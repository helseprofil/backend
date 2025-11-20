Rsynt_postprosess_ungdata
# Beregner dekningsgrad og sletter tall

# Hente dekningsgradfil for fylkestall (inneholder treårige tall for 14-16-åringer, som skal matches på AARh for å treffe treårige fylkestall)

dekning <- max(list.files(file.path(getOption("khfunctions.root"), getOption("khfunctions.kubedir"), getOption("khfunctions.kube.dat"), "R"),
                          pattern = "^UNGDATA_DEKNINGSGRAD_\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}.parquet$", full.names = T))
dekning <- arrow::read_parquet(dekning, col_select = c("GEOniv", "GEO", "AARh", "TELLER", "sumTELLER"))[GEOniv %in% c("K", "F")]

# Finne ut hvilke kommuner som har deltatt (har predteller != 0)
# Treårige lister for alle år utenom spesialbehandling av pandemiårene:
# - 2021 og 2022 er ettårige, 2023 er toårig, (2021-tallene skal ikke inn her).
deltatt <- data.table::copy(KUBE)[GEOniv == "K" & !grepl("99$", GEO) & PREDTELLER != 0]
aar <- sort(unique(KUBE$AARh))
dekning_miss_aar <- setdiff(aar[3:length(aar)], unique(dekning$AARh))
if(length(dekning_miss_aar) > 0L){
  stop("KUBE UNGDATA_DEKNINGSGRAD mangler tall for år ", paste0(dekning_miss_aar, collapse = ","), ", og må kjøres på nytt")
}
kommune_deltatt <- list()
for(i in 3:length(aar)){
  aar_included <- (aar[i]-2):aar[i]
  kommune_deltatt[[as.character(aar[i])]] <- deltatt[AARh %in% aar_included, unique(GEO)]
}
kommune_deltatt[["2021"]] <- deltatt[AARh == 2021, unique(GEO)]
kommune_deltatt[["2022"]] <- deltatt[AARh == 2022, unique(GEO)]
kommune_deltatt[["2023"]] <- deltatt[AARh %in% c(2022, 2023), unique(GEO)]

# pga avbrutte undersøkelser i 2020 har NOVA kodet om en del kommuner til x99. Disse er med i våre fylkestall, men kommunetallene er borte.
# For å beregne korrekt dekningsgrad for fylket må befolkningstallet for disse kommunene også være med. Disse er hentet fra filen
# "O:/Prosjekt/FHP/PRODUKSJON/ORGDATA/NOVA/Ungdata/2021/DOK/Tabell_Ungdomsskolen_Ungdata_2020.xlsx", hvor svarprosent > 10%

# d <- data.table::setDT(readxl::read_excel("O:/Prosjekt/FHP/PRODUKSJON/ORGDATA/NOVA/Ungdata/2021/DOK/Tabell_Ungdomsskolen_Ungdata_2020.xlsx", skip = 1))
# addgeo <- d[Svarprosent >= 0.10, unique(Kommunenr.)]
# geoharmoniser denne listen og legg til manglende verdier i kommune_deltatt[["2020"]]
addgeo <- data.table::data.table(GEO = c("1507", "1515", "1525", "1528", "1531", "1554", "1560", "1566", "1573", 
            "1576", "1578", "1811", "3005", "3006", "3007", "3038", "3040", "3041", 
            "3042", "3043", "3045", "3047", "3049", "3050", "3051", "3052", "3053", 
            "3054", "3401", "3403", "3405", "3407", "3411", "3413", "3415", "3416", 
            "3417", "3418", "3419", "3420", "3421", "3422", "3423", "3424", "3425", 
            "3426", "3427", "3428", "3429", "3431", "3433", "3434", "3435", "3437", 
            "3438", "3441", "3442", "3443", "3446", "3447", "3448", "3449", "3450", 
            "3451", "3452", "3453", "3454", "3803", "3811", "5014", "5021", "5025", 
            "5028", "5032", "5035", "5036", "5038", "5041", "5042", "5047", "5054", 
            "5057", "5058", "5059", "5060"))
addgeo[parameters$KnrHarm, on = "GEO", GEO := data.table::fifelse(!is.na(i.GEO_omk), i.GEO_omk, GEO)]
addgeo2020 <- addgeo[!grepl("99$", GEO) & !GEO %in% kommune_deltatt[["2020"]], unique(GEO)]
kommune_deltatt[["2020"]] <- c(kommune_deltatt[["2020"]], addgeo2020)

# Beregne dekningsgrad som summen av befolkning i inkluderte kommuner/totalbefolkning i fylket
kommunedekning <- data.table::copy(KUBE[KJONN == 0 & GEOniv == "K"])
if("SOES" %in% names(kommunedekning)) kommunedekning <- kommunedekning[SOES == 0]
kommunedekning <- kommunedekning[, .SD, .SDcols = c("GEO", "FYLKE", "AARh", "TELLER")]
kommunedekning[dekning[GEOniv == "K"], on = c("GEO", "AARh"), let(KOMMUNEBEF = i.TELLER)]
data.table::setorderv(kommunedekning, c("GEO", "AARh"))
kommunedekning[, let(KOMMUNEBEF = data.table::nafill(KOMMUNEBEF, type = "nocb")), by = GEO]
kommunedekning[is.na(TELLER) | TELLER <= 0, let(KOMMUNEBEF = 0)]

fylkedekning <- data.table::copy(KUBE[KJONN == 0 & GEOniv == "F"])
if("SOES" %in% names(fylkedekning)) fylkedekning <- fylkedekning[SOES == 0]
fylkedekning <- fylkedekning[, .SD, .SDcols = c("GEO", "AARh")]
fylkedekning[dekning[GEOniv == "F"], on = c("GEO", "AARh"), let(FYLKEBEF = i.TELLER)]
fylkedekning[, let(DELTATT_KOMMUNE = 0)]

aarlist <- list()
for(i in 3:length(aar)){
  aarlist[[as.character(aar[[i]])]] <- (aar[i]-2):aar[i]
}
aarlist[["2021"]] <- 2021
aarlist[["2022"]] <- 2022
aarlist[["2023"]] <- c(2022, 2023)

# Lag totale treårige befolkningstall for kommunene som har deltatt og merge på fylkedekning
# Bruker snittet av befolkning for hver kommune for å ta høyde for kommuner med flere deltakelser.
for(i in names(aarlist)){
  kommune_included <- kommune_deltatt[[i]]
  kommune <- kommunedekning[GEO %in% kommune_included & AARh %in% aarlist[[i]]][TELLER > 0]
  kommune <- kommune[, KOMMUNEBEF := mean(KOMMUNEBEF), by = GEO][, .SD[1], by = GEO]
  kommune <- kommune[, .(KOMMUNESUM = sum(KOMMUNEBEF)), by = FYLKE][, let(AARh = as.integer(i))]
  fylkedekning[kommune, on = c(setNames("FYLKE", "GEO"), "AARh"), let(DELTATT_KOMMUNE = i.KOMMUNESUM)]
}
fylkedekning[DELTATT_KOMMUNE > 0, let(DEKNINGSGRAD = DELTATT_KOMMUNE/FYLKEBEF)]
slettfylker <- fylkedekning[DEKNINGSGRAD < 0.5, .SD, .SDcols = c("GEO", "AARh")]

# For førsteperioder er det nødvendig å slette foregående 2 år også. 
# Unntak: For 2021 og 2022, som er ettårige, skal ikke foregående år slettes, og for 2023 skal bare 2022 slettes. 
firstperiod <- aar[3]
n_back <- data.table::fcase(firstperiod %in% 2021:2022, 0L,
                            firstperiod == 2023, 1L,
                            default = 2L)
if(n_back > 0){
  extra <- -seq_len(n_back)
  add <- slettfylker[AARh == firstperiod, .(AARh = AARh + extra), by = GEO]
  slettfylker <- data.table::rbindlist(list(slettfylker, add), use.names = TRUE)
}

flaggcols <- c("TELLER.f", "NEVNER.f", "RATE.f", "spv_tmp")

KUBE[slettfylker, on = c("GEO", "AARh"), (flaggcols) := 3L]

# Sletter undergrupper av SOES dersom nevner for SOES = 0 er lavere enn valgt cutoff (100)
# Gjør ingenting om alle undergrupper mangler fra før, f.eks. der alle har SPVFLAGG = 2, slik at de beholder opprinnelig SPVFLAGG
if("SOES" %in% names(KUBE)){
  soesvalues <- KUBE[, unique(SOES)]
  soesnull <- if(is.character(soesvalues)) "0" else 0
  tab1 <- parameters$fileinformation[[1]]$TAB1
  bycols <- c("GEO", "AARh", "KJONN", tab1)
  slett_soes_undergrupper <- KUBE[SOES == 0 & NEVNER < 100, .SD, .SDcols = bycols][, .(SOES = setdiff(soesvalues, soesnull)), by = bycols]
  if(nrow(slett_soes_undergrupper) > 0L){
    KUBE[slett_soes_undergrupper, on = names(slett_soes_undergrupper), let(slettsoes = 1)]
    KUBE[SOES != 0, allmissing := sum(spv_tmp != 0) == .N, by = bycols]
    KUBE[allmissing == FALSE & slettsoes == 1, (flaggcols) := 3L][, let(slettsoes = NULL, allmissing = NULL)]
  }
}

# Slette Åsane bydel i Bergen (460108) i 2024, pga for lav dekningsgrad
# (bare 1 av 5 ungdomsskoler er med som utgjør ca 20% av elevene sammenlignet med tidligere år).
# Sletter også Midt-Telemark (4020) i 2024, pga tekn.probl. på en skole, de ville ikke at tallene skulle vises
KUBE[GEO %in% c("4020", "460108") & AARh == 2024 & spv_tmp == 0, (flaggcols) := 3L]

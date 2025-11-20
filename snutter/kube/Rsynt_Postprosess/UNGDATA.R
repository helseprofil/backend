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

# GAMMEL STATA-SNUTT
# /* POSTPROSESSERING UNGDATA: 
#   - DEKNINGSGRAD
# - DETALJRETTING I SMNSLÅTT KOMMUNE
# - PRIKKING AV SOES (sosøk.status)
# - SLETTING AV SOES før 2017 (Jørgen, 29.11.2019)
# 
# Tidl.utvikling: Produkter\Kuber\Kommuneh\KH2016 (og 17)\POSTPROSESS.
# v2:  Nytt resonnement for metoden.
# v3:  Inkl. postprosessering av kubefiler i hht. de beregnede dekningsgradene.
# v4:  Oppdatert til 2017-data (førsteutkast) og lagt inn behandlnig av FRISKVIKfiler (ikke testet).
# Skal bygge om denne versjonen til en RSYNT_POSTPROSESS. 
# v5:  Bygget om. - Brukt tempfiles ist.f. faste filer som mellomlager.
# v6:  Rettet: Beregning av hvilke kommuner som har deltatt, må gjøres innenfor hver treårsperiode. 
# v7:  Ny befolkningsfil, med path og filnavn lagt øverst i snutten.
# v8:  Lagt inn assert på at GEO i befolkning og Ungdatafil matcher. Dermed trigges en
# åpenbar feil hvis vi kjører med gal befolk-fil.
# v9:  TILLEGG: Slette alle år unntatt 2013 og 2017 for Geo==5054. (Dvs. bevare år der de to 
#                                                                   sammenslåtte komm. gjorde Ungdata samtidig, så det sammenslåtte tallet gir mening)
# -	   Sjekket des-18: Ny årgang befolkningsfil, og bruk av 2017 ist.f. 2016-befolkning som grunnlag, ga
# ingen endringer. Dermed lot vi være å endre snuttene (annet enn i ALKOHOL, som var testcase). Dette
# scriptet er uendret.
# v10: TILLEGG: Dersom ekstradimensjonen (TAB1) har varnavn ett av <SKJERMTID LOKALTILBUD> skal alle data 
# før 2016 slettes (pga dårlig kvalitet). Dette må skje etter at dekningsgrad er beregnet, derfor helt til slutt.
# v11: TILLEGG: Prikking av SOES. Alle undergrupper (SOES 1-5) slettes hvis nevneren for SOES==0 er lavere enn
# den cutoff som settes i scriptet - i utgangspunktet 100.
# v12: Videreutvikling for SOES: Dersom to eller fler undergrupper mangler, skjules alle undergrupper.
# v13: Oppheve sletting av kommune 5054 (se v9). Ny metode for å håndtere at smnslåtte komm. tidligere 
# gjorde Ungdata i ulike år, det skjer i en annen RSYNT. (stbj nov-2019)
# NY DODE-FIL med 2020-geo spesifisert i linje ca.100 (stbj nov-2019)
# v14: Slette alle SOES-tall før 2017, slik at vi i periopden 2012-2016 kun viser 
# SOES=0. SOES ble innført i 2016, og ble problematisk for enkelte av de 
# undersøkelsene som er slått sammen på tvers av år (i snutten Rsynt_Pre_FGlagring_Ungdata)
# (Jørgen, 29.11.2019)
# OBS se 29.1.21!
#   v15: Fjerne "TILLEGG 2, Slette tall for tidlige årganger (før 2016) pga dårlige
# 	   data. Gjelder bare noen kuber bla-bla" (Jørgen, 05.12.2019)
# v16: FORLATT. Laget en ny metode for å estimere antall barn som deltok (for beregning 
#                                                                         av dekningsgrad i fylkene). Det viste seg at forutsetningene for metoden ikke holdt.
# v17: Spesialbehandling av 2020-data i beregningen av dekningsgrad for fylkene: 
#   Mange kommuner fikk avbrutt datainnsamlingen pga korona-nedstengingen. NOVA har tatt ut 
# en del kommuner ved å kode dem til xx99. Derfor må vi hardkode hvilke kommuner som deltok 
# og skal telle med i dekningsgraden. 
# Kilde for kommunelista: Kvalitetsnotat i ORGDATA\...\2021\DOK\ . Kriterium: Svarprosent 10 eller høyere.
# -Fikset feil når ingen kommuner i et fylke deltok - fylket fikk missing dekning, og da slo ikke filteret inn.
# -Tilrettelagt for kjøring med INCLUDE-kommando i Access.
# HERETTER: IKKE ENDRE FILNAVN VED NY VERSJON - Unngå å måtte endre i alle kuber i Access.
# 
# v	   25.01.2021: Endret SOES-prikking til å slette alle undergrupper hvis én eller fler er missing. Tillegg 3.
# v	   29.01.2021: Fjernet Tillegg 4. Det har oppstått misforståelse: SOES ble innført i 2014. Første årgang hvor 
# kommuner kan sammenliknes med tre-årige fylkes- og landstall der SOES inngår, er 2016. Dette er håndtert
# i Rsynt_Pre_FGlagring. Tillegg 4 var overflødig, og dessuten feil (slettet tall før 2018).
# v    27.01.2022: Modifisert SOES-prikking spesifikt for kuber med FORNOYDHET (Tillegg 3)
# 
# v    14.12.2022: Scriptet må takle ettårige F- og L-tall for 2021 og 2022. Det vil si, skal telle opp 
# deltakende kommuner separat for disse to enkeltårene. Samme kriterium for å slette fylkestall som ellers.
# -Det medfører også at 2023 må fikses på: Da skal tallene være for to år, siden 2021 ikke skal være med.
# Jeg legger inn det med det samme. Det vil ikke få noen effekt så lenge "2023" ikke er med i AARl.
# 
# PLUSS: Sjekk for bruk av feltet Kuber\AAR_START. Lese i tabellen KUBE og feltet AAR_START, og dersom 
# det står noe annet enn «0», får man feilmelding. Saken var at ved dårlige tall i de første årene, så 
# kan man ikke bruke «startår» i KUBER for Ungdata-kuber hvis man vil ha en kortere tidsserie enn det 
# tallmaterialet faktisk tilsier (langt resonnement!). 
# 
# v	   05.01.2023: Ny indik LIVSKVALITET_UNGDATA har bare to årganger (2021 og -22). Da må vi spesialsy beregningen 
# av dekningsgrad, som normalt krever tre år. Logikken om å skjule fylkestall med lav dekning skal fremdeles gjelde.
# Dette bør kodes til å gjelde BARE denne kuben og dette året, slik at vi blir varslet om krøll med neste 
# toårige kube... Vi har kubenavn tilgjengelig i spec-filen, se tidlig i scriptet.
# Lagt inn nødvendige endringer alle steder hvor løkkestyring med "start på i = tredje årstall" brukes.
# 
# v	   08.05.2023: FORNOYDHET_SAMLET_UNGDATA krever å tillate bruk av at AAR_START settes til noe annet enn null.
# Assert i linje 183 hoppes over for denne kuben.
# I tillegg må da tre fylkestall slettes (hardkodes) for 2016, for å matche tidligere publiserte tall. Lagt inn nederst.
# 
# v	   13.11.2023: Ny DODE-FIL (befolkningstall for 14-15-16-åringer) med 2024-Geo. Nytt kubenavn.
# 
# v	   14.12.2023: Beregningen av Deltattsum var laget for én rad per Geo, mens DODE-filen hadde UTD med fire kategorier.
# La inn en keep bare én UTD-kat (med capture, så den tåler at UTD ikke er med.)
# 
# v	29.01.2025: TILLEGG 5: Slette Åsane bydel i Bergen (460108) året 2024, pga for lav dekningsgrad
# (bare 1 av 5 ungdomsskoler er med som utgjør ca 20% av elevene sammenlignet med tidligere år).
# OPPDATERT befolkningsfil til 2025-utgaven.
# 
# 
# OBS VED SENERE ENDRINGER: IKKE ENDRE FILNAVN.
# Nytt regime: Unngå behov for å endre kommandoen i Accessfeltet. Kopier i stedet scriptfilen til "OLD" og rename med dato.
# */
#   
#   /*** FORUTSETNINGER: 
#   -For SOES-prikking når "to eller fler undergrupper mangler" ("v12" ovenfor):
#   Ekstravariabelen med svar-kategori (f.eks ANTALL_GANGER == "engangellermer") 
# må ikke ha mer enn én kategori. Se Tillegg 3.
# 
# -Befolkning hentes fra Forv.Levealder-grunnlagsdatafil. Skriv inn filnavn for ferskeste utg., og 
# endre evt. årstallet som brukes. (Må ha ettårig alder, derfor denne filen)
# -GEO må være likt harmonisert (samme sett kommunenumre) i de to filene.
# */
#   /*	Target: Hvor stor andel av de aktuelle elevkullene har FÅTT TILBUD OM Å DELTA 
# i Ungdata-undersøkelsen i et gitt fylke? Det vil si: Telleren er befolkningstallet 
# i de aktuelle aldersgruppene i de kommunene som har deltatt.
# 
# Tallet (pluss en valgt cutoff) brukes for å selektere hvilke fylker som får vist tall.
# 
# Metode: 
#   Teller: Plukker ut fra en Ungdata-datafil (kube) hvilke kommuner i hvert fylke 
# som har deltatt. Henter ut befolkningstall for 14-15-16-åringer i disse kommunene
# (uavhengig av antall svar i Ungdata-filene).
# (For 2020: Hardkodet liste over kommuner, se "v17" ovenfor.)
# 
# Nevner: = summen av antall 14-15-16-åringer i fylket.
# Utg.pkt. i befolkningstallet i grunnlagsdatafilen for Forv.Levealder: der er 
# ettårig befolkning, i form av en middelfolkemengde, ferdig geoharmonisert etc.
# 
# Resonnement for tidsperiode: 
#   For FYLKEStall lages treårige snitt (i en RSYNT tidligere i løypa), selv om "AAR" sier at det 
# er ett år. (Det samme gjelder for landstall, men disse rører vi ikke i dette scriptet).
# Derfor må vi telle hvilke kommuner som deltok i hver glidende treårsperiode, og summere folketall
# for alle disse, for hver beregning av dekningsgrad. 
# Dekningsgrad-tallet gjelder m.a.o. for en treårsperiode.
# Hver kommune gjør SOM REGEL undersøkelsen én gang i løpet av dataenes treårsperiode. Da blir 
# det riktig å bruke kommunens folketall én gang som teller, og ett års fylkesbefolkning som nevner.
# 
# Spes. for første periode (som ofte er 2014): Hvis fylkestallet slettes, må også 2012 og 2013 slettes.
# De treårige snittene som vises for fylkene (se forrige avsnitt), er for 2012-13-14 samme tall,
# ist.f. "de tre foregående årene" slik det er videre i serien.
# 
# Dekningsgraden kan aldri bli nøyaktig: Vi mangler ofte info om f.eks. når på året 
# Ungdata ble kjørt, og da kjenner vi ikke i hvilket skoleår det var. Alder er ofte 
# også ukjent. Dermed er det nøyaktig nok å lage et grovestimat, bare vi dokumenterer det.
# Dermed er det ikke så nøye å bruke "riktig type" middelfolkemengde etc.
# Vi regner heller ikke nøyaktig teller/nevner for hvert enkelt år i perioden.
# 
# Endringslogg: Se ovenfor.
# 
# */
#   *-------------------------------------------------------------------------------
#   **** OBS: Det er path til Befolkningsfil i et "avsnitt" nede i scriptet. 
# 
# * CUTOFF-VERDI FOR Å SKJULE FYLKESTALL: Settes i avsnittet rett før første "Tillegg".
# * CUTOFF-VERDI FOR Å SKJULE SOES-UNDERGRUPPER: Settes i avsnittet "Tillegg 3", nederst.
# 
# *
#   *-------------------------------------------------------------------------------
#   /* FOR UTVIKLINGSFASEN - KOMMENTERES UT FØR SKARP KJØRING MED INCLUDE 
# 
# ***** OBS: AKTUELL KUBE MÅ VÆRE DEN SISTE SOM ER KJØRT AV MEG på samme maskin - for å få lagret kubespec.csv.
# 
# ****************************************
#   *  Fildump MÅ LAGES MED SAVE i postpro-feltet.
# *  En dump fra løypa har feil var-navn og -typer.
# ****************************************
#   
#   pause on
# 
# local datakatalog "O:/Prosjekt/FHP/PRODUKSJON\RUNTIMEDUMP"
# local innfil "VENNER_UTE_UNGDATApostpro-PRE"		// uten filtypen
# 
# frame change default
# capture frame drop spec
# */
#   
#   /* LAGE FILDUMP
# save "`datakatalog'/`innfil'.dta", replace
# */
#   /* LESE INN FILDUMP - dta
# use "`datakatalog'/`innfil'.dta", clear
# */
#   /* LESE INN FILDUMP - csv
# import delimited "`datakatalog'/`innfil'.csv", case(preserve) stringcols(17) clear  //GEO er kol. 17
# */
#   *-------------------------------------------------------------------------------
#   /*
#   *** OBS: KAN IKKE BRUKE "///" for å skjøte programlinjer, det virker ikke i Statas batchmodus.
# *** Må bruke /*   */  rundt linjeskifttegnet i stedet (sist på første linje og først på siste linje).
# 
# 
# <STATA>
#   ******************************************************************************/
#   * Script: Rsynt_Postprosess_UNGDATA_dekngrad....
# * NOTATER OM OPPBYGNING OG UTVIKLING: Se ovenfor.
# * OBS: ASSERT sjekker at Geo i befolkningsfil og Ungdatafil stemmer overens! 
#   * Trigger kræsj ved mismatch.
# 
# * SJEKK AV STARTAAR
# *-------------------------------------------------------------------------------
#   * Hente inn hvilken kube vi er i fra den lagrede spec'en til stataprikking.
# 	// Her er kubenavnet i KUBE_NAVN, og en liste over alle dimensjoner i DIMS.
# 	// Filen lagres i starten av LagKUBE. 
# frame create spec
# frame change spec
# * SKARP:
# import delimited "C:\Users\\`c(username)'\helseprofil\kubespec.csv", varnames(1) case(preserve) delimiter(";") clear
# local kubenavn = KUBE_NAVN[1]
# */
# 	*local kubenavn = "VENNER_UTE_UNGDATA"		//For utvikling. VENNER_UTE er kjørt jan-25.
# 
# * Hente inn det aktuelle feltet fra kubespec'en. Det ligger ikke i det som er lagret for Stataprikking.
# odbc load, exec(`"SELECT KUBER.KUBE_NAVN, KUBER.AAR_START FROM KUBER WHERE KUBER.KUBE_NAVN = '`kubenavn'' "') /*
#   */ dsn("MS Access Database; DBQ=O:/Prosjekt/FHP\PRODUKSJON\STYRING\KHELSA.mdb;")   clear
# 
# * SJEKKE at det ikke er brukt gal metode for å utelukke tidlige årganger: Dersom AAR_START er brukt, stopp her.
# * Dersom tidlige årganger må utelukkes, må det gjøres ved å slette dem i KODEBOK.
# * UNNTAK for FORNOYDHET_SAMLET_UNGDATA.
# 
# if !("`kubenavn'" == "FORNOYDHET_SAMLET_UNGDATA") {
#   assert AAR_START == 0
#   ** ANM: For FORNOYDHET_SAMLET_UNGDATA er det også en egen bolk nederst i scriptet, om sletting av tall for 2016.
# }
# *pause kubespec
# */
#   *-------------------------------------------------------------------------------
#   frame change default	// Gå tilbake til datasettet
# capture frame drop spec
# ** Riktig befolkningsfil: Se hvilken som er brukt i scriptet for Forventet levealder.
# ** ...\PRODUKSJON\BIN\Z_e0_e30\ <produksjonsår> \eX_v05_Vestland.do - linje ca. 80
# local befolkpath "O:/Prosjekt/FHP/PRODUKSJON\PRODUKTER\KUBER\STATBANK\DATERT\csv"
# local befolkningsfil "`befolkpath'\Dode1.1_forventetlevealder_2025-01-07-08-27.csv"
# //Trenger ettårig alder, derfor denne litt ulogiske filen.
# //Brukes bare til å beregne dekningsgrad for fylkene.
# 
# tempfile ungdatafil
# save `ungdatafil', replace	//Ta vare på R-datasettet!
# 	*pause Datasettet i R er slik
# 	
# *TELLER
# *-------------------------------------------------------------------------------
# //Vi leser ut fra Ungdata-filene "hvilke kommuner som har deltatt".
# //Alle som har PREDTELLER, har tilstrekkelige opplysninger til 
# //å få standardiserte tall - selv om de kanskje skal prikkes senere. Disse kommunene skal regnes med.
# //PREDTELLER FINS i R-datasettet på RSYNT_POSTPRO-nivå!
# //OBS spesialbehandling av 2020, 2021 og 2022.
# //OBS spesiell håndtering når tidsserien er kortere enn tre år.
# keep if GEOniv=="K"
# 
# drop if substr(GEO, 3,2)=="99"	//Ukjent kommune, vil ikke finnes i Befolk-filen.
# tempvar numGEO
# gen `numGEO'=real(GEO)
# levelsof `numGEO', local(allekommuner) clean //Tar vare på kommunelista for å sjekke mot Befolk-filen.
# drop if PREDTELLER==0 	//Den er ikke missing
# 	
# *Nå skal gjenstående geo være kommuner som bidrar til det standardiserte fylkestallet.
# *Må telle opp for hver treårsperiode, og samle dem på siste år i perioden.
# 	*pause Levelsof-lista, ovenfor, er alle kommuner. I datasettet er nå alle deltakerkommuner, alle år
# 	
# *Hvilke årganger fins? Plukke ut alle som kan være siste år i en treårsperiode.
# * (Aar er gitt ettårig - det er bare F og L som egentlig har treårige tall ...)
# gen kommflagg=.
# levelsof(AARl), local(aarganger) //Alle år i datasettet
# local antaar = wordcount("`aarganger'")
# 
# * Spesialbehandling av LIVSKVALITET_UNGDATA for profilår 2023: Filen har bare to årganger.
# if "`kubenavn'" == "LIVSKVALITET_UNGDATA" & `antaar' == 2 {
# 	* Kommuneliste for 2021 og 2022 lages eksplisitt nedenfor!
# 	} //end kube Livskvalitet_ungdata
# 
# else {	//alle andre kuber
# forvalues i= 3/`antaar' { //Kommuneliste-løkka:
#     *local i=3
#     local aarstall = word("`aarganger'", `i') //Siste årstall i perioden
# 	local fjor	   = `aarstall'-1
#                           local forfjor  = `aarstall'-2
# 	replace kommflagg= 1 if (AARl==`aarstall' | AARl==`fjor' | AARl==`forfjor')
# 	di `"Kommuneliste for "`aarstall'":"'
# 	levelsof GEO if kommflagg==1, local(kommuneliste) clean //Lagrer alle kommuner som nå er flagget.
# 	local kommuneliste`aarstall' = "`kommuneliste'"
#                           *pause inni kommuneliste-løkka, for hvert år
#                           replace kommflagg=.
# } //end -forvalues-
#   } //end -else-
#     *****	
#   *di "`kommuneliste2020'"
# *pause
# * Spesialbehandling av 2020:
#   * Preppet fram lista ut fra kildetabell (se øverst). Den må LEGGES TIL lista laget i scriptet, 
# * hvor 2018- og 2019-kommunene ligger.
# * Omkodet til 2024-geo. Da forsvinner 1507 Ålesund, som ble delt.
# local kommuneliste2020 = "`kommuneliste2020'" + /*
#   */	" 1515 1525 1528 1531 1554 1560 1566 1573 1576 1578 1811 3301 3303 3305 3310 3322 3324 " + /*
#   */	"3326 3328 3332 3316 3312 3334 3336 3338 3236 3234 3401 3403 3405 3407 3411 3413 3415 " + /*
#   */	"3416 3417 3418 3419 3420 3421 3422 3423 3424 3425 3426 3427 3428 3429 3431 3433 3434 " + /*
#   */	"3435 3437 3438 3441 3442 3443 3446 3447 3448 3449 3450 3451 3452 3453 3454 3905 3911 " + /*
#   */	"5014 5021 5025 5028 5032 5035 5036 5038 5041 5042 5047 5054 5057 5058 5059 5060"
# 
# /* original, 2023-geo:
#   " 1507 1515 1525 1528 1531 1554 1560 1566 1573 1576 1578 1811 3005 3006 3007 3038 3040 " + 
#   "3041 3042 3043 3045 3047 3049 3050 3051 3052 3053 3054 3401 3403 3405 3407 3411 3413 " + 
#   "3415 3416 3417 3418 3419 3420 3421 3422 3423 3424 3425 3426 3427 3428 3429 3431 3433 " + 
#   "3434 3435 3437 3438 3441 3442 3443 3446 3447 3448 3449 3450 3451 3452 3453 3454 3803 " + 
#   "3811 5014 5021 5025 5028 5032 5035 5036 5038 5041 5042 5047 5054 5057 5058 5059 5060" 
# */
#   
#   *pause
# * Spesialbehandling av 2021:
#   local aarstall = "2021"
# replace kommflagg= 1 if (AARl==`aarstall')		//AARl er lik AARh, ett år.
# 	di `"Kommuneliste for "`aarstall'":"'
# 	levelsof GEO if kommflagg==1, local(kommuneliste) clean //Lagrer alle kommuner som nå er flagget.
# 	local kommuneliste`aarstall' = "`kommuneliste'"
#                          replace kommflagg=.
#                          
#                          * Spesialbehandling av 2022:
#                            local aarstall = "2022"
#                          replace kommflagg= 1 if (AARl==`aarstall')		//AARl er lik AARh, ett år.
# 	di `"Kommuneliste for "`aarstall'":"'
# 	levelsof GEO if kommflagg==1, local(kommuneliste) clean //Lagrer alle kommuner som nå er flagget.
# 	local kommuneliste`aarstall' = "`kommuneliste'"
#                                                   replace kommflagg=.
#                                                   
#                                                   * Spesialbehandling av 2023: Skal ha med to år. Denne vil ikke få noen effekt før "2023" faktisk er med i AARl.
#                                                   local aarstall = "2023"
#                                                   local fjor	   = `aarstall'-1
# 	replace kommflagg= 1 if (AARl==`aarstall' | AARl==`fjor')
# 	di `"Kommuneliste for "`aarstall'":"'
# 	levelsof GEO if kommflagg==1, local(kommuneliste) clean //Lagrer alle kommuner som nå er flagget.
# 	local kommuneliste`aarstall' = "`kommuneliste'"
#                                                   replace kommflagg=.
#                                                   
#                                                   
#                                                   //Nå skal vi ha en serie locals med hver sin liste over kommuner. Lista gjelder tre år (med noen unntak), og er
#                                                   //navngitt med siste årstall.
#                                                   *di "2014: `kommuneliste2014'"
#                                                   *di "2015: `kommuneliste2015'"
#                                                   *di "2016: `kommuneliste2016'"
#                                                   *di "2017: `kommuneliste2017'"
#                                                   *di "2018: `kommuneliste2018'"
#                                                   *di "2020: `kommuneliste2020'"
#                                                   *pause
#                                                   
#                                                   *NEVNER 
#                                                   *-------------------------------------------------------------------------------
#                                                     import delimited "`befolkningsfil'", delimiter(";") clear 
#                                                   //Default: Oversettes fra encoding Latin1
#                                                   drop if geo> 30000
#                                                   drop if geo==0
#                                                   
#                                                   * SJEKKE at Geo samsvarer med Ungdatafilen, OG GENERERE KRÆSJ hvis mismatch
#                                                   levelsof geo if geo>99, local(befolkkommuner) clean
#                                                   assert "`allekommuner'" == "`befolkkommuner'" 
#                                                   
#                                                   keep if aar=="2016_2016" //Sparer ikke eksakte data for alle årganger. Se resonnement i do-filen.
#                                                   drop aar
#                                                   keep if alder=="14_14" | alder=="15_15" | alder=="16_16"
#                                                   keep if kjonn==0	//Bruker bare kjønn samlet i kuben
#                                                   drop kjonn
#                                                   capture drop teller			//Er antall døde, uinteressant her
#                                                   capture drop rate
#                                                   drop spvflagg
#                                                   
#                                                   sort geo alder
#                                                   by geo: egen befolk= total(sumnevner) //Summen av de tre aldersklassene
#                                                   *pause Sjekk befolk-variabelen, den er nevner i dekn.grad
#                                                   keep if alder=="14_14"
#                                                   drop alder
#                                                   drop sumnevner 		//Er befolkn.tall for én alder, trengs ikke nå
#                                                   
#                                                   * Noen filer har Utdanning med flere kategorier - men uten Utd Samlet.
#                                                   * Nå vil alle rader ha et befolk-tall, så jeg må beholde bare én rad per Geo.
#                                                   capture keep if utdann == 1
#                                                   
#                                                   *tempfile nevnerfil			//Trengs ikke med ny beregningsmetode
#                                                   *save `nevnerfil', replace
# 	*pause etter prepping for nevner
# *-----------------------------------------------------------------------------
# *BEREGNING
# *Bruker samme løkkestyring som ovenfor
# 		*For utvikl:
# 		*local aarganger = "2012 2013 2014 2015 2016"
# gen flagg=.
# gen hjemmefylke= floor(geo/100) if geo>99
# replace hjemmefy = geo if hjemmefy==. & geo<100 & geo>0
# sort hjemmefy geo //Nå ligger fylket rett foran sine kommuner
# 
# * Spesialbehandling av LIVSKVALITET_UNGDATA for profilår 2023: Filen har bare to årganger, 2021 og -22.
# * Jeg lurer nedenstående beregningsløkke til å funke - mens alle andre kuber krever minst tre årganger.
# if "`kubenavn'" == "LIVSKVALITET_UNGDATA" & `antaar' == 2 {
# 	/*Sett løkkestart til 1.
# 	`antaar' er 2, så løkka vil kjøre for de to årene.
# 	`aarganger' inneholder de to årene, så riktige kommunelister vil bli hentet fram.
# 	Så vil logikken med beregning av antall deltatt osv. funke riktig. */
# 	local lokkestart = 1
# 	} //end kube Livskvalitet_ungdata
# else {
# 	local lokkestart = 3
# }
# 
# *Løper gjennom de aktuelle periodene
# forvalues i= `lokkestart'/`antaar' {
# *local i=3
# di "Periode: i= `i'"
# 	local aarstall = word("`aarganger'", `i') //Siste årstall i perioden
# 		di "Årstall: `aarstall'"
# 	foreach geokode of local kommuneliste`aarstall' {
# 	  replace flagg=1 if geo == `geokode'
# 			di "`geokode'"
# 	} //Funker selv om GEO var string da kommuneliste ble laget.
# *pause Flagget alle deltakerkommuner dette året
# 
# 	by hjemmefylke: egen deltattsum`aarstall'= total(befolk) if flagg==1 & geo>100
# 	//Lager tall bare for deltakende kommuner, dvs det er en del missing celler.
# 	//For å sikre at vi finner en verdi å legge i fylkets rad:
# 	tempvar deltatt_mellomlager
# 	by hjemmefylke: egen `deltatt_mellomlager' = mean(deltattsum`aarstall')
# 		//Dvs. "gj.snitt" av en samling like tall, for hvert fylke ...
# *pause Sjekk deltattsum
# 	replace deltattsum`aarstall' = `deltatt_mellomlager' if geo < 100 & geo > 0
# 	replace deltattsum`aarstall' = 0 if missing(deltattsum`aarstall') & geo < 100 & geo > 0
# *pause	
# 	drop `deltatt_mellomlager'
# 
# 	/*Nå har vi, for fylkene:
# 		- befolk =antall 14-15-16-åringer i fylket
# 		- deltattsumÅÅÅÅ =antall 14-15-16-åringer i de kommunene som bidrar til det std.fylkestallet
# 		  i den aktuelle perioden (ÅÅÅÅ-2 til ÅÅÅÅ)
# 	*/
# 	 
# 	gen dekngrad_pct`aarstall'=deltattsum`aarstall'/befolk*100 if geo<100 
# *pause Se dekningsgrad-tall
# 	replace flagg=. //Klargjøre for neste runde (periode)
# } //end "antaar"
# *pause Se dekningsgrad-tallene samlet
#  
# sort geo 
# format dekngrad_pct* %5.1f
# *save Ungdata-dekngrad_v3, replace
# *export delimited Ungdata-dekngrad_v3.csv, delimiter(";") nolabel replace
# 
# * Velge ut fylker
# drop if geo > 100
# replace flagg=.
# 
# *-------------------------------------------------------------------------------
# * POSTPROSESSERING, UNGDATA:
# * Fjerne FYLKESTALL dersom "dekningsgraden" i fylket er for lav -
# * det vil si dersom summen av folketallet i de kommunene som har deltatt, er 
# * under en viss andel av fylkets totale folketall (for 14+15+16-åringer).
# * (Resonnement: Over en viss andel av fylkets ungdommer skal ha fått tilbudet om å delta.)
# * Gjelder bare våre standardiserte kuber. De crude kubene viser samme tall som Ungdata selv.
# 
# * Cutoff-verdi: Ideelt 50 %. Da ryker fire fylker (2016), hvorav to har verdi over 45 %.
# 
# 
# 	* For utviklingen:
# 	*use Ungdata-dekngrad_v3, clear
# 
# * SETT CUTOFF: 
# local cutoff= 50 //prosent
# 
# * Spesialbehandling av LIVSKVALITET_UNGDATA for profilår 2023: Filen har bare to årganger, 2021 og -22.
# * Jeg lurer nedenstående beregningsløkke til å funke - mens alle andre kuber krever minst tre årganger.
# if "`kubenavn'" == "LIVSKVALITET_UNGDATA" & `antaar' == 2 {
# 	/*Sett løkkestart til 1.
# 	`antaar' er 2, så løkka vil kjøre for de to årene.
# 	  `aarganger' inneholder de to årene, så riktige årstall vil bli hentet fram.
# 	Så vil resten funke riktig. */
# 	local lokkestart = 1
# 	} //end kube Livskvalitet_ungdata
# else {
# 	local lokkestart = 3
# }
# 
# *Løper gjennom de aktuelle periodene
# forvalues i= `lokkestart'/`antaar' {
# 	local aarstall = word("`aarganger'", `i') //Siste årstall i perioden
# 
# 	replace flagg=geo if dekngrad_pct`aarstall' <`cutoff'
# 	levelsof flagg, local(slett_fylker`aarstall') //Lagrer de fylkene som skal skjules
# 	di as res "slett_fylker`aarstall':   `slett_fylker`aarstall''"
# *pause	
# 	replace flagg=. //Klargjøre for neste runde
# }
# *pause Se Slett_fylker-listene
# * Lese inn igjen R-datasettet
# use `ungdatafil', clear
# 
# * Spesialbehandling av LIVSKVALITET_UNGDATA for profilår 2023: Filen har bare to årganger, 2021 og -22.
# * Jeg lurer nedenstående beregningsløkke til å funke - mens alle andre kuber krever minst tre årganger.
# if "`kubenavn'" == "LIVSKVALITET_UNGDATA" & `antaar' == 2 {
# 	/*Sett løkkestart til 1.
# 	`antaar' er 2, så løkka vil kjøre for de to årene.
# `aarganger' inneholder de to årene, så riktige årstall vil bli hentet fram. */
# 	local lokkestart = 1
# 	} //end kube Livskvalitet_ungdata
# else {
# 	local lokkestart = 3
# }
# 
# *Løper gjennom de aktuelle periodene
# forvalues i= `lokkestart'/`antaar' {
# 	local aarstall = word("`aarganger'", `i') //Siste årstall i perioden
# 
# 	foreach fylke of local slett_fylker`aarstall' {
# 		capture replace TELLER=. 	if real(GEO) ==`fylke' & AARl ==`aarstall' //GEO er jo string, mens 
# 		capture replace RATE=. 		if real(GEO) ==`fylke' & AARl ==`aarstall' //den var num høyere opp.
# 		capture replace SMR=. 		if real(GEO) ==`fylke' & AARl ==`aarstall'
# 		capture replace MEIS=. 		if real(GEO) ==`fylke' & AARl ==`aarstall'
# 		capture replace TELLER_f= 3	if real(GEO) ==`fylke' & AARl ==`aarstall'
# 		capture replace RATE_f  = 3	if real(GEO) ==`fylke' & AARl ==`aarstall'
# 		
# 		*Spes. for første periode (f.eks. 2014): Da må også 2012 og 2013 slettes.
# 		*Men ikke for pandemiårene. Vi må skille ut 2021, starter på nytt fra -22, og -23 har toårige tall.
# 		if `i'==3 { //Dette er tredje år, vi må sjekke om det er i en normal førsteperiode 
# 			if inlist(`aarstall', 2021, 2022) {
# 				* Ikke gjør noe.
# 			}
# 			else {
# 				if `aarstall' == 2023 {
# 					* Slett ett år bakover
# 					capture replace TELLER=. 	if real(GEO) ==`fylke' & (AARl==`aarstall'-1 | AARl==`aarstall'-2)
# 					capture replace RATE=. 		if real(GEO) ==`fylke' & (AARl==`aarstall'-1 )
# 					capture replace SMR=. 		if real(GEO) ==`fylke' & (AARl==`aarstall'-1 )
# 					capture replace MEIS=. 		if real(GEO) ==`fylke' & (AARl==`aarstall'-1 )
# 					capture replace TELLER_f= 3	if real(GEO) ==`fylke' & (AARl==`aarstall'-1 )
# 					capture replace RATE_f  = 3	if real(GEO) ==`fylke' & (AARl==`aarstall'-1 )
# 				}
# 				else {	//Alle normale førsteperioder
# 					* Slett to år bakover
# 					capture replace TELLER=. 	if real(GEO) ==`fylke' & (AARl==`aarstall'-1 | AARl==`aarstall'-2)
# 					capture replace RATE=. 		if real(GEO) ==`fylke' & (AARl==`aarstall'-1 | AARl==`aarstall'-2)
# 					capture replace SMR=. 		if real(GEO) ==`fylke' & (AARl==`aarstall'-1 | AARl==`aarstall'-2)
# 					capture replace MEIS=. 		if real(GEO) ==`fylke' & (AARl==`aarstall'-1 | AARl==`aarstall'-2)
# 					capture replace TELLER_f= 3	if real(GEO) ==`fylke' & (AARl==`aarstall'-1 | AARl==`aarstall'-2)
# 					capture replace RATE_f  = 3	if real(GEO) ==`fylke' & (AARl==`aarstall'-1 | AARl==`aarstall'-2)
# 				} //end -normale perioder-
# 			} //end -alt unntatt 2021 og -22
# 		} //End -første periode-
# 	} //End -foreach fylke-
# } //End -forvalues "antaar"-
# 
# *-------------------------------------------------------------------------------
# /*	Spesialsøm for FORNOYDHET_SAMLET_UNGDATA:
# 	Vi starter tidsserien i 2016, og hopper over tall for 2014-15. Da må vi hardkode sletting av 
# 	noen fylker i 2016 for å matche tidligere publiserte tall.
# */
# 	if "`kubenavn'" == "FORNOYDHET_SAMLET_UNGDATA" {
# 		foreach fylke in 15 46 50 {
# 		capture replace TELLER=. 	if real(GEO) ==`fylke' & AARl == 2016 //GEO er jo string, mens 
# capture replace RATE=. 		if real(GEO) ==`fylke' & AARl == 2016 //den var num høyere opp.
# 		capture replace SMR=. 		if real(GEO) ==`fylke' & AARl == 2016
# capture replace MEIS=. 		if real(GEO) ==`fylke' & AARl == 2016
# 		capture replace TELLER_f= 3	if real(GEO) ==`fylke' & AARl == 2016
# capture replace RATE_f  = 3	if real(GEO) ==`fylke' & AARl == 2016
# 		}
# 	}
# 
# *-------------------------------------------------------------------------------
# * OPPHEVET tillegg: Slette tall for sammenslåtte kommuner, der de inngående kommunene gjorde Ungdata i ulike år.
# * (Annen RSYNT håndterer dette med ny metode)
# 
# 
# /*
# -------------------------------------------------------------------------------
# * OPPHEVET tillegg 2: Har ikke notert hvorfor, men de aktuelle kubene ble kjørt 
# * uten dette filteret for publiseringen i profilår 2020. Se "v15" øverst.
# 
# * Slette tall for tidlige årganger (før 2016) pga dårlige data. Gjelder bare noen kuber:
# * LOKALTILBUD, SKJERMTID
# * Forutsetter at ekstradimensjonen har et spesifikt variabelnavn: Settes i TAB1 i tabell Filgrupper, og 
# * i EKSTRA_TAB i tabell Friskvik.
# lookfor LOKALTILBUD SKJERMTID
# if "`r(varlist)'" != "" {  //En av variablene finnes, dvs. data før 2016 skal slettes
# 	drop if AARl<2016
# }
# *exit
# */
# 
# *-------------------------------------------------------------------------------
# * TILLEGG 3: Slette undergrupper av SOES hvis nevneren for SOES==0 er lavere enn valgt cutoff.
# * Dessuten slette alle undergrupper dersom én eller fler undergrupper mangler (i mangel av 
# * ordentlig naboprikking).
# * Lager variabler for begge kriteriene, og behandler begge i samme "if".
# 
# * SOES er fra 2022 tredelt + "samlet". Tidligere 0-5.
# 
# * OBS: KREVER (FOR DE FLESTE KUBER) AT EKSTRAVARIABELEN MED SVARKATEGORI HAR BARE ÉN KATEGORI.
# * (f.eks. STATUS == "svaertfornoyd") - ellers må den variabelen inkluderes i Sort og 
# * By/egen-kommandoene nedenfor. Det er litt plundrete å generalisere, for disse variablene har 
# * ulike navn for hver Ungdatafil.
# 
# * SPESIAL FOR KUBER MED "FORNOYDHET": Tillater mer enn én svarkategori (se forrige avsnitt).
# * Da blir variabelen med i sortering og by-setninger.
# 
# local cutoff = 100
# 
# // Identifisere om dette er en FORNOYDHET-kube
# local TEMA = ""
# describe, varlist
# local liste "`r(varlist)'"
# 	*di "`liste'"
# if ustrregexm("`liste'", "(FORNOYD[A-Z]*)") {
#     local TEMA = ustrregexs(0)
# }
# 	*di "Tema: `TEMA'"
# 
# // Plukk ut Nevner-verdien for SOES==0, og fyll den ut for alle SOES i en egen variabel.
# // Da kan den brukes direkte til å slette verdier.
# 
# //// OBS: SOES ER STRING - men ikke i en Runtimedump! Bruk "save ...dta" for å utvikle script.
# 
# sort AARl GEO `TEMA' SOES 
# gen soesnull = NEVNER if SOES == "0"	//Gir ett tall per "by"-gruppe
# by AARl GEO `TEMA' : egen nullnevner = mean(soesnull) 	//Fyller ut samme tall for alle fire SOES-kategorier i gruppa.
# 
# // Tell opp antall missing SOES-grupper for hver gruppe
# gen prikker = 1 if missing(TELLER)
# by AARl GEO `TEMA' : egen flagg = sum(prikker)			//Fyller ut samme tall for alle fire i gruppa.
# 
# // Vil ikke tukle med bl.a. SPVflagg i de tilfellene _alle_ SOES-grupper mangler fra før.
# // Derfor filter på om flagg, dvs. antall missing, er 4.
# capture noisily replace TELLER=. 	if (nullnevner < `cutoff' | (flagg >= 1 & flagg < 4)) & SOES != "0"
# capture noisily replace RATE=. 		if (nullnevner < `cutoff' | (flagg >= 1 & flagg < 4)) & SOES != "0"
# capture noisily replace SMR=. 		if (nullnevner < `cutoff' | (flagg >= 1 & flagg < 4)) & SOES != "0"
# capture noisily replace MEIS=. 		if (nullnevner < `cutoff' | (flagg >= 1 & flagg < 4)) & SOES != "0"
# *capture noisily replace sumNEVNER=. if (nullnevner < `cutoff' | (flagg >= 1 & flagg < 4)) & SOES != "0"
# capture noisily replace TELLER_f= 3	if (nullnevner < `cutoff' | (flagg >= 1 & flagg < 4)) & SOES != "0" & TELLER_f==0
# capture noisily replace RATE_f  = 3	if (nullnevner < `cutoff' | (flagg >= 1 & flagg < 4)) & SOES != "0" & RATE_f  ==0
# 
# drop soesnull nullnevner prikker flagg
# 
# 
# *-------------------------------------------------------------------------------
# * UTDATERT OG FEIL TILLEGG 4: Slette SOES-tall for årganger før 2018: Innføringen av SOES i 2016
# * ville i en overgangsfase gitt mix av undersøkelser med og uten SOES i fylkes- 
# * og landstall (som er treårige gjennomsnitt). Tilsvarende problem for en del av 
# * de sammenslåtte kommunene.
# *drop if real(SOES)>0 & AARl<2018
# 
# 
# *-------------------------------------------------------------------------------
# * TILLEGG 5: Slette Åsane bydel i Bergen (460108) året 2024, pga for lav dekningsgrad
# * (bare 1 av 5 ungdomsskoler er med som utgjør ca 20% av elevene sammenlignet med tidligere år).
# * SPVflagg skal da være 3.
# *pause for Tillegg 5
# 
# 	capture replace TELLER=. 	if GEO == "460108" & AARl == 2024 //GEO er jo string, mens 
# 	capture replace RATE=. 		if GEO == "460108" & AARl == 2024 //den var num høyere opp.
# 	capture replace SMR=. 		if GEO == "460108" & AARl == 2024
# 	capture replace MEIS=. 		if GEO == "460108" & AARl == 2024
# 	capture replace TELLER_f= 3	if GEO == "460108" & AARl == 2024
# 	capture replace RATE_f  = 3	if GEO == "460108" & AARl == 2024
# 
# 
# *-------------------------------------------------------------------------------
# * TILLEGG 6: Slette Midt-Telemark (4020) året 2024, pga tekn.probl. på en skole, de ville ikke at tallene
# * skulle vises.
# * SPVflagg skal da være 3.
# *pause for Tillegg 6
# 
# 	capture replace TELLER=. 	if GEO == "4020" & AARl == 2024 //GEO er jo string, mens 
# 	capture replace RATE=. 		if GEO == "4020" & AARl == 2024 //den var num høyere opp.
# 	capture replace SMR=. 		if GEO == "4020" & AARl == 2024
# 	capture replace MEIS=. 		if GEO == "4020" & AARl == 2024
# 	capture replace TELLER_f= 3	if GEO == "4020" & AARl == 2024
# 	capture replace RATE_f  = 3	if GEO == "4020" & AARl == 2024
# 
# *Ferdig

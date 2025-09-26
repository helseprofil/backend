# Rsynt 1 for innlesing av vanlige ungdataindikatorer
# Bydelstall fra 2015 og kommunetall fra 2010

tab1 <- unique(DF$tab1_innles) # Kan bruke filedescription$TAB1, men do_special_handling må også kunne ta med filedescription før dette kan brukes
minaar <- collapse::fmin(unique(DF$AAR))
if(minaar > 2012) minaar <- 2012 # rektangulariser minst tilbake til 2012
maxaar <- collapse::fmax(unique(DF$AAR))
if(is.numeric(DF[[tab1]])) DF <- DF[get(tab1) < 98]
data.table::setnames(DF, c("klasse", "kommune", "tidspunkt"), c("Klasse", "Kommune", "Tidspunkt"), skip_absent = T)
DF[is.na(SOES), let(SOES = 99)]

bydelcols <- grep("^Bydel", names(DF), ignore.case = TRUE, value = T)
isbydel <- length(bydelcols) > 0
keepcols <- c(tab1, "Kommune", "AAR", "Tidspunkt", "KJONN", "Klasse", "SOES", "vekt2020")

if(isbydel){
  keepcols_bydel <- c(intersect(keepcols, names(DF)), bydelcols)
  DF <- DF[, .SD, .SDcols = keepcols_bydel]
  DF[, let(nonmiss = rowSums(!is.na(.SD)),
           miss = Reduce(`+`, lapply(.SD, function(x) x %in% c(98, 99)))), .SDcols = bydelcols]
  DF <- DF[nonmiss == 1 & miss == 0 & !(Kommune %in% c(1601, 5001) & AAR == 2013)][, let(nonmiss = NULL, miss = NULL)]
  DF[Kommune == 301 & AAR >= 2015, let(Kommune = get(grep("oslo", bydelcols, ignore.case = T, value = T)))]
  DF[Kommune == 1103 & AAR >= 2015, let(Kommune = get(grep("stavanger", bydelcols, ignore.case = T, value = T)))]
  DF[Kommune %in% c(1201, 4601) & AAR >= 2015, let(Kommune = get(grep("bergen", bydelcols, ignore.case = T, value = T)))]
  DF[Kommune %in% c(1601, 5001) & AAR >= 2015, let(Kommune = get(grep("trondheim", bydelcols, ignore.case = T, value = T)))]
  DF[, (bydelcols) := NULL]
  if(!"vekt2020" %in% names(DF)) DF[, let(vekt2020 = 1)]
}
DF <- DF[, .SD, .SDcols = keepcols]
allgeos <- unique(DF$Kommune)
DF <- DF[!is.na(Klasse) & !is.na(KJONN)]

DF[Tidspunkt == 99 & AAR > 2021, let(Tidspunkt = 1)]
DF[Klasse < 98, let(klasse_6delt = paste0(Klasse + 7, "_", 2/Tidspunkt))]
DF[Klasse >= 98, let(klasse_6delt = paste0(Klasse, "_", 2/Tidspunkt))]
DF[, let(teller = 1)]
DF[is.na(vekt2020), let(vekt2020 = 1)]

dims <- c(tab1, "Kommune", "AAR", "KJONN", "klasse_6delt", "SOES")
g <- collapse::GRP(DF, dims)
DF <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(DF, c("teller", "vekt2020")), g = g))
DF[, let(exist = 1)]

full <- list()
full[["Kommune"]] <- data.table::data.table(Kommune = allgeos)
full[["klasse_6delt"]] <- data.table::data.table(klasse_6delt = c("10_1", "10_2", "9_1", "9_2", "8_1", "8_2"))
full[["AAR"]] <- data.table::data.table(AAR = minaar:maxaar)
for(dim in setdiff(dims, c("Kommune", "klasse_6delt", "AAR"))){
  full[[dim]] <- unique(DF[, .SD, .SDcols = dim])
}  

full <- do.call(khfunctions:::expand.grid.dt, full)
data.table::setcolorder(full, c("Kommune", "AAR", "KJONN", tab1, "klasse_6delt", "SOES"))
DF <- collapse::join(full, DF, multiple = T, overid = 2, verbose = 0)
DF[is.na(exist), let(teller = 0, vekt2020 = 0)][, let(exist = NULL)]

# Lag nevner som sum(teller) i hvert strata og gjør alt til tekst
DF[, let(nevner = collapse::fsum(teller)), by = setdiff(dims, tab1)]
DF[, names(.SD) := lapply(.SD, as.character)]


# Gamle kommentarer fra STATA
# /*
#   Forskjellen mellom filen(e) med gamle bydelstall og andre filer, er at bydels-
#   variablene har byttet a) navn og b) innhold (har senere fått autentiske bydels-
#                                                  koder). 
# 
# I Oslo er bydel selvoppgitt, i de andre byene er bydelsopplysning avledet fra 
# skolens beliggenhet.
# 
# Hardkodet GEO: Ja. De fire største byene + bydeler der.
# 
# Endringer i koder for Tr.heim 1.1.2018 og Bergen 1.1.2020 er tatt høyde for 
# (funker med både nye og gml. komm.nr).
# 
# v_01 Nov. 2020: 
#   # Tatt ut dikotomisering, slik at dette heller gjøres i kodebok. 
#   # Én og samme snutt kan brukes på nesten* alle indikatorer (fordi Yusman har 
#   ordnet sånn at navnet på den originale variabelen ligger i Stata-filen i stedet 
# for å være hardkodet i snutten).
# # Det må fortsatt være en egen snutt for de eldste bydelstallene.
# # *) Det må fortsatt være egne snutter for indikatorer som er basert på mer enn 
# én variabel: Depresjon, Fysisk aktivitet, ...
# v_02 Des. 2020:
#   # Ta høyde for vektingsvariabelen <vekt2020>. Prøve å ordne slik at RSYNT1-
#   snutten både for filer med (kommunefiler) og uten (bydelsfiler) <vekt2020>.
# Ingen bydeler hadde datainnsamling i 2020. I skrivende stund virker det 
# best om bydelsfilene også gis en vektingsvariabel; vekt2020=1. Må tenke på 
# at også RSYNT_PRE_FG-snutten skal fungere på begge filtyper. 
# 
# Endringer kun i linje 70, 71 (nye linjer) og 72 (tar med <vekt2020> i -collapse-)
# NYTT SYSTEM fom. 6.jan.2021: Gjeldende snutt har FAST navn, utgåtte snutter er 
# versjonerte. 
# 
# 6.jan.2021:
#   # Endring: local innevaerendeAar=siste år i filen (i stedet for faktisk 
#   inneværende år) 
# 14.des.2021:
#   # Hardkoder endring av tidspunkt=99 til tidspunkt=1 for årgang 2021 og ut-
#   over. Årsaken er at alle kommuner f.o.m. 2021 har UNGDATA på våren, noe 
# som har ført til at NOVA sluttet å bruke variabelen "tidspunkt", og setter
# inn verdien 99 i filer de sender til oss. Denne verdien skaper trøbbel
# i dette skriptet, (f.eks. aldersgruppen 10_.020202 i tillegg til alders-
#                      gruppen 10_2) og fører senere til halvering av nevnerne.
# 21.des.2021:
#   # Sletting av kommmunetall dersom filen er en bydelsfil (nytt fenomen
#   medio desember 2021; bydelsfiel inneholder kommunetallene for 2021).
# 17.01.2022 (JM):
#   # Omkode "."  i SOES til "99". Burde helst vært gjort i kodebok, men den 
#   metoden gir uventet store problemer på pre_FGlagring.
# 
# ******************************************************************************/

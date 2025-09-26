# Preprosessering av TAB1 for DEPRESJON_UNGDATA
# Lager samleindikator basert på Depr1-Depr6
# Videre prosessering i hovedsnuttene

depr_cols <- grep("^Depr[1-6]$", names(DF), value = T, ignore.case = TRUE)

DF[, (depr_cols) := lapply(.SD, function(x) data.table::fifelse(x >= 98, NA_real_, x)), .SDcols = depr_cols]
DF[, let(miss = rowSums(is.na(.SD)),
         depr = rowMeans(.SD, na.rm = T)), .SDcols = depr_cols]
DF <- DF[miss <= 2] # Fjerner missing for TAB1
DF[!is.na(depr) & miss <= 2, let(depr_dicS = data.table::fifelse(depr >= 3 & depr <= 4, "Ja_score>=3", "Nei_score<3"))]

# Gamle kommentarer fra STATA: 
#   v03: Byttet til å inkludere de samme 6 items som NOVA. Forskjellen fra NOVA blir 
# vårt krav om non-missing på minimum 4 items (og som vanlig at våre tall er 
#                                              standardiserte og ekskludere respondenter med uoppgitt alder og/eller kjønn).
# Endringen fra snuttversjon 02 til 03 innebærer a) at vi tar med et item av 
# ukjent opprinnelse ("stiv og anspent"), noe som gjør at sammenlignbarhet med
# NOVA er hovedargument for valg av metode. En positiv bivirkning er at man 
# kan henvise videre til NOVA hvis det kommer mer inngående spørsmål om valg 
# av metode. Det er verdt å merke seg at de 5 HSCL-items innen depresjon som 
# vi opprinnelig tenkte å begrense oss til, heller ikke utgjør et etablert 
# depresjonsinstrument med vitenskapelig utviklet cut-off og således heller  
# ikke ville vært så lett å begrunne. 
# v04: vekt2020 (des. 2020): Denne snutten er identisk med den som ligger i 
# Access. Oppdaterer med vekt2020, og lager en peker hit fra Access
# 
# NYTT SYSTEM fom. 6.jan.2021: Gjeldende snutt har FAST navn, utgåtte snutter er 
# versjonerte. 
# 
# 6.jan.2021:
#   # Erstatter local innevaerendeAar=siste år i filen (i stedet for faktisk 
#   inneværende år) 
# 14.des.2021:
#   # Hardkoder endring av tidspunkt=99 til tidspunkt=1 for årgang 2021 og ut-
#   over. Årsaken er at alle kommuner f.o.m. 2021 har UNGDATA på våren, noe 
# som har ført til at NOVA sluttet å bruke variabelen "tidspunkt", og setter
# inn verdien 99 i filer de sender til oss. Denne verdien skaper trøbbel
# i dette skriptet, (f.eks. aldersgruppen 10_.020202 i tillegg til alders-
#                      gruppen 10_2) og fører senere til halvering av nevnerne.
# ******************************************************************************/


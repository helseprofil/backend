# Preprosessering av TAB1 for FYSAK_UNGDATA
# Dikotomiserer trener9-kolonnen
# Videre prosessering i hovedsnuttene

tren_col <- grep("Trener9", names(DF), ignore.case = TRUE, value = T)
DF[, trener_1_9_dicS := data.table::fifelse(get(tren_col) <= 3, "TrSjelden, trener9=1 2 3", "TrUkentlig, trener9=4 5 6")]
DF <- DF[!is.na(trener_1_9_dicS) & AAR >= 2014]

# Gamle kommentarer fra STATA
#   NYTT SYSTEM fom. 6.jan.2021: Gjeldende snutt har FAST navn, utgåtte snutter er 
# versjonerte. 
# 
# 6.jan.2021: Erstatter local innevaerendeAar=siste år i filen (i stedet for faktisk 
#                                                               inneværende år)
# 18.jan.2021: tar høyde for nytt varnavn (trener1 i stedet for Trener1) f.o.m. 2020 :(
#   21.jan.2021: Fjerne svaralternativene for Trener1 de årene dette spm. ikke var 
#   med, Tilsvarende med trener9. Forhindrer masse trøbbel senere. Nederst i skriptet. 
#   14.des.2021:
#     # Hardkoder endring av tidspunkt=99 til tidspunkt=1 for årgang 2021 og ut-
#     over. Årsaken er at alle kommuner f.o.m. 2021 har UNGDATA på våren, noe 
#   som har ført til at NOVA sluttet å bruke variabelen "tidspunkt", og setter
#   inn verdien 99 i filer de sender til oss. Denne verdien skaper trøbbel
#   i dette skriptet, (f.eks. aldersgruppen 10_.020202 i tillegg til alders-
#                        gruppen 10_2) og fører senere til halvering av nevnerne.	  
#   21.des.2021:
#     # Sletting av kommmunetall dersom filen er en bydelsfil (nytt fenomen
#     medio desember 2021; bydelsfiel inneholder kommunetallene for 2021).
# 17.01.2022 (JM):
#   # Omkode "."  i SOES til "99". Burde helst vært gjort i kodebok, men den 
#   metoden gir uventet store problemer på pre_FGlagring.
#   Trøndelagssammenslåing er tatt høyde for (funker med både nye og gml. komm.nr).
# Trondheim og Bergens nye 2020koder er tatt inn.
# v03: vekt2020

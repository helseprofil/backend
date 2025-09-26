# Preprosessering av TAB1 for REGELBRUDD_UNGDATA
# Lager samleindikator `regbrudd_dicS` basert på atfpro[1,12,15,18,25] og skolprob4-kolonnene
# Videre prosessering i hovedsnuttene

cols <- grep("^atfpro(1$|12$|15$|18$|25$)|^skolprob4", names(DF), value = T, ignore.case = T)
DF <- DF[AAR >= 2017] # første år alle spørsmålene er med
DF[, (cols) := lapply(.SD, function(x) data.table::fifelse(x >= 98, NA, x >= 2 & x <=5)), .SDcols = cols]
DF[, let(miss = rowSums(is.na(.SD)),
         regbrudd = rowSums(.SD, na.rm = T)), .SDcols = cols]
DF <- DF[miss <= 1] # Fjerne missing for TAB1
DF[, let(regbrudd_dicS = data.table::fifelse(regbrudd >= 3 & regbrudd <= 6, "Ja_brudd>=3","Nei_brudd<3"))]

# local startAar=2017 // Første året alle items er med, f.x. 2017 for REGELBRUDD
# local forsteUngdataAar=`startAar' // Utgår
# su AAR
# local innevaerendeAar=`r(max)'
# local origVar "regbrudd" // Samlebetegnelse "inndata" til Rsynt1
# local dicVar=lower("`origVar'")+"_dic"
# 
# * PRE-PROSESSERING. Omkode "."  i SOES til "99". Burde helst vært gjort i kodebok, 
# *men den metoden gir uventet store problemer på pre_FGlagring (JM 17.1.2022) 
# keep if AAR>=`startAar'
# replace SOES=99 if SOES==.
# 
# *A DIKOTOMISERING.
# *A.1. Etablere <regbrudd> som gjennomsnitt av enkelt-items. Først: 98->. 99->.
# capture rename Atfpro*
# capture rename Skolprob*, lower
# foreach var of varlist atfpro1 atfpro12 atfpro15 atfpro18 atfpro25 skolprob4  {
# 	replace `var'=. if `var'==98 | `var'==99
# }
# tempvar miss
# egen `miss' = rowmiss(atfpro1 atfpro12 atfpro15 atfpro18 atfpro25 skolprob4) // ant miss i 6 items
# *A.2. Dikotomisere enkeltspørsmålene (nytt med REGBRUDD)
# foreach var of varlist atfpro1 atfpro12 atfpro15 atfpro18 atfpro25 skolprob4  {
#   replace `var'=(`var'>=2 & `var'<=5) if `var'<.
# }
# egen `origVar'=rowtotal(atfpro1 atfpro12 atfpro15 atfpro18 atfpro25 skolprob4) if `miss'<=1
# capture su `origVar'
# if _rc!=0 {
#   local origVar=lower("`origVar'")
# }
# capture drop *dic
# assert (`origVar'>=0 & `origVar'<=6) | `origVar'==.  
#         
#         
#         gen `dicVar'=(`origVar'>=3 & `origVar'<=6) if `origVar'<. & `miss'<=1
# drop if `dicVar'==.
# * B. Labels
# label var `dicVar' "Mange regelbrudd"
# local hovedlabel_1 "Ja_brudd>=3" // Beskrivelse for dikotom variabel=1
# local hovedlabel_0 "Nei_brudd<3" // Beskrivelse for dikotom variabel=0
# * Her pleier det å legges inn en prosedyre for å hindre feil ifm. copy-paste, men
#   *hverken overførbart til eller så relevant for Depr. stemningsleie 	 	
# label define tekstverdier 1 "`hovedlabel_1'" 0 "`hovedlabel_0'"
# label values `dicVar' tekstverdier
# decode `dicVar', gen(`dicVar'S)


# Gamle kommentarer fra STATA
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
# 21.des.2021:
#   # Sletting av kommmunetall dersom filen er en bydelsfil (nytt fenomen
#   medio desember 2021; bydelsfiel inneholder kommunetallene for 2021).
# 17.01.2022 (JM):
#   # Omkode "."  i SOES til "99". Burde helst vært gjort i kodebok, men den 
#   metoden gir uventet store problemer på pre_FGlagring.
# 
# ******************************************************************************/
#   /*
#   Trøndelagssammenslåing er tatt høyde for (funker med både nye og gml. komm.nr).
# v04: Bergens nye 2020-koder, og vekt2020
# */
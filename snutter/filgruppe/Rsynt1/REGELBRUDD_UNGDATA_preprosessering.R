# /*
#   NYTT SYSTEM fom. 6.jan.2021: Gjeldende snutt har FAST navn, utgåtte snutter er 
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
#   
#   set more off
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
# * C. FILTRERING, forskjell mellom kommune- og bydelsfil
# capture rename klasse Klasse
# capture rename kommune Kommune
# capture rename tidspunkt Tidspunkt
# capture su bydel_* // * Finne ut om dette er en KOMMUNE- eller BYDELsfil 
# if _rc>0 { // hvis det er kommunefilen
# 	keep `dicVar'S Kommune AAR Tidspunkt KJONN Klasse SOES vekt2020
# }
# else { // hvis det er bydelsfilen
#   * Droppe eventuelle rene kommunetall (20.12.2021). Telle opp hvor mange av 
#   * "bydel_..."-variablene som ikke er missing. Skal være = 1, for alle 
#   * observasjoner skal kunne knyttes til en bydel.
#   tempvar Bydel_nonmiss
#   egen `Bydel_nonmiss'=rownonmiss(bydel*)
# 	drop if `Bydel_nonmiss'==0 // drop hvis det er missing (bokstavelig talt) på
#   // alle bydelsvariablene. F.o.m. 2021 kodes det 'missing' i stedet for 98/99.
#   keep `dicVar'S Kommune AAR Tidspunkt KJONN Klasse bydel* SOES
# 	drop if Ko==301 & (bydel_oslo==98 | bydel_oslo==99)
# 	drop if Ko==1103 & (bydel_stavanger==98 | bydel_stavanger==99) 
# 	capture drop if (Ko==1601 | Ko==5001) & (bydel_Trondheim==98 | bydel_Trondheim==99)
# 	capture drop if (Ko==1601 | Ko==5001) & (bydel_trondheim==98 | bydel_trondheim==99)
# 	drop if (Ko==1201 | Ko==4601) & 	(bydel_bergen==98 | bydel_bergen==99)
# 	drop if Ko==1601 & AAR==2013 // Kan ikke konverteres til de offisielle bydelene
# 	replace Kommune=bydel_oslo if Ko==301 & AAR>=2015
# 	replace Kommune=bydel_bergen if (Ko==1201 | Ko==4601) & AAR>=2015
# 	capture replace Kommune=bydel_Trondheim if (Ko==1601 | Ko==5001) & AAR>=2015
# 	capture replace Kommune=bydel_trondheim if (Ko==1601 | Ko==5001) & AAR>=2015
# 	replace Kommune=bydel_stavanger if Ko==1103 & AAR>=2015	  // Storhaug mangler i 2016, pga. St Svithun mixup
# 	assert Ko>30000
# }
# * KLASSE + SEMESTER (SEMESTER=<Tidspunkt>. 1=før sommeren, 2=etter sommeren)
# replace Tidspunkt=1 if Tidspunkt==99 & AAR>=2021 // "99" er nytt i 2021 og skaper trøbbel (jørgen 14.des.2021)
# gen klasse_6delt=strofreal(Klasse+7)+"_"+strofreal(2/Tidsp)
# replace klasse_6delt=strofreal(Klasse)+"_"+strofreal(2/Tidsp) if Klasse==98 | Klasse==99 
# * TELLER
# gen teller=1 
# capture gen vekt2020=1  // Ny i 2020! Legge inn <vekt2020> i bydelsfiler. 
# replace vekt2020=1 if vekt2020==. // Ny i 2020! Fylle ut missingverdier i ekte vekt2020
# collapse (sum) teller vekt2020, by(`dicVar'S Kommune AAR KJONN klasse_6delt SOES) 
# * På dette stadiet: Hvis i en kommune/bydel, på et klassetrinn, for fx gutter
# * det var 0 som svarte et av svaralternativene, så vil det på dette stadiet 
# * mangle linje for denne kombinasjonen (mens det egentlig skulle ha vært en 
#                                         * linje med teller=0. Det er dette som rettes opp med neste fillin:
#                                           * 23.1.2016: Rektangularisere, ellers mister vi strata med teller 0
#                                         fillin `dicVar'S Kommune AAR KJONN klasse_6delt SOES
# replace teller =0 if teller==. & _f==1
# replace vekt2020 =0 if vekt2020==. & _f==1 // Ny des. 2020
# drop _f
# * NEVNER
# egen nevner = total(teller), by(Kommune AAR KJONN klasse_6delt SOES)
# * 23.1.2016: Fillin-linjen gir massevis av tomme strata, i år der komunen ikke 
# * har gjenniomført undersøkelsen. Dropper derfor hvis nevner 0
# drop if nevner==0  // disse settes trolig inn igjen nedenfor men skitt au
# 
# *"FILLIN" av alder. Det kan være et problem at ikke alle "Alders"-verdiene er 
# * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
# * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
# * aldersverdier er representert i alle filer
# sort Kommune AAR KJONN klasse_6delt SOES // unngå evt. missingverdier på linje 1
# foreach alder in 10_1 10_2 8_1 8_2 98_1 98_2 99_1 99_2 9_1 9_2 {
# 	local nylinje=_N+1
# 	set obs `nylinje'
#                                         replace klasse_6delt="`alder'" in `nylinje'
# 	replace Ko=Ko[1] in `nylinje'
#                                         replace KJ=1 in `nylinje'
# 	replace AAR=AAR[1] in `nylinje'
#                                         replace `dicVar'S=`dicVar'S[1] in `nylinje'
#                                         replace SOES=SOES[1] in `nylinje'
# 	replace teller=0 in `nylinje'
#                                         replace nevner=0 in `nylinje'
# 	replace vekt2020=0 in `nylinje'    // Ny i 2020
# }
# *"FILLIN" av aar. Det kan være et problem at ikke alle "års"-verdiene er 
# * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
# * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
# * årsverdier er representert i alle filer
# sort Kommune AAR KJONN klasse_6delt SOES // unngå evt. missingverdier på linje 1
# forvalues aar = `forsteUngdataAar'/`innevaerendeAar' {
# 	local nylinje=_N+1
# 	set obs `nylinje'
# replace klasse_6delt=klasse_6delt[1] in `nylinje'
# 	replace Ko=0 in `nylinje'
# replace KJ=KJ[1] in `nylinje'
# 	replace AAR=`aar' in `nylinje'
# 	replace `dicVar'S=`dicVar'S[1] in `nylinje'
# 	replace SOES=SOES[1] in `nylinje'
# replace teller=0 in `nylinje'
# 	replace nevner=0 in `nylinje'
# collapse (sum) teller nevner vekt2020, by(Kommune AAR KJONN klasse_6delt SOES `dicVar'S)
# 	fillin Kommune AAR KJONN klasse_6delt SOES `dicVar'S
#                                           replace teller=0 if teller==. & _fillin==1
#                                           replace nevner=0 if nevner==. & _fillin==1
#                                           replace vekt2020=0 if vekt2020==. & _fillin==1    // Ny i 2020
#                                           drop _fillin
#                                           }
# * TOSTRING
# tostring _all, replace force  
# * RYDDING
# capture drop __0* //temp-variabelen  
# *******************************************************************************
#   
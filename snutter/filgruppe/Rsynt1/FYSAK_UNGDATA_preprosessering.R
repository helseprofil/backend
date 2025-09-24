# /*
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
# ******************************************************************************/
#   /*
#   Trøndelagssammenslåing er tatt høyde for (funker med både nye og gml. komm.nr).
# Trondheim og Bergens nye 2020koder er tatt inn.
# v03: vekt2020
# */
#   pause on
# set more off
# local forsteUngdataAar=2012 // Bør være første Ungdata-år i Kommunehelsa (2012)
# su AAR
# local innevaerendeAar=`r(max)'
# local dicVar "trener_1_9_dic"
# * SPESIAL: Finne ut a) om ny spm.stilling heter <trener9> eller <Trener9> og
# 	*b) sjekke at en av disse er til stede i filen.
# local trener_ny 
# foreach variant in Trener9 trener9 {
# 	capture su `variant'  
# if _rc==0 { 
#   local trener_ny "`variant'"
# }
# }
# assert `"`trener_ny'"'=="Trener9" | `"`trener_ny'"'=="trener9"
# 
# * PRE-PROSESSERING. Omkode "."  i SOES til "99". Burde helst vært gjort i kodebok, 
# *men den metoden gir uventet store problemer på pre_FGlagring (JM 17.1.2022) 
# replace SOES=99 if SOES==.
# 
# * DIKOTOMISERING. NB Trener1 (2010-2013) og Trener9/trener9 (2014-) ulikt kodet
# capture rename trener1 Trener1 // nytt variabelnavn (trener1) f.o.m. 2020 :(
#   capture gen Trener1=98 // Litt skummel, men T(t)rener1 fins ikke i ny bydeslfil. 
#   capture drop *dic
#   drop if Trener1>=98 & `trener_ny'>=98
# assert `trener_ny'<=6 | Trener1<=5
#   * Sjekke at Trener1 og (T)(t)rener9 er gjensidig utelukkende (at ingen har
#                                                                 *verdier <98 på begge)
#   assert Trener1>=98 if `trener_ny'<=6
# assert `trener_ny'>=98 if Trener1<=5
#   * Opprette den dikotome variabelen
#   gen `dicVar'=((Trener1>=3 & Trener1<=5) | (`trener_ny'<=3))
# assert (Trener1<=2) | (`trener_ny'>=4 & `trener_ny'<=6) if `dicVar'==0
# label var `dicVar' "Fysisk inaktiv"
#   * Mer detaljerte labels for kontroll av at det er benyttet rett cut-off. Cut-off
#   *kan bli feil ifm. copy-paste. På følgende måte vil man både se hvilken variabel
#   *og hvilken cut-off som faktisk er blitt benyttet. Spesiell algoritme for denne
#   *indikatoren iom. at det varierer ml. filer hvilken variabel som brukes.
#   *---------------------
#     *NB: Hvis man skal ha helt korrekt labeling av den dikotome variabelen, så må 
#   *verdien 1 ha en  labels hver, avhengig av om det er Trener1 eller trener9
#   *som ligger til grunn.
#   tostring `dicVar', replace
# rename `dicVar' `dicVar'S
# local hovedlabel_1 "TrSjelden" // Beskrivelse for dikotom variabel=1
# local hovedlabel_0 "TrUkentlig" // Beskrivelse for dikotom variabel=0
# foreach trenVar of varlist Trener1 `trener_ny' {
#   levelsof `trenVar' if `dicVar'=="1" & `trenVar'<98, local(verdier_1) clean miss
#   levelsof `trenVar' if `dicVar'=="0" & `trenVar'<98, local(verdier_0) clean miss
#   replace `dicVar'="`hovedlabel_1', `trenVar'=`verdier_1'" if `dicVar'=="1" & `trenVar'<98
#   replace `dicVar'="`hovedlabel_0', `trenVar'=`verdier_0'" if `dicVar'=="0" & `trenVar'<98
# } 
#   
#   *****************************************************************
#     * FILTRERING, forskjell mellom kommune- og bydelsfil
#   capture rename klasse Klasse
#   capture rename kommune Kommune
#   capture rename tidspunkt Tidspunkt
#   capture su bydel_* // * Finne ut om dette er en KOMMUNE- eller BYDELsfil 
#   if _rc>0 { // hvis det er kommunefilen
#     keep `dicVar'S Kommune AAR Tidspunkt KJONN Klasse SOES vekt2020
# }
# if _rc==0 { // hvis det er bydelsfilen
# 	* Droppe eventuelle rene kommunetall (20.12.2021). Telle opp hvor mange av 
# 	* "bydel_..."-variablene som ikke er missing. Skal være = 1, for alle 
# 	* observasjoner skal kunne knyttes til en bydel.
# 	tempvar Bydel_nonmiss
# 	egen `Bydel_nonmiss'=rownonmiss(bydel*)
#   drop if `Bydel_nonmiss'==0 // drop hvis det er missing (bokstavelig talt) på
# 	// alle bydelsvariablene. F.o.m. 2021 kodes det 'missing' i stedet for 98/99.
# 	keep `dicVar'S Kommune AAR Tidspunkt KJONN Klasse bydel* SOES
#   drop if Ko==301 & (bydel_oslo==98 | bydel_oslo==99)
#   drop if Ko==1103 & (bydel_stavanger==98 | bydel_stavanger==99) 
#   capture drop if (Ko==1601 | Ko==5001) & (bydel_Trondheim==98 | bydel_Trondheim==99) //stor forbokstav
#   capture drop if (Ko==1601 | Ko==5001) & (bydel_trondheim==98 | bydel_trondheim==99) //liten forbokstav
#   drop if (Ko==1201 | Ko==4601) & 	(bydel_bergen==98 | bydel_bergen==99)
#   drop if Ko==(Ko==1601 | Ko==5001) & AAR==2013 // Kan ikke konverteres til de offisielle bydelene
#   replace Kommune=bydel_oslo if Ko==301 & AAR>=2015
#   replace Kommune=bydel_bergen if (Ko==1201 | Ko==4601) & AAR>=2015
#   capture replace Kommune=bydel_Trondheim if (Ko==1601 | Ko==5001) & AAR>=2015
#   capture replace Kommune=bydel_trondheim if (Ko==1601 | Ko==5001) & AAR>=2015
#   replace Kommune=bydel_stavanger if Ko==1103 & AAR>=2015	  // Storhaug mangler i 2016, pga. St Svithun mixup
#   assert Ko>30000
#   }
# 
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
# * linje med teller=0. Det er dette som rettes opp med neste fillin:
# * 23.1.2016: Rektangularisere, ellers mister vi strata med teller 0
# fillin `dicVar'S Kommune AAR KJONN klasse_6delt SOES
#                                     * For trening blir dette for mye fordi samme kommune får tall både for Trener1
#                                     *og for trener9/Trener9 og til slutt dobles nevneren (og halveres preva-
#                                                                                             *lensene). Må fjerne linjene med svaralternativer som ikke eksisterte, f.eks.
#                                     *Trener1 etter 2013.
#                                     tempvar spm test
#                                     generate `spm'="trener9" if ustrregexm(`dicVar'S,"rener9")==1
# replace  `spm'="trener1" if ustrregexm(`dicVar'S,"rener1")==1
# assert `spm'=="trener9" | `spm'=="trener1" 
# egen `test'=total(teller), by(Ko AAR `spm')
# drop if `test'==0 // Kutt ut linjene med spørsmål/år-kombinasjoner som ikke har
#                               // eksistrert (og derfor ikke må få nevner).
#                               replace teller =0 if teller==. & _f==1
#                               replace vekt2020 =0 if vekt2020==. & _f==1 // Ny des. 2020
#                               drop _f
#                               * NEVNER
#                               egen nevner = total(teller), by(Kommune AAR KJONN klasse_6delt SOES)
#                               * 23.1.2016: Fillin-linjen gir massevis av tomme strata, i år der komunen ikke 
#                               * har gjenniomført undersøkelsen. Dropper derfor hvis nevner 0
#                               drop if nevner==0  // disse settes trolig inn igjen nedenfor men skitt au
#                               
#                               *"FILLIN" av alder. Det kan være et problem at ikke alle "Alders"-verdiene er 
#                               * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
#                               * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
#                               * aldersverdier er representert i alle filer
#                               sort Kommune AAR KJONN klasse_6delt SOES // unngå evt. missingverdier på linje 1
#                               foreach alder in 10_1 10_2 8_1 8_2 98_1 98_2 99_1 99_2 9_1 9_2 {
#                                 local nylinje=_N+1
#                                 set obs `nylinje'
# 	replace klasse_6delt="`alder'" in `nylinje'
# 	replace Ko=Ko[1] in `nylinje'
# 	replace KJ=1 in `nylinje'
# 	replace AAR=AAR[1] in `nylinje'
# 	replace `dicVar'S=`dicVar'S[1] in `nylinje'
# 	replace SOES=SOES[1] in `nylinje'
# 	replace teller=0 in `nylinje'
# 	replace nevner=0 in `nylinje'
# 	replace vekt2020=0 in `nylinje'    // Ny i 2020
# }
# 
# *"FILLIN" av aar. Det kan være et problem at ikke alle "års"-verdiene er 
# * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
# * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
# * årsverdier er representert i alle filer
# sort Kommune AAR KJONN klasse_6delt SOES // unngå evt. missingverdier på linje 1
# forvalues aar = `forsteUngdataAar'/`innevaerendeAar' {
# 	local nylinje=_N+1
# 	set obs `nylinje'
# 	replace klasse_6delt=klasse_6delt[1] in `nylinje'
# 	replace Ko=0 in `nylinje'
# 	replace KJ=KJ[1] in `nylinje'
# 	replace AAR=`aar' in `nylinje'
# 	replace `dicVar'S=`dicVar'S[1] in `nylinje'
# 	replace SOES=SOES[1] in `nylinje'
# 	replace teller=0 in `nylinje'
# 	replace nevner=0 in `nylinje'
# 	collapse (sum) teller nevner vekt2020, by(Kommune AAR KJONN klasse_6delt SOES `dicVar'S)
# 	fillin Kommune AAR KJONN klasse_6delt SOES `dicVar'S
# 	replace teller=0 if teller==. & _fillin==1
# 	replace nevner=0 if nevner==. & _fillin==1
# 	replace vekt2020=0 if vekt2020==. & _fillin==1    // Ny i 2020
# 	drop _fillin
# }
# 
# * FJERNE 
# assert nevner==0 if AAR<=2013 & (ustrregexm(trener_1_9_dicS, "trener9") | AAR>=2014 & ustrregexm(trener_1_9_dicS, "Trener1"))
# drop if AAR<=2013 & ustrregexm(trener_1_9_dicS, "trener9")
# drop if AAR>=2014 & ustrregexm(trener_1_9_dicS, "Trener1")
# 
# * TOSTRING
# tostring _all, replace force  
# * RYDDING
# capture drop __0* //temp-variabelen  
# *******************************************************************************

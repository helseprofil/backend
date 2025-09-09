# /*
#   
#   Endringer: 
#   # _v2, JM nov 2020: Kommenterer ut omkoding av bydeler for årganger 2015 og 
#   utover. NOVAS koding av bydeler er korrigert for årganger 2015 og 
# utover. Uansett ligger ikke 2015 og nyere årganger i den gamle Bydelsfilen 
# som denne snutten er beregnet for. 
# # _v3, JM des 2020: Fjerne dikotomisering, opprette dummy <vekt2020> slik at 
# filen får de samme kolonnene som de andre filene i filgruppen.  
# 14.des.2021:
#   # Hardkoder endring av tidspunkt=99 til tidspunkt=1 for årgang 2021 og ut-
#   over. Årsaken er at alle kommuner f.o.m. 2021 har UNGDATA på våren, noe 
# som har ført til at NOVA sluttet å bruke variabelen "tidspunkt", og setter
# inn verdien 99 i filer de sender til oss. Denne verdien skaper trøbbel
# i dette skriptet, (f.eks. aldersgruppen 10_.020202 i tillegg til alders-
#                      gruppen 10_2) og fører senere til halvering av nevnerne.	  
# 
# <STATA>
#   ******************************************************************************/
#   * Denne snutten skal kun brukes på en gammel bydelsfil med DELID=KB_bydelfeilkod
# set more off
# assert delid=="KB_bydelfeilkod"
# 
# 
# local forsteUngdataAar=2010
# local sisteUngdataAar=2016
# local origVar=tab1_innles 
# drop if `origVar'>=98
# * FILTRERING
# keep `origVar' Kommune AAR Tidspunkt KJONN Klasse Bydel* 
#   drop if Ko==301 & Bydel_Oslo>=98
# drop if Ko==1103 & Bydel_Stavanger>=98
# drop if Ko==1601 & Bydel_Trondheim>=98
# drop if Ko==1601 & AAR==2013 // Kan ikke konverteres til de offisielle bydelene
# 
# * GEO. NB: SJEKK I DEN ORIGINALE spss-FILEN VEDR. KODEBOK FOR <Bydel_Oslo> osv.
# *             KODEBOKEN KAN VARIERE FRA ÅR TIL ÅR :<=     :<=
#   *Oslo 2012
# replace Kommune=30112 if  Bydel_Oslo==11 & Ko==301 & AAR==2012
# replace Kommune=30109 if  Bydel_Oslo==9 & Ko==301 & AAR==2012
# replace Kommune=30105 if  Bydel_Oslo==3 & Ko==301 & AAR==2012
# replace Kommune=30101 if  Bydel_Oslo==8 & Ko==301 & AAR==2012
# replace Kommune=30110 if  Bydel_Oslo==13 & Ko==301 & AAR==2012
# replace Kommune=30102 if  Bydel_Oslo==7 & Ko==301 & AAR==2012
# replace Kommune=30108 if  Bydel_Oslo==4 & Ko==301 & AAR==2012
# replace Kommune=30114 if  Bydel_Oslo==15 & Ko==301 & AAR==2012
# replace Kommune=30103 if  Bydel_Oslo==6 & Ko==301 & AAR==2012
# replace Kommune=30116 if  Bydel_Oslo==10 & Ko==301 & AAR==2012
# replace Kommune=30104 if  Bydel_Oslo==5 & Ko==301 & AAR==2012
# replace Kommune=30111 if  Bydel_Oslo==12 & Ko==301 & AAR==2012
# replace Kommune=30115 if  Bydel_Oslo==16 & Ko==301 & AAR==2012
# replace Kommune=30106 if  Bydel_Oslo==2 & Ko==301 & AAR==2012
# replace Kommune=30107 if  Bydel_Oslo==1 & Ko==301 & AAR==2012
# replace Kommune=30113 if  Bydel_Oslo==14 & Ko==301 & AAR==2012
# replace Kommune=30199 if  Bydel_Oslo==. & Ko==301 & AAR==2012
# drop if Bydel_Oslo==17 & Ko==301 & AAR==2012  // 17="Jeg bor ikke i Oslo"
# /* Kodingen av bydeler er korrigert for årganger 2015 og utover, og slike data 
# ligger ikke i den gamle Bydelsfilen som denne snutten er beregnet for. JM nov 2020
# *Oslo 2015 (NOVAs koding i bydelsvariabelen er annerledes enn for 2012-us.) 
# replace Kommune=30107 if Bydel_Oslo==1 & Ko==301 & AAR==2015
# replace Kommune=30106 if Bydel_Oslo==2 & Ko==301 & AAR==2015
# replace Kommune=30105 if Bydel_Oslo==3 & Ko==301 & AAR==2015
# replace Kommune=30108 if Bydel_Oslo==4 & Ko==301 & AAR==2015
# replace Kommune=30104 if Bydel_Oslo==5 & Ko==301 & AAR==2015
# replace Kommune=30103 if Bydel_Oslo==6 & Ko==301 & AAR==2015
# replace Kommune=30102 if Bydel_Oslo==7 & Ko==301 & AAR==2015
# replace Kommune=30101 if Bydel_Oslo==8 & Ko==301 & AAR==2015
# replace Kommune=30109 if Bydel_Oslo==9 & Ko==301 & AAR==2015
# replace Kommune=30112 if Bydel_Oslo==10 & Ko==301 & AAR==2015
# replace Kommune=30111 if Bydel_Oslo==11 & Ko==301 & AAR==2015
# replace Kommune=30110 if Bydel_Oslo==12 & Ko==301 & AAR==2015
# replace Kommune=30113 if Bydel_Oslo==13 & Ko==301 & AAR==2015
# replace Kommune=30114 if Bydel_Oslo==14 & Ko==301 & AAR==2015
# replace Kommune=30115 if Bydel_Oslo==15 & Ko==301 & AAR==2015
# drop if Bydel_Oslo==16 & Ko==301 & AAR==2015  // 16="Jeg bor ikke i Oslo"
# */
#   
#   *Stavanger 2013
# replace Kommune=110304 if Bydel_Stavanger==1 & Ko==1103 & AAR==2013
# replace Kommune=110302 if Bydel_Stavanger==2 & Ko==1103 & AAR==2013
# replace Kommune=110301 if Bydel_Stavanger==3 & Ko==1103 & AAR==2013
# replace Kommune=110305 if Bydel_Stavanger==4 & Ko==1103 & AAR==2013
# replace Kommune=110306 if Bydel_Stavanger==5 & Ko==1103 & AAR==2013
# replace Kommune=110307 if Bydel_Stavanger==6 & Ko==1103 & AAR==2013
# replace Kommune=110303 if Bydel_Stavanger==7 & Ko==1103 & AAR==2013
# /* Kodingen av bydeler er korrigert for årganger 2015 og utover, og slike data 
# ligger uansett ikke i den gamle Bydelsfilen som denne snutten er beregnet for.
# *Stavanger 2016(bydelsvariabelen er annerledes kodet enn i 2013-us.)
# replace Kommune=110301 if Bydel_Stavanger==1 & Ko==1103 & AAR==2016
# replace Kommune=110307 if Bydel_Stavanger==2 & Ko==1103 & AAR==2016
# replace Kommune=110304 if Bydel_Stavanger==3 & Ko==1103 & AAR==2016
# replace Kommune=110303 if Bydel_Stavanger==4 & Ko==1103 & AAR==2016
# replace Kommune=110306 if Bydel_Stavanger==5 & Ko==1103 & AAR==2016
# replace Kommune=110302 if Bydel_Stavanger==6 & Ko==1103 & AAR==2016
# // Storhaug mangler i 2016, pga. St Svithun mixup
# */
#   assert Ko>3000
# * KLASSE + SEMESTER (SEMESTER=<Tidspunkt>. 1=før sommeren, 2=etter sommeren)
# replace Tidspunkt=1 if Tidspunkt==99 & AAR>=2021 // "99" er nytt i 2021 og skaper trøbbel (jørgen 14.des.2021)
# gen klasse_6delt=strofreal(Klasse+7)+"_"+strofreal(2/Tidsp)
# replace klasse_6delt=strofreal(Klasse)+"_"+strofreal(2/Tidsp) if Klasse==98 | Klasse==99 
# * TELLER
# gen teller=1 
# capture gen vekt2020=1  // Ny i 2020! Legge inn <vekt2020> i bydelsfiler. 
# replace vekt2020=1 if vekt2020==. // Ny i 2020! Unødvendig siden ikke ekte vekt2020 i gamle bydelstall, men, men.
# collapse (sum) teller vekt2020, by(`origVar' Kommune AAR KJONN klasse_6delt) 
# count
# * 23.1.2016: Rektangularisere, ellers mister vi strata med teller 0
# fillin `origVar' Kommune AAR KJONN klasse_6delt
#                                     replace teller =0 if teller==. & _f==1
#                                     replace vekt2020 =0 if vekt2020==. & _f==1 // Ny des. 2020
#                                     pause
#                                     drop _f
#                                     * NEVNER
#                                     egen nevner = total(teller), by(Kommune AAR KJONN klasse_6delt) // des. 2020: Kun fra u-vektede tellere. Har ikke VALer nok til å beregne vektet nevner her.
#                                     * 23.1.2016: Fillin-linjen gir massevis av tomme strata, i år der komunen ikke 
#                                     * har gjenniomført undersøkelsen. Dropper derfor hvis nevner 0
#                                     drop if nevner==0
#                                     *"FILLIN" av alder. Det kan være et problem at ikke alle "Alders"-verdiene er 
#                                     * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
#                                     * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
#                                     * aldersverdier er representert i alle filer
#                                     sort Kommune AAR KJONN klasse_6delt // unngå evt. missingverdier på linje 1
#                                     foreach alder in 10_1 10_2 8_1 8_2 98_1 98_2 99_1 99_2 9_1 9_2 {
#                                       local nylinje=_N+1
#                                       set obs `nylinje'
# 	replace klasse_6delt="`alder'" in `nylinje'
# 	replace Ko=Ko[1] in `nylinje'
# 	replace KJ=1 in `nylinje'
# 	replace AAR=AAR[1] in `nylinje'
# 	replace `origVar'=`origVar'[1] in `nylinje'
# 	replace teller=0 in `nylinje'
# 	replace nevner=0 in `nylinje'
# 	replace vekt2020=0 in `nylinje'    // Ny i 2020
# }
# *"FILLIN" av aar. Det kan være et problem at ikke alle "års"-verdiene er 
# * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
# * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
# * årsverdier er representert i alle filer
# sort Kommune AAR KJONN klasse_6delt // unngå evt. missingverdier på linje 1
# forvalues aar = `forsteUngdataAar'/`sisteUngdataAar' {
# 	local nylinje=_N+1
# 	set obs `nylinje'
# 	replace klasse_6delt=klasse_6delt[1] in `nylinje'
# 	replace Ko=Ko[1] in `nylinje'
# 	replace KJ=KJ[1] in `nylinje'
# 	replace AAR=`aar' in `nylinje'
# 	replace `origVar'=`origVar'[1] in `nylinje'
# 	replace teller=0 in `nylinje'
# 	replace nevner=0 in `nylinje'
# 	collapse (sum) teller nevner vekt2020, by(Kommune AAR KJONN klasse_6delt `origVar')
# 	fillin Kommune AAR KJONN klasse_6delt `origVar'
# 	replace teller=0 if teller==. & _fillin==1
# 	replace nevner=0 if nevner==. & _fillin==1
# 	replace vekt2020=0 if vekt2020==. & _fillin==1    // Ny i 2020
# drop _fillin
# }
# * TOSTRING
# tostring _all, replace force  
# * RYDDING
# capture drop __0* //temp-variabelen  
# *******************************************************************************

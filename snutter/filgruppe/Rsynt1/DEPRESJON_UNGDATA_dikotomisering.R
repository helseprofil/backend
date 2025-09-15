# /*
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
#   
#   set more off
# assert delid=="KB_bydelfeilkod"
# 
# local forsteUngdataAar=2012 // Bør være første Ungdata-år i Kommunehelsa (2012)
# su AAR
# local innevaerendeAar=`r(max)'
# local origVar "depr" // Samlebetegnelse "inndata" til Rsynt1
# local dicVar=lower("`origVar'")+"_dic"
# *A DIKOTOMISERING.
# *A.1. Etablere <Depr> som gjennomsnitt av enkelt-items. Først: 98->. 99->.
# capture rename Depr*, lower
# foreach var of varlist depr* {
# 	replace `var'=. if `var'==98 | `var'==99
# }
# tempvar miss
# egen `miss' = rowmiss(depr1 depr2 depr3 depr4 depr5 depr6) // ant miss i 6 items
# egen `origVar'=rowmean(depr1 depr2 depr3 depr4 depr5 depr6) 
# capture su `origVar'
# if _rc!=0 {
# 	local origVar=lower("`origVar'")
# }
# capture drop *dic
# assert (`origVar'>=1 & `origVar'<=4) | `origVar'==.  
# gen `dicVar'=(`origVar'>=3 & `origVar'<=4) if `origVar'<. & `miss'<=2
# drop if `dicVar'==.
#               * B. Labels
#               label var `dicVar' "Depr. stemningsleie"
# local hovedlabel_1 "Ja_score>=3" // Beskrivelse for dikotom variabel=1
# local hovedlabel_0 "Nei_score<3" // Beskrivelse for dikotom variabel=0
# * Her pleier det å legges inn en prosedyre for å hindre feil ifm. copy-paste, men
#   *hverken overførbart til eller så relevant for Depr. stemningsleie 	 	
# label define tekstverdier 1 "`hovedlabel_1'" 0 "`hovedlabel_0'"
# label values `dicVar' tekstverdier
#               decode `dicVar', gen(`dicVar'S)
# * FILTRERING, forskjell mellom kommune- og bydelsfil
# capture su Bydel_* // * Finne ut om dette er en KOMMUNE- eller BYDELsfil 
# if _rc>0 { // hvis det er kommunefilen
# 	keep `dicVar'S Kommune AAR Tidspunkt KJONN Klasse 
#               }
# if _rc==0 { // hvis det er bydelsfilen
#   capture su Bydel_* // * Finne ut om dette er en KOMMUNE- eller BYDELsfil 
#   keep `dicVar'S Kommune AAR Tidspunkt KJONN Klasse Bydel*
# 	drop if Ko==301 & Bydel_Oslo>=98
# 	drop if Ko==1103 & Bydel_Stavanger>=98
# 	drop if Ko==1601 & Bydel_Trondheim>=98
# 	drop if Ko==1601 & AAR==2013 // Kan ikke konverteres til de offisielle bydelene
# 	* GEO. NB: SJEKK I DEN ORIGINALE spss-FILEN VEDR. KODEBOK FOR <Bydel_Oslo> osv.
# 	*             KODEBOKEN KAN VARIERE FRA ÅR TIL ÅR :<=     :<=
# 	*Oslo 2012
# 	replace Kommune=30112 if  Bydel_Oslo==11 & Ko==301 & AAR==2012
# 	replace Kommune=30109 if  Bydel_Oslo==9 & Ko==301 & AAR==2012
# 	replace Kommune=30105 if  Bydel_Oslo==3 & Ko==301 & AAR==2012
# 	replace Kommune=30101 if  Bydel_Oslo==8 & Ko==301 & AAR==2012
# 	replace Kommune=30110 if  Bydel_Oslo==13 & Ko==301 & AAR==2012
# 	replace Kommune=30102 if  Bydel_Oslo==7 & Ko==301 & AAR==2012
# 	replace Kommune=30108 if  Bydel_Oslo==4 & Ko==301 & AAR==2012
# 	replace Kommune=30114 if  Bydel_Oslo==15 & Ko==301 & AAR==2012
# 	replace Kommune=30103 if  Bydel_Oslo==6 & Ko==301 & AAR==2012
# 	replace Kommune=30116 if  Bydel_Oslo==10 & Ko==301 & AAR==2012
# 	replace Kommune=30104 if  Bydel_Oslo==5 & Ko==301 & AAR==2012
# 	replace Kommune=30111 if  Bydel_Oslo==12 & Ko==301 & AAR==2012
# 	replace Kommune=30115 if  Bydel_Oslo==16 & Ko==301 & AAR==2012
# 	replace Kommune=30106 if  Bydel_Oslo==2 & Ko==301 & AAR==2012
# 	replace Kommune=30107 if  Bydel_Oslo==1 & Ko==301 & AAR==2012
# 	replace Kommune=30113 if  Bydel_Oslo==14 & Ko==301 & AAR==2012
# 	replace Kommune=30199 if  Bydel_Oslo==. & Ko==301 & AAR==2012
# 	drop if Bydel_Oslo==17 & Ko==301 & AAR==2012  // 17="Jeg bor ikke i Oslo"
# 	*Oslo 2015 (NOVAs koding i bydelsvariabelen er annerledes enn for 2012-us.) 
# 	replace Kommune=30107 if Bydel_Oslo==1 & Ko==301 & AAR==2015
# 	replace Kommune=30106 if Bydel_Oslo==2 & Ko==301 & AAR==2015
# 	replace Kommune=30105 if Bydel_Oslo==3 & Ko==301 & AAR==2015
# 	replace Kommune=30108 if Bydel_Oslo==4 & Ko==301 & AAR==2015
# 	replace Kommune=30104 if Bydel_Oslo==5 & Ko==301 & AAR==2015
# 	replace Kommune=30103 if Bydel_Oslo==6 & Ko==301 & AAR==2015
# 	replace Kommune=30102 if Bydel_Oslo==7 & Ko==301 & AAR==2015
# 	replace Kommune=30101 if Bydel_Oslo==8 & Ko==301 & AAR==2015
# 	replace Kommune=30109 if Bydel_Oslo==9 & Ko==301 & AAR==2015
# 	replace Kommune=30112 if Bydel_Oslo==10 & Ko==301 & AAR==2015
# 	replace Kommune=30111 if Bydel_Oslo==11 & Ko==301 & AAR==2015
# 	replace Kommune=30110 if Bydel_Oslo==12 & Ko==301 & AAR==2015
# 	replace Kommune=30113 if Bydel_Oslo==13 & Ko==301 & AAR==2015
# 	replace Kommune=30114 if Bydel_Oslo==14 & Ko==301 & AAR==2015
# 	replace Kommune=30115 if Bydel_Oslo==15 & Ko==301 & AAR==2015
# 	drop if Bydel_Oslo==16 & Ko==301 & AAR==2015  // 16="Jeg bor ikke i Oslo"
# 
# 	*Stavanger 2013
# 	replace Kommune=110304 if Bydel_Stavanger==1 & Ko==1103 & AAR==2013
# 	replace Kommune=110302 if Bydel_Stavanger==2 & Ko==1103 & AAR==2013
# 	replace Kommune=110301 if Bydel_Stavanger==3 & Ko==1103 & AAR==2013
# 	replace Kommune=110305 if Bydel_Stavanger==4 & Ko==1103 & AAR==2013
# 	replace Kommune=110306 if Bydel_Stavanger==5 & Ko==1103 & AAR==2013
# 	replace Kommune=110307 if Bydel_Stavanger==6 & Ko==1103 & AAR==2013
# 	replace Kommune=110303 if Bydel_Stavanger==7 & Ko==1103 & AAR==2013
# 	*Stavanger 2016(bydelsvariabelen er annerledes kodet enn i 2013-us.)
# 	replace Kommune=110301 if Bydel_Stavanger==1 & Ko==1103 & AAR==2016
# 	replace Kommune=110307 if Bydel_Stavanger==2 & Ko==1103 & AAR==2016
# 	replace Kommune=110304 if Bydel_Stavanger==3 & Ko==1103 & AAR==2016
# 	replace Kommune=110303 if Bydel_Stavanger==4 & Ko==1103 & AAR==2016
# 	replace Kommune=110306 if Bydel_Stavanger==5 & Ko==1103 & AAR==2016
# 	replace Kommune=110302 if Bydel_Stavanger==6 & Ko==1103 & AAR==2016
# 																				  // Storhaug mangler i 2016, pga. St Svithun mixup
# 	assert Ko>3000
# }
# * KLASSE + SEMESTER (SEMESTER=<Tidspunkt>. 1=før sommeren, 2=etter sommeren)
# replace Tidspunkt=1 if Tidspunkt==99 & AAR>=2021 // "99" er nytt i 2021 og skaper trøbbel (jørgen 14.des.2021)
# gen klasse_6delt=strofreal(Klasse+7)+"_"+strofreal(2/Tidsp)
# replace klasse_6delt=strofreal(Klasse)+"_"+strofreal(2/Tidsp) if Klasse==98 | Klasse==99 
# * TELLER
# gen teller=1 
# capture gen vekt2020=1  // Ny i 2020! Legge inn <vekt2020> i bydelsfiler. 
# replace vekt2020=1 if vekt2020==. // Ny i 2020! Unødvendig siden ikke ekte vekt2020 i gamle bydelstall, men, men.
# collapse (sum) teller vekt2020, by(`dicVar'S Kommune AAR KJONN klasse_6delt) 
# * På dette stadiet: Hvis i en kommune/bydel, på et klassetrinn, for fx gutter
# * det var 0 som svarte et av svaralternativene, så vil det på dette stadiet 
# * mangle linje for denne kombinasjonen (mens det egentlig skulle ha vært en 
#                                         * linje med teller=0. Det er dette som rettes opp med neste fillin:
#                                           * 23.1.2016: Rektangularisere, ellers mister vi strata med teller 0
#                                         fillin `dicVar'S Kommune AAR KJONN klasse_6delt
# replace teller =0 if teller==. & _f==1
# replace vekt2020 =0 if vekt2020==. & _f==1 // Ny des. 2020
# drop _f
# * NEVNER
# egen nevner = total(teller), by(Kommune AAR KJONN klasse_6delt)
# * 23.1.2016: Fillin-linjen gir massevis av tomme strata, i år der komunen ikke 
# * har gjenniomført undersøkelsen. Dropper derfor hvis nevner 0
# drop if nevner==0  // disse settes trolig inn igjen nedenfor men skitt au
# 
# *"FILLIN" av alder. Det kan være et problem at ikke alle "Alders"-verdiene er 
# * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
# * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
# * aldersverdier er representert i alle filer
# sort Kommune AAR KJONN klasse_6delt // unngå evt. missingverdier på linje 1
# foreach alder in 10_1 10_2 8_1 8_2 98_1 98_2 99_1 99_2 9_1 9_2 {
# 	local nylinje=_N+1
# 	set obs `nylinje'
#                                         replace klasse_6delt="`alder'" in `nylinje'
# 	replace Ko=Ko[1] in `nylinje'
#                                         replace KJ=1 in `nylinje'
# 	replace AAR=AAR[1] in `nylinje'
#                                         replace `dicVar'S=`dicVar'S[1] in `nylinje'
#                                         replace teller=0 in `nylinje'
# 	replace nevner=0 in `nylinje'
#                                         replace vekt2020=0 in `nylinje'    // Ny i 2020
# }
# *"FILLIN" av aar. Det kan være et problem at ikke alle "års"-verdiene er 
# * representert i en gitt innfil. Kræsjer ved stabling med andre innfiler til  
# * filgruppe. Derfor legges det her inn noen  linjer som fører til at alle  
# * årsverdier er representert i alle filer
# sort Kommune AAR KJONN klasse_6delt // unngå evt. missingverdier på linje 1
# forvalues aar = `forsteUngdataAar'/`innevaerendeAar' {
# 	local nylinje=_N+1
# 	set obs `nylinje'
# replace klasse_6delt=klasse_6delt[1] in `nylinje'
# 	replace Ko=0 in `nylinje'
# replace KJ=KJ[1] in `nylinje'
# 	replace AAR=`aar' in `nylinje'
# 	replace `dicVar'S=`dicVar'S[1] in `nylinje'
# 	replace teller=0 in `nylinje'
# 	replace nevner=0 in `nylinje'
# 	collapse (sum) teller nevner vekt2020, by(Kommune AAR KJONN klasse_6delt `dicVar'S)
# fillin Kommune AAR KJONN klasse_6delt `dicVar'S
# 	replace teller=0 if teller==. & _fillin==1
# 	replace nevner=0 if nevner==. & _fillin==1
# 	replace vekt2020=0 if vekt2020==. & _fillin==1    // Ny i 2020
# 	drop _fillin
# }
# * TOSTRING
# tostring _all, replace force  
# * RYDDING
# capture drop __0* //temp-variabelen  
# *******************************************************************************

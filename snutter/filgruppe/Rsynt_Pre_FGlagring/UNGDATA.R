# /*
#   <STATA>
#   **********************************************************/
#   /*
#   do-fil denne snutten er hentet fra: Rsynt_Pre_FGlagring_Ungdata_   ...    
# GEO: 
#   # Følgende er GEO-hardkodet (for å beholde bare kommuner): drop if X<101, 
#   drop if X>=9999
# # Sårbart for nye kommune- eller bydelskoder for Stavanger og Trondheim.
# Endringer:
#   # nov. 2020, Jørgen: Ifm med flytting av dikotomisering fra RSYNT1 til kode-
#   bok: Omkoding av f.eks. NAERTILB4 i kodebook (3, 4 og 5 kodes til "dårlig") 
# fører til at tre og tre linjer blir duplikater på tab'ene. Disse må aggre-
# 	  geres til én og én linje for at det ikke skal bli feilberegning av nevner
# 	  når vi lager samlekategori for SOES. 
# 	# v3 des. 2020, Jørgen: Legge til rette for vekting ifm. med utarbeiding av
# 	  lands- og fylkestall.  
# 	# Diskutabelt ved versjon_3: A) Som følge av mange K-sammenslåinger 1.1.2020 
# 	  forsøkes det å slå sammen Ungdataundersøkelser tilsvarende, så langt det 
# 	  virker rimelig. Resten av historiske undersøkelser i sammenslåtte K slettes.
# 	  Sammenslåing av undersøkelser medfører at noen undersøkelser flyttes i tid.
# 	  I skriptet gjøres både flytting og sletting *etter* L- og F-tall. Burde vel
# 	  vært før. I hvert fall flyttingene. Kanskje også slettingene. Sletting først
# 	  gir L- og F-tall basert på akkurat samme datagrunnlag som kommunetallene 
# 	  (max sammenlignbarhet). Sletting sist gir max datagrunnlag for L- og F-tall. 
# 	  Saken er diskutert med de andre og det er argumenter for at vi lar det stå 
# 	  som det er.
# 	# 13. jan. 2021
# 	  "Sletter" 2017-undersøkelsen i Oppegård. Denne skal ikke være med, heller  
# 	  ikke som del av fylkes- og landstall. Oppegård gjorde undersøkelsen på nytt
# 	  i 2018 og vil bli overrepresentert i fylkes- eller landstall dersom også 
# 	  2017 inkluderes.
# 	# 21.okt.2021 Jørgen: Erstatter "SIVST" med "INNVKAT"
# 	# JM 1. nov. 2022: "Sletter" alle undersøkelser gjennomført på høsten. Med 
# 	  ny standardisering (dvs. alle undersøkelser standardiseres mot siste årgang
# 	  i filen), finnes det ikke lenger en standardpopulasjon for høst-under-
# 	  søkelsene som fant sted i årene 2012-2016.
# 	# JM 30. nov. 2022 A: Gjeninnfører undersøkelser gjennomført på høsten (siden 
# 	  vi går tilbake til opprinnelig opplegg med at hver årgang standardiseres 
# 	  mot sitt landstall). (Ble det for ustabile rater med den nye standardiserings-
# 	  metoden, eller hva var det for noe?)
# 	# JM 30. nov. 2022 B: 2021-årgangen er så spesiell (pga. nedstengning) at 
# 	  lands- og fylkestall for denne årgangen skal være ett-årige. 
# 	# JM 7. des. 2022 C: 2022-årgangens lands- og fylkestall skal også være ett-
# 	  årige. JM 8. sept. 2023: Dette stemmer nok med virkeligheten, 2022 har nok 
# 	  ettårige lands- og fylkestall, selv om det lenger nede står at 2022 skulle 
# 	  ha to-årige tall (let rundt linje 210), kanskje 2020+2022? Hvorfor ombestemte
# 	  vi oss og gikk inn for ettårige L og F-tall for 2022? Kanskje for bedre å 
# 	  visualisere eventuelle endringen fra pandemi til post-pandemi?
# 	# JM 23. des. 2022: Livskavalitet går gjennom men får ikke fylkes- og landstall. 
# 	  Eneste spesielle med Livskavalitet er at tidsserien starter med 2021. Inndata
# 	  har altså bare to årganger. JM 8. sept. 2023: Litt rart med denne kommentaren 
# 	  her under "ENDRINGER", men problemet ble tydeligvis fikset.
# 	# JM 21. sept. 2023: Redaksjonen har besluttet: 
# 		a) L- og F-tall for 2021 og 2022 forblir ettårige for alltid. 
# 		b) L- og F-tall for 2023 forblir toårige for alltid.
# 		c) Tilbake på track med treårige L- og F-tall fom. 2024-årgangen. 
# 	  Skriptet er sjekket og skal oppfylle denne spec'en. 
# # JM 20.11.2023: "Jukset" rundt Ungdata i Drammen: Endre slik at tidligste 
# år i en tidsserie ikke kan være før første år indikatoren var med i spørre-
#   skjemaet. Dette kan bare skje når man endrer årstallet for en undersøkelse,
# slik tilfellet er for 0625 Nedre Eiker og 0711 Svelvik. 
# # JM 18.12.2023: Omkoder kommunetall MIDLERTIDIG til "current code" ifm.
# aggregering til fylkestall. Utenom dette beholdes originale K-koder fordi
# vi trenger de originale K-kodene når vi tweaker til noen av Ungdata-under-
#   søkelsene for å passe sammen mtp. kommunesammenslåinger. 
# */
#   * SETTINGS
# set more off
# pause off
# local MA=3  // Hvor mange av årgangene i hvert lands- og fylkestall? 
#   local cutoff=80 // En del av Ungdataundersøkelsene i årene forut for en kommune-
#   // sammenslåing kan slås sammen til en Ungdata-tidsserie for den sammenslåtte 
# // kommunen, men vi setter en cutoff-verdi for hvor lav andel av den nye 
# // kommunen en slik sammenslått Ungdataundersøkelse kan få lov til å representere. 
# tempfile KBtall stablet SOES_1_99
# * UNIVERSELL KVALITETSKONTROLL AV SNUTTER (DEL 1/2)
# ****************************************************
#   *i. Lagre varlist i inndata (sjekkes mot ditto i utdata nederst i snutten)
# qui des, varlist
# local varlist_inn "`r(varlist)'"
# *ii. Lagre variabelTYPEne i inndata (for sjekking mot ditto i utdata)
# local vartypeListInn="" // Skal ende opp med f.eks. "str num num str ..."
# foreach var of varlist _all {
#   local vartype : type `var'
# 	if ustrregexm("`vartype'","str") local vartypeListInn=`"`vartypeListInn'"'+"str "
#   else local vartypeListInn=`"`vartypeListInn'"'+"num "
# }
# 
# * UNGDATA
# ******************************************************
#   
#   su AARl
# local startaar=`r(min)' // Skal brukes senere
# 
# * Slette Oppegård-2017 i tilfelle denne ved en feil er blitt med i leveranse fra 
#   *NOVA. Kunne ha slettet records, men dette er litt skummelt i en fil som (av 
#   *en eller annen grunn) må være helt rektangulær.
# foreach var of varlist ANTALL NEVNER VEKT {
# 	replace `var'=0 if GEO=="0217" & AARl==2017
# }
# 
# * SELVE Ålesund kjørte sin egen UNGDATA i 2023, men under den misvisende kommune-
#   *koden "1507" (som er koden for det samlede Haram+Ålesund i perioden 2020-2023).
# *For at denne undersøkelsen skal oppfattes som en ren Ålesund-undersøkelse, må 
# *den få koden for Ålesund anno 2024 (etter splitting fra Haram), altså "1508".
# replace GEO="1508" if GEO=="1507" & AARl==2023
# 
# * Lage den vektede nevneren
# egen vNEVNER = total(VEKT), by(GEOniv FYLKE GEO AAR* KJONN ALDER* UTDANN INNVKAT LANDBAK TAB2)   // Ny!
#   
#   
#   * Fjerne årganger der spørsmålet ikke var med.
# su AARl
# forvalues k=`r(min)'/`r(max)' {
# 	su NEVNER if AARl==`k'
# if r(mean)==0 {
#   drop if AARl==`k'
# 	}
# }
# 
# * Fjerne dummy landstall (N=0) innført på Rsynt1, og fikse en kjent feil i en 
#   *ORG-fil (duplikater i 1931 Lenvik). FILID=1276 
# *a. Finne ut om GEO er num. el. str.. Hvis string, er hele landet "0" eller "00"? 
# local typeGEO : type GEO // f.eks. "str6"
# *b. Fjerne landstall med N=0, og korrigere for duplikater i Lenvik
# return clear  // sletter tidligere resultater av bl.a. -count-
# if ustrregexm("`typeGEO'","str") {
# 	local Lenvik `""1931""'
# 	count if GEO=="0"
# 	if r(N)>0 local landskode `""0""'
# 	if r(N)==0 local landskode `""00""'
# }
# else {
# 	local landskode = 0
# 	local Lenvik = 1931
# }
# drop if GEO==`landskode' & NEVNER==0
# foreach var of varlist ANTALL NEVNER VEKT vNEVNER {
# 	replace `var'=`var'/2 if GEO==`Lenvik' & (KOBLID==1395 | KOBLID==1435 | KOBLID==1457 | KOBLID==1461 | KOBLID==1463 | KOBLID==1464 | KOBLID==1467 | KOBLID==1470 | KOBLID==1473 | KOBLID==1474 | KOBLID==1476 | KOBLID==1478 | KOBLID==1480 | KOBLID==1482 | KOBLID==1485 | KOBLID==1488)
# }
# * 2017-tallene for bydeler i Bergen ser ut til å inkludere privatskoler i bydelstallene.
#   * Særlig problematisk for Danielsen i Bergenhus, så Bergenhustall for 2017 tas ut.
#   * Gjelder foreløpig bare den filen vi mottok i 2022. Satser på at vi ikke bruker den
#   * etter 30. juni 2023.
# drop if GEO=="120102" & AARl==2017 & td("`c(current_date)'")<=td("30 Jun 2023")
# 
# * Slå sammen de linjene som er blitt duplikater på tab'ene etter omkodingen (diko-
#                                                                                *tomiseringen) i kodebok. (Nov. 2020)
# ***********************************************************************************
#   collapse (sum) ANTALL VEKT *_a (mean) NEVNER vNEVNER *_f, by(GEOniv FYLKE GEO AAR* KJONN ALDER* UTDANN INNVKAT LANDBAK TAB2 TAB1 ) // Lagt til <VEKT> des. 2020
# gen KOBLID=.
# gen ROW=.
# 
# 
# * pause sjekk Eidsberg
# 
# * Lage samletall for sosioøk. status. Flyttet fra ETTER L- og F-tall (januar 2020)
# ***********************************************************************************
#   replace TAB2="98" if TAB2=="NA" // Den ene bydelsfilen ble laget før SOES var påtenkt
# replace TAB2="0" if TAB2=="98" // januar 2020 Unaturlig å skille mellom 0 og 98
# save `SOES_1_99', replace // originale verdier av SOES
# drop if TAB2=="0" // Linjer med "SOESsamlet" skal ikke være med når vi aggregerer
# 				// til SOESsamlet fra SOES_1,2,3,4,5
# collapse (sum) ANTALL NEVNER VEKT vNEVNER *_a (mean) *_f, by(GEOniv  AARl AARh ALDER* KJONN UTDANN INNVKAT LANDBAK TAB1 FYLKE GEO)  // Lagt til <VEKT> des. 2020
# gen KOBLID=.
# gen ROW=.
# gen TAB2="0"  // SOES=0 (sosioøkonomisk status samlet)
# append using `SOES_1_99'
# replace ROW=_n
# * Vi skal ikke ha med kommunetall etter SOES før kommunetallene kan sammenlignes
# *med treårig landstall etter SOES. Det første treårige landstallet med SOES er
# *2014-2016, iom. at SOES ble tatt inn i 2014. Det første året med kommunetall 
# *som kan sammenlignes med tre år med landstall etter SOES, er 2016 (sammenlignes
#                                                                     *med landstall for siste tre år: 2014-2016). Dette betyr at vi skal slette 
# *kommunetall etter SOES for 2014 og 2015 (og bare beholde tall for SOES=0), 
# *men vi må ikke slette disse kommunetallene før vi har laget landstallet for 
# *2014-2016 og 2015-2017. Se lenger nede etter 
# * 		-replace ANTALL=. if AARl<2016 & TAB2!="0" ... -
#   *Dette løser samtidig problemet med at sammenslåing av undersøkelser med og 
# *uten SOES (etter flytting av en undersøkelse *uten* SOES til et år der alle 
#             *undersøkelser er *med* SOES).  
# 
# 
# * Lagre KOMMUNE- OG BYDELSTALL, 1-årige
# *****************************************************
#   * a. Slette høst-data f.o.m. 2016
# foreach var of varlist ANTALL NEVNER VEKT vNEVNER {   // Lagt til <VEKT> des. 2020
#   replace `var'=0 if AARl>=2016 & (ALDERl==1 | ALDERl==3 | ALDERl==5)  
# }
# * b. Lagre kommune- og bydelstall
# save `KBtall', replace
# save `stablet', replace
# 
# 
# 
# 
# 
# 
# 
# * Aggregere til Lands- og fylkestall, 3-årige
# *****************************************************
# * Skiller mellom de første periodene som skal bruke høst-undersøkelser, og de  
#   *nyere som ikke skal det. 
# foreach periode in t.o.m.2015 f.o.m.2016 {
# 	* a. Fylkestall
# 	use `KBtall', clear
# * Noen kommuner bytter fylke. Setter dem midlertidig til ukjent K i det nye F
# replace FYLKE="19" if GEO=="1852" // Tjeldsund
# replace FYLKE="16" if GEO=="1567" | GEO=="1571" // Rindal, Halsa
# replace FYLKE="15" if GEO=="1444" // Hornindal
# replace FYLKE="06" if GEO=="0711" | GEO=="0532" | GEO=="0533" // Svelvik, Jevnaker, Lunner
# replace GEO="1999" if GEO=="1852" // Tjeldsund
# replace GEO="1699" if GEO=="1567" | GEO=="1571" // Rindal, Halsa
# replace GEO="1599" if GEO=="1444" // Hornindal
# replace GEO="0699" if GEO=="0711" | GEO=="0532" | GEO=="0533" // Svelvik, Jevnaker, Lunner
# * Slette resten av høst-tallene i filen dersom vi lager LF-tall for treårs-
#   *perioder f.o.m. (2014-)2016
# if "`periode'"=="f.o.m.2016" {
#   foreach var of varlist ANTALL NEVNER VEKT vNEVNER {   // Lagt til <VEKT> des. 2020
#     replace `var'=0 if (ALDERl==1 | ALDERl==3 | ALDERl==5)
# 		}
# 	}
# 	* Trimme slik at filen nå kun har kommunetall
# 	destring GEO, gen(X)
# 	drop if X<101 
# 	drop if X>=9999  // endret 3.11.2017 pga Trondelag
# 	drop X
# 	assert GEOniv=="K"
# 	tempfile datagrunnlag_F
# 	sort GEO 
# 	save "`datagrunnlag_F'" // Kommunedata på original GEO
# 	* Omkode kommunekodene til Current Code (JM 18.12.2023). Ellers vil Østfold-,
# 	  *Akershus- og Buskerud-kommunene i årgangene 2020-2023 bli aggregert til 
# 	  *fylke 30 Viken (som vil omkodes til 99 "ukjent fylke" i LagKube).
# 	* Hente inn omkodingstabellen
# 	clear
# 	odbc load, dsn(`"MS Access Database; DBQ=O:/Prosjekt/FHP/PRODUKSJON\STYRING/KHELSA.mdb"') table("KnrHarm")
# 	sort GEO 
# 	merge GEO using "`datagrunnlag_F'"
# 	drop if _merge==1 // dette er kommunekoder som aldri har hatt Ungdata
# 	replace GEO_omk=GEO if GEO_omk=="" // f.x. hvis GEO=1103; denne finnes ikke i
# 		// KnrHarm's GEO_omk fordi 1103 aldri har vært omkodet. Det samme med 
#     // f.x. 4601; Bergen har skiftet fra 1201 til 4601, men 4601 selv har 
#     // aldri blitt omkodet. 
#     * Nå er det GEO_omk som er den nye GEO
#     drop GEO 
#     drop HARMstd
#     rename GEO_omk GEO
#     replace FYLKE=substr(GEO,1,2) 
#     
#     * Business
#     * Først erstatte ANTALL og NEVNER med de vektede variantene (des. 2020) 	
#     drop ANTALL NEVNER
#     rename (VEKT vNEVNER) (ANTALL NEVNER) 							  // Ny!
#       *pause A før aggreg til Fylke
#     
#     * Lagre de ett-årige fylkestallene for 2021 og 2022
#     preserve
#     collapse (sum) ANTALL NEVNER *_a (mean) *_f, by(GEOniv  AARl AARh ALDER* KJONN UTDANN INNVKAT LANDBAK TAB* FYLKE)
#     keep if AARl==2021 | AARl==2022
#     tempfile ettaarigF2021_2022 // fylkestall for 2021 og 2022
#     save "`ettaarigF2021_2022'"
#     restore
#     
#     ***************************************************
#       * IOM. -rename (VEKT vNEVNER) (ANTALL NEVNER)- kan nå resten stå som før
#     preserve
#     collapse (sum) ANTALL NEVNER *_a (mean) *_f, by(GEOniv  AARl AARh ALDER* KJONN UTDANN INNVKAT LANDBAK TAB* FYLKE)
#     
#     * Glidende summer av T og N
#     foreach var in ANTALL NEVNER {
#       replace `var'=0 if AARl==2021 // 2021-tallene settes her til null fordi 
# 			// tallene fra pandemiåret (2021) hverken skal inngå i F- og L-tallene 
# 			// for 2022 eller 2023. (Det er anderledes med 2022-tallene; de skal
# 			// inngå i F- og L-tallene for 2023 og 2024, og settes IKKE til null.)
# 		bysort GEOniv ALDER* KJONN UTDANN INNVKAT LANDBAK TAB* FYLKE (AARl AARh) : gen `var'_cum=sum(`var')
# 		by GEOniv ALDER* KJONN UTDANN INNVKAT LANDBAK TAB* FYLKE: gen `var'_cum2=`var'_cum-`var'_cum[_n-`MA']
# by GEOniv ALDER* KJONN UTDANN INNVKAT LANDBAK TAB* FYLKE: replace `var'_cum2=`var'_cum if _n-`MA'==0
# *li GEOniv ALDERl KJONN TAB* FYLKE AAR* `var' `var'_cum* in 1/44
# 		*pause `var'
# replace `var'=`var'_cum2 // missing på de første årene spørsmålet var med, men dette blir fikset
# 		drop *_cum*
# 	}
# 	drop if AARl==2021 | AARl==2022 // de glidende summene for 2021 og 2022 skal 
# 		// vekk. Det var en stor diskusjon om F- og L-tallene for 2022 skulle om-
# 		// fatte 2020 og 2022, men vi landet på at de skulle være ettårige (for 
# 		// nærmere begrunnelse, hør med Hanna).
# 	append using "`ettaarigF2021_2022'"
# di "`periode'"
# 	if "`periode'"=="t.o.m.2015" {
# 		keep if AARl<=2015
# 	}
# 	if "`periode'"=="f.o.m.2016" {
# 		keep if AARl>=2016 & AARl<.
# 	}
# 	gen KOBLID=.
# 	gen ROW=.
# 	gen GEO=FYLKE
# 	replace GEOniv="F"
# 
# 	append using `stablet'
# replace ROW=_n
# *pause BREAK
# save `stablet', replace
# 	restore
# 
# 	
# 	
# 	
# 	
# 	
# 	
# 	* b. Landstall
# 	*****************************************************
# 	* Sjekke at filen nå kun har kommunetall
# 	destring GEO, gen(X)
# 	di "Sjekke at det her kun er kommune- og bydelstall"
# 	assert X>=101 & X<=9999 & GEOniv=="K" // JM 19.des.2023: Kommunekoden 9999 
# 		// settes til lovlig pga. kodene 3099, 3899 og 5499 fra 2020 da en del 
# 		// Ungdata på enkelte skoler/ kommuner var for ufullstendige til å kunne
# 		// gi kommunetall, men OK til å inngå i fylkestall. Men, splittingen av 
# 		// f.eks. 30 Viken 1.1.2024 forhidrer at data med GEO=3099 (ukjent 
# 		// kommune i Viken) kan mappes til fylke fom. 2024-profilene.
# 	drop X
# 
# 
# 	* Aggregere til landstall
# 	collapse (sum) ANTALL NEVNER *_a (mean) *_f, by(GEOniv AARl AARh ALDER* KJONN UTDANN INNVKAT LANDBAK TAB*)
# 	* Lagre de ett-årige landstallene for 2021
# 	preserve
# 	keep if AARl==2021 | AARl==2022
# 	tempfile ettaarigL2021_2022 // landstall for 2021
# 	save "`ettaarigL2021_2022'"
# 	restore
# 	* Glidende summer
# 	foreach var in ANTALL NEVNER {
# 	    replace `var'=0 if AARl==2021 // 2021-tallene settes her til null fordi 
# 			// tallene fra pandemiåret (2021) hverken skal inngå i F- og L-tallene 
# 			// for 2022 eller 2023. (Det er anderledes med 2022-tallene; de skal
# 			// inngå i F- og L-tallene for 2023 og 2024, og settes IKKE til null.)
# 		bysort GEOniv ALDER* KJONN UTDANN INNVKAT LANDBAK TAB* (AARl AARh) : gen `var'_cum=sum(`var')
# 		by GEOniv ALDER* KJONN UTDANN INNVKAT LANDBAK TAB*: gen `var'_cum2=`var'_cum-`var'_cum[_n-`MA']
# 		by GEOniv ALDER* KJONN UTDANN INNVKAT LANDBAK TAB*: replace `var'_cum2=`var'_cum if _n-`MA'==0
# 		*li GEOniv ALDERl KJONN TAB* FYLKE AAR* `var' `var'_cum* in 1/44
# 		*pause `var'
# 		replace `var'=`var'_cum2 // missing på 2012 0g 13, men blir fikset
# 		drop *_cum*
# 	}
# 	drop if AARl==2021 | AARl==2022  // de 3-årige tallene for 2021 skal vekk. NB: Husk 
# 		// (ved kval.kontroll) at de 3-årige tallene for 2021 faktisk mangler 
# 		// tall for 2021 for disse er satt til null.
# 	append using "`ettaarigL2021_2022'"
# 
# 	gen KOBLID=.
# 	gen ROW=.
# 	gen FYLKE="00"
# 	gen GEO=`landskode'
# if "`periode'"=="t.o.m.2015" {
#   keep if AARl<=2015
# }
# if "`periode'"=="f.o.m.2016" {
#   keep if AARl>=2016 & AARl<.
# } 
# replace GEOniv="L"
# append using `stablet'
# 	save `stablet', replace
#     }
#     replace ROW=_n
#     ********************************************************************************
#       
#       
#       * Dersom de to første årene nå er missing (normalt er de det), skal de ha samme 
#     *fylkes- og landstall som det tredje.
#     *LIVSKVALITET er et unntak (JM 22.des.2022): 
#       *# Det første landstallet (2021) skal alltid, også i fremtidige kuber, få 
#       *være ett-årig, pga. coronanedstenging.
#     *# Det andre landstallet (2022) skal få være ettårig første gang vi lager 
#       *kube (desember 2022). 
#     * Siden LIVSKVALITET-filen kommer hit UTEN å være missing på 2021 og 2022,
#     *kan en foreløpig fiks være at de to første årene erstattes med det tredje
#     *KUN HVIS de to første er missing. Altså legge til en "if `var'==." der 
#     *to første årene erstattes.
#     ********************************************************************************
#       * a) Identifisere hva som er det tredje året (NB på dette stadiet er det fjernet  
#                                                     *årganger der spørsmålet ikke var med => det første året i filen nå er det 
#                                                     *første året spørsmålet var med.
#                                                     su AARl
#                                                     local tredje=r(min)+2
#                                                     * b) Kopiere LF-tall fra det tredje året til de to første
# 		foreach var in ANTALL NEVNER {
# 		  gen `var'_`tredje' = `var' if AARl==`tredje' & (GEOniv=="F" | GEOniv=="L")
# 	bysort GEO ALDERl KJ UT LAN TAB*: egen `var'_`tredje'_2=mean(`var'_`tredje')
# sort GEO  ALDERl  KJONN  UTDANN  INNVKAT  LANDBAK  TAB* AAR*
#   replace `var'=`var'_`tredje'_2 if AARh<`tredje' & (GEOniv=="F" | GEOniv=="L") & `var'==. // & `var'==. er en tilpasning til LIVSKVALITET_ungdata
# drop `var'_`tredje'*
# }
# 
# 
# 
# pause E Etter F og L, men før kommunesammenslåing av undersøkelser. Burde det ikke vært motsatt rekkefølge? :-()
# 
# 		
# * Kommunesammenslåing - Ungdatasammenslåing
# ********************************************************************* 		
# * SAMMENSLåING (EVT. ANNULLERING) AV GAMLE UNDERSøKELSER (bl.a. i.f.m. Kommune-
# * sammenslåing) skjer på to måter: 
# *---------------------------------------------------------------------------
# * a. Et dedikert skript:
# 	* 1. Vurdere om en undersøkelse fra en *liten* tidligere kommune ligger nært
# 	     *nok i tid til å kunne slås sammen med en undersøkelse fra en større av
# 		 *de andre kommunene den er blitt slått sammen med. Hvis ikke, annullere
# 		 *den (sette T=N=0).
# 	* 2. Hvis OK, flytte den lille undersøkelsen til samme år som den store (se-
# 	     *tte AAR=året for undersøkelsen i den største kommunen).
# 	* 3. Finne ut om den enkelte samling av undersøkelser dekker en akseptabel 
# 	     *andel av den nye kommunen (si 85 %). Hvis ikke, annullere både de den (sette T=N=0).
# * For å bedømme om en sammenslått Ungdataundersøkelse (fra tiden før en kommune-
# * sammenslåing) vil representere en stor nok del av den sammenslåtte kommunen,
# * må man hekte på folketall osv. osv. PROBLEM: På dette stadiet er ikke GEO 
# * harmonisert. Derfor blir det komplisert å koble på folketall. Som en konsekvens
# * av dette lages koden for Ungdatasammenslåing ikke on the fly her, men utenfor 
# * løypen, basert på Ungdata som ER geo-harmonisert. Opplegg: Ungdataundersøkelser
# * som ikke skal være med videre får AAR satt til missing.
# 
# * NB: VED FLYTTING (I TID) OG SAMMENSLåING AV UNDERSøKELSER;
# 
# 	* EN UNDERSøKELSE MED HøST-DATA (DVS. ALDER=1,3,5) Må IKKE FLYTTES TIL 2016 
# 	  *ELLER SENERE (DER DET IKKE FINNES LANDSTALL FOR DISSE VERDIENE AV ALDER).
# 	* MAN KAN IKKE SLå SAMMEN EN UNDERSøKELSE  BARE SOES=0 MED KAN IKKE BESTå FåR EN BLANDING AV 
# 
# * FøRST NOEN MANUELLE ENDRINGER 
# * a) Være litt snille med Drammen fordi NOVA gjør det samme. JM nov. 2023: Sam-
# * tidig korrigere dersom 2017-undersøkelsene til 0625 Nedre Eiker og 0711 Svelvik
# * flyttes til et år der indikatoren ikke var med i spørreskjemaet (f.eks. medie-
# * bruk).
# foreach AARx of varlist AAR* {
# replace `AARx'=2016 if real(GEO)==0625 & `AARx'==2017 // En liten undersøkelse flyttes TILBAKE i tid.
# replace `AARx'=2016 if real(GEO)==0711 & `AARx'==2017 // --'''--- Svelvik ble midlertidig omkodet 
# 		// til 0699 ovenfor, men her er vi (og andre) tilbake på originalt Knr. 
# 		}
#   drop if AARl<`startaar'
# * b) Sammenslåing i trøndelag i 2018 som trenger sletting av dublett (skriptet 
# *    som lager disse kommandoene tar bare for seg sammenslåinger i 2020). De fleste
# *    2018-sammenslåinger trenger verken sletting av dubletter eller flytting i 
# *    tid av småundersøkelser, men denne i Trøndelag var et unntak. 
# foreach TN in ANTALL NEVNER {
# replace `TN'=0 if real(GEO)==1718 & AARl==2016 // Fjerne dublett.
#   }
# * c) Slette høstundersøkelser for spørsmål som ble innført i 2014. årsak: Kun to
# *    års overlapp (2014, 2015) => Ingen landstall => ingen standardisering
# su AARl
# if `r(min)'>=2014 {
# foreach TN in ANTALL NEVNER {
# 	replace `TN'=0 if  (ALDERl==1 | ALDERl==3 | ALDERl==5) 
# }
# }
# 
# 
# 
# 
# * Nå; AUTOMATISK GENERERTE SLETTINGER OG FLYTTINGER FOR 2020-SAMMENSLåINGENE
# ****************************************************************************************************************
#   * SLETTINGER
# foreach TN in ANTALL NEVNER {
#   replace `TN'=0 if (real(GEO)==5023 | real(GEO)==1636) & AARl==2017 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1854 & AARl==2014 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1551 & AARl==2016 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1545 & AARl==2016 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1534 & AARl==2014 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1529 & AARl==2014 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1523 & AARl==2015 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1260 & AARl==2012 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1259 & AARl==2012 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1256 & AARl==2012 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1241 & AARl==2016 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1231 & AARl==2019 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==1018 & AARl==2012 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0711 & AARl==2017 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0711 & AARl==2013 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0628 & AARl==2015 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0627 & AARl==2015 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0625 & AARl==2013 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0625 & AARl==2017 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0226 & AARl==2018 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0136 & AARl==2018 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# replace `TN'=0 if real(GEO)==0123 & AARl==2019 // Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
# }
# * FLYTTINGER
# foreach AARx of varlist AAR* {
#   replace `AARx'=2016 if (real(GEO)==5023 | real(GEO)==1636) & `AARx'==2014 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2015 if real(GEO)==1551 & `AARx'==2013 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2015 if real(GEO)==1545 & `AARx'==2014 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2015 if real(GEO)==1543 & `AARx'==2013 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2018 if real(GEO)==1543 & `AARx'==2017 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2018 if real(GEO)==1439 & `AARx'==2017 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2016 if real(GEO)==1439 & `AARx'==2015 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2014 if real(GEO)==1439 & `AARx'==2012 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2019 if real(GEO)==1260 & `AARx'==2017 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2019 if real(GEO)==1259 & `AARx'==2017 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2019 if real(GEO)==1256 & `AARx'==2017 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2019 if real(GEO)==1245 & `AARx'==2017 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2017 if real(GEO)==1231 & `AARx'==2016 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2013 if real(GEO)==1231 & `AARx'==2012 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2014 if real(GEO)==1027 & `AARx'==2013 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2014 if real(GEO)==1018 & `AARx'==2013 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2014 if real(GEO)==1017 & `AARx'==2013 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2014 if (real(GEO)==0716 | real(GEO)==0716) & `AARx'==2013 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2014 if real(GEO)==0628 & `AARx'==2012 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2019 if real(GEO)==0227 & `AARx'==2018 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2016 if real(GEO)==0227 & `AARx'==2015 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2013 if real(GEO)==0226 & `AARx'==2012 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2016 if real(GEO)==0226 & `AARx'==2015 // Rekode AAR for godkjente små-undersøkelser.
# replace `AARx'=2015 if real(GEO)==0217 & `AARx'==2014 // Rekode AAR for godkjente små-undersøkelser.
# }
# * SLETTINGER
# foreach TN in ANTALL NEVNER {
# replace `TN'=0 if (real(GEO)==5024 | real(GEO)==1638) & AARl==2012 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if (real(GEO)==5018 | real(GEO)==1630) & AARl==2013 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if (real(GEO)==5018 | real(GEO)==1630) & AARl==2017 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if (real(GEO)==5015 | real(GEO)==1621) & AARl==2013 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if (real(GEO)==5011 | real(GEO)==1612) & AARl==2017 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if (real(GEO)==5011 | real(GEO)==1612) & AARl==2012 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if (real(GEO)==5005 | real(GEO)==1703) & AARl==2013 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1931 & AARl==2015 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1913 & AARl==2016 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1805 & AARl==2013 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1805 & AARl==2019 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1524 & AARl==2016 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1504 & AARl==2013 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1263 & AARl==2016 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1243 & AARl==2015 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==1032 & AARl==2019 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==0821 & AARl==2014 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==0628 & AARl==2014 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==0220 & AARl==2014 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==0104 & AARl==2014 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# replace `TN'=0 if real(GEO)==0104 & AARl==2016 // Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.
# * Manuelt lagt inn (Jørgen 17.-24.1.2020)
# replace `TN'=0 if real(GEO)==1439 & AARl==2016 // Høst-undersøkelse. Kan ikke standardiseres når flyttet til 2016.
# replace `TN'=0 if real(GEO)==1401 & AARl==2016 // Blir for liten i 4602 etter sletting av 1439.
# replace `TN'=0 if (real(GEO)==1636 | real(GEO)==5023) & AARl==2016 // Høst-undersøkelse. Kan ikke standardiseres når flyttet til 2016.
# replace `TN'=0 if (real(GEO)==1638 | real(GEO)==5024) & AARl==2016 // Blir for liten i 5059 etter sletting av 1636.
# su AARl
# if `r(min)'==2014 {
# 	replace `TN'=0 if real(GEO)==1545 & AARl<=2015 // 1545 Midsund i 2013 blir eneste gyldige undersøkelse for 1506 Nye Molde i 2015 
# // for spørsmål som ble innført i 2014. årsak: 1543 Nesset i 2013 har ikke spørsmålet, 1502 Gamle Molde i 2015 annullert pga. 
# // høstundersøkelse. 
# }
# }
# 
# 
# 
# * Slette SOES-inndeling før 2016.
# ************************************
#   * Vi skal ikke ha med kommunetall etter SOES før kommunetallene kan sammenlignes
# *med treårig landstall etter SOES. Det første treårige landstallet med SOES er
# *2014-2016, iom. at SOES ble tatt inn i 2014. Det første året med kommunetall 
# *som kan sammenlignes med tre år med landstall etter SOES, er 2016 (sammenlignes
#                                                                     *med landstall for siste tre år: 2014-2016). 
# replace ANTALL=. if AARl<2016 & TAB2!="0" & TAB2!="NA" & TAB2!="98"  
# replace NEVNER=. if AARl<2016 & TAB2!="0" & TAB2!="NA" & TAB2!="98"  
# 
# 
# 
# * Sørge for at ikke den gamle Narvik-koden o.l. settes til xx99 (se begrunnelse
#                                                                  *øverst i skriptet).
# ****************************************************************************** 		
#   replace GEO="5055" if GEO=="5011" | GEO=="1612"
# replace GEO="5055" if GEO=="1571"
# replace GEO="5056" if GEO=="5013" | GEO=="1617"
# replace GEO="5059" if GEO=="5024" | GEO=="1638"
# replace GEO="5059" if GEO=="5023" | GEO=="1636"
# replace GEO="5059" if GEO=="5016" | GEO=="1622"
# replace GEO="1806" if GEO=="1805"
# replace GEO="1806" if GEO=="1854"
# replace GEO="1875" if GEO=="1849"
# 
# 
# * Sørge for at Klæbu, Rennesøy og Finnøy kommer med i bydelstallene for hhv. 
# *Trondheim og Stavanger, ikke bare i kommunetallet.
# ****************************************************************************** 		
#   preserve 
# levelsof GEOniv, local(nivaa) clean
# tempfile nyebydeler
# keep if GEO=="5030" | GEO=="1662" | GEO=="1141" | GEO=="1142"
# replace GEO="500104" if GEO=="5030" | GEO=="1662"
# replace GEO="110308" if GEO=="1141"
# replace GEO="110309" if GEO=="1142"
# if ustrregexm("`nivaa'","B") & !ustrregexm("`nivaa'","S") replace GEOniv="B"
# if ustrregexm("`nivaa'","S") replace GEOniv="S"
# save `nyebydeler', replace
# restore
# append using `nyebydeler'
# 
# 
# 
# pause F
# 
# 
# * Slette vNEVNER
# drop vNEVNER
# 
# * TOSTRING 
# tostring GEO, replace
# * RYDDING
# capture drop __0* //temp-variabelen
# 
# * UNIVERSELL KVALITETSKONTROLL AV SNUTTER (DEL 2/2)
# ****************************************************
#   *i. Sjekke at varlist i utdata = varlist i inndata
# order `varlist_inn'
# des, varlist
# assert "`r(varlist)'" == "`varlist_inn'"
# *ii. Sjekke at variabelTYPE i utdata = ditto i inndata
# local vartypeListUt="" // Skal ende opp med f.eks. "str num num str ..."
# foreach var of varlist _all {
# 	local vartype : type `var'
# if ustrregexm("`vartype'","str") local vartypeListUt=`"`vartypeListUt'"'+"str "
# else local vartypeListUt=`"`vartypeListUt'"'+"num "
# }
# assert `"`vartypeListUt'"'==`"`vartypeListInn'"'

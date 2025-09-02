/*	RSYNT1 for BEF_GKny: Rektangularisere bydeler før 2003

20.1.2022: REKTANGULARISERE BYDELER FØR 2003
I Rådataløypa sletter vi bydelstall før 2003 for de andre byene enn Oslo.
Oslobydeler bevares helt fra 1990, men andre bydeler har ikke rader for disse årene.
Problem: i LagKUBE tolkes dette feil, så tall for samtlige bydeler blir borte i prosesseringen.
FIX: Vi rektangulariserer på Bydelskode + AAR + KJONN, så alle kombinasjoner finnes.
Resten av inndelingene får bare én verdi lagt til. Da er Geonivået representert. 
(Dette blir under 700 nye rader. Komplett rektangularisering ville gi 34 mill rader ...)
Legger inn en _underkategori_ av dimensjonene, for total (0)-verdier slettes av Rsynt_PreFGlagring.
BEF (befolkningstallet) er aldri missing, så vi setter inn en null.

Senere modifisert:
  20.04.2022: SLETTE TOTALKATEGORIER FRA UTD, INNV og LANDBAK
Bakgrunn: Vi fikk lagt inn i Rådataløypa at Utd, Innv og Landbak aggregeres til 
total-kategorier (kode 0). Poenget var å unngå at LagKUBE standardiserer for disse
dimensjonene når en kube skal standardiseres.
Problem: Middelfolkemengdesnutten (Rsynt_PreFGlagring) i BEF_GKny registrerer at det er
total-kategorier for disse, og aggregerer dem. Det ser ut som dette blir feil, for 
kuben BEFOLK_GK som er basert på denne filgruppen kommer ut med firedoblet antall for siste år.
FIX: Vi sletter total-kategoriene igjen her, så Midbef-snutten ikke gjør noen aggregering.
OBS: Siste år har (i praksis) _bare_ UTDANN == 0, så akkurat den må bevares.

13.06.22: Styre totalkategorier (mod. fra ovenfor).
Sletter Totalkat. fra INNV og LANDBAK, men rører ikke UTDANN.
Det betyr at alle tre vars kommer ut med underkategorier, og UTDANN har i tillegg Total.
I R-scriptet som lager middelfolkemengder (Rsynt_Pre_FGlagring) omkodes Totalkat fra "0" til "888" før snutten
og tilbake til "0" etterpå. Da detekterer ikke snutten "0"-kat, så ingen aggregering skjer der.


Variabler i datasettet: (Alle er string)
GEO LEVEL (dvs. fylke kommune bydel) AAR ("1990") KJONN (1,2) ALDER ("32")
UTDANN LANDBAK INNVKAT BEF filgruppe delid tab1_innles

OBS VED GJENBRUK AV RSYNT'EN: 
	- Filgruppe og delID er hardkodet.
	- Sjekk også tab1_innles.
*/
*-----------------------------------
* Utvikling:
* use "O:/Prosjekt/FHP\PRODUKSJON\RUNTIMEDUMP\BEF_GKny_RSYNT1.dta", clear

*-----------------------------------
version 17
* SLETTE TOTALKATEGORIER FOR INNVKAT og LANDBAK
		/* Finne høyeste årstall: (levelsof tar LANG tid! Derfor dette, som er MYE raskere.)
		gen index = _n
		sort AAR
		local maxaar = AAR[_N]
		di `maxaar'
sort index
drop index
*/
  * Slette rader
drop if (INNVKAT == "0" | LANDBAK == "0" )
  *drop if (UTDANN == "0" & real(AAR) < `maxaar')

* REKTANGULARISERE BYDELER
preserve	//Mellomlagrer originalt datasett
	keep if LEVEL == "bydel"
	
	* Alle GEO må finnes i alle AAR, og ha begge KJONN. Tar med LEVEL, det er bare ett.
	* Resten av inndelingene mangler allerede rader, og det går fint. Så vi trenger 
	* bare én verdi der.
	fillin GEO LEVEL AAR KJONN
	replace ALDER       = "1" if _fillin == 1
	replace UTDANN      = "1" if _fillin == 1
	replace LANDBAK     = "1" if _fillin == 1
	replace INNVKAT     = "8" if _fillin == 1	//Vi har bare Uoppgitt i disse årene.
	replace BEF         = "0" if _fillin == 1
	replace filgruppe   = "BEF_GKny" if _fillin == 1
	replace delid       = "Raa_v1"   if _fillin == 1
	replace tab1_innles = "-" 		 if _fillin == 1
	
	drop _fillin	
	tempfile mellomlager
	save `mellomlager', replace
            restore
            
            * Tilbake i originaldatasettet:
              drop if LEVEL == "bydel"
            append using `mellomlager'

* Ferdig



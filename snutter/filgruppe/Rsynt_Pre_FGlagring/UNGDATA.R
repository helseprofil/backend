Filgruppe[GEO == "0217" & AARl == 2017, names(.SD) := 0, .SDcols = c("ANTALL", "NEVNER", "VEKT")] # Slette Oppegård-2017 om det er kommet med ved et uhell. 
Filgruppe[GEO == "1507" & AARl == 2023, let(GEO = "1508")] # La undersøkelsen for Ålesund + Haram i 2023 representere Ålesund

# Slette høst-data f.o.m 2016, sette missing soes til 0 (gammel bydelsfil)
Filgruppe[AARl >= 2016 & ALDERl %in% c(1,3,5), names(.SD) := 0, .SDcols = c("ANTALL", "NEVNER", "VEKT")]
Filgruppe[is.na(TAB2) | TAB2 == 98, let(TAB2 = 0)]
# Fjerne år hvor spørsmålet ikke var med (nevner = 0 for hele årgangen). Fjerner også evt dummy landstall (skal ikke lages lenger i rsynt1)
Filgruppe <- Filgruppe[, let(missing = mean(NEVNER, na.rm = T)), by = AARl][missing != 0 & !(as.numeric(GEO) == 0 & NEVNER == 0)][, let(missing = NULL)]
startaar <- collapse::fmin(Filgruppe$AARl)

# Lage vektet nevner
bycols <- c("GEOniv", "FYLKE", "GEO", "AARl", "AARh", "KJONN", "ALDERl", "ALDERh", "UTDANN", "INNVKAT", "LANDBAK")
Filgruppe[, let(vNEVNER = sum(VEKT, na.rm = T)), by = c(bycols, "TAB2")]

# Aggreger duplikatrader
g <- collapse::GRP(Filgruppe, c(bycols, "TAB1", "TAB2"))
sumvars <- c("ANTALL", "VEKT", grep(".a$", names(Filgruppe), value = T))
meanvars <- c("NEVNER", "vNEVNER", grep(".f$", names(Filgruppe), value = T))
Filgruppe <- collapse::add_vars(g[["groups"]],
                                collapse::fsum(collapse::get_vars(Filgruppe, sumvars), g = g),
                                collapse::fmean(collapse::get_vars(Filgruppe, meanvars), g = g))

# Lage samletall for soes
# Siden tallene i den gamle bydelsfilen i praksis er SOES = 0 må tallene aggregeres på nytt etter at SOES = 0 er sydd på.
soes0 <- Filgruppe[TAB2 != 0]

g <- collapse::GRP(soes0, c(bycols, "TAB1"))
sumvars <- c("ANTALL", "NEVNER", "vNEVNER", "VEKT", grep(".a$", names(soes0), value = T))
meanvars <- grep(".f$", names(soes0), value = T)
soes0 <- collapse::add_vars(g[["groups"]],
                                collapse::fsum(collapse::get_vars(soes0, sumvars), g = g),
                                collapse::fmean(collapse::get_vars(soes0, meanvars), g = g))
soes0[, let(TAB2 = 0)]

Filgruppe <- data.table::rbindlist(list(Filgruppe, soes0), use.names = T, fill = T)
g <- collapse::GRP(Filgruppe, c(bycols, "TAB1", "TAB2"))
Filgruppe <- collapse::add_vars(g[["groups"]],
                                collapse::fsum(collapse::get_vars(Filgruppe, sumvars), g = g),
                                collapse::fmean(collapse::get_vars(Filgruppe, meanvars), g = g))

# Aggregere til fylkes- og landstall basert på vektet antall og nevner.
# Kommunekodene geoharmoniseres for å få korrekte lands- og fylkestall
# For 2021 og 2022 lagres ettårige tall pga Covid19
Fylkeorg <- data.table::copy(Filgruppe)[GEOniv == "K"][, let(ANTALL = VEKT, NEVNER = vNEVNER)][, let(VEKT = NULL, vNEVNER= NULL)]
Fylkeorg <- khfunctions:::do_harmonize_geo(file = Fylkeorg, vals = list(), rectangularize = F, parameters = parameters)
sumvars <- c("ANTALL", "NEVNER", grep(".a$", names(Fylkeorg), value = T))
meanvars <- grep(".f$", names(Fylkeorg), value = T)

# Fylkestall frem til 2015 (med høstundersøkelser)
fylke2015 <- Fylkeorg[AARl <= 2015]

if(nrow(fylke2015) > 0){
  g <- collapse::GRP(fylke2015, c(setdiff(bycols, "GEO"), "TAB1", "TAB2"))
  fylke2015 <- collapse::add_vars(g[["groups"]],
                                  collapse::fsum(collapse::get_vars(fylke2015, sumvars), g = g),
                                  collapse::fmean(collapse::get_vars(fylke2015, meanvars), g = g))
  allperiods <- khfunctions:::find_periods(unique(fylke2015$AARh), period = 3)
  fylke2015 <- khfunctions:::extend_to_periods(fylke2015, allperiods)
  g <- collapse::GRP(fylke2015, c(setdiff(bycols, "GEO"), "TAB1", "TAB2"))
  fylke2015 <- collapse::add_vars(g[["groups"]],
                              collapse::fsum(collapse::get_vars(fylke2015, sumvars), g = g),
                              collapse::fmean(collapse::get_vars(fylke2015, meanvars), g = g))
  fylke2015[, let(AARl = AARh)] # Setter AARl = AARh slik at AAR 2014 inneholder 2012_2014 osv. 
} 

# Fylkestall fra 2016 (uten høstundersøkelser for 2014-15)
fylke2016 <- Fylkeorg[AARl >= 2014]
fylke2016[ALDERl %in% c(1,3,5), names(.SD) := 0, .SDcols = c("ANTALL", "NEVNER")]
g <- collapse::GRP(fylke2016, c(setdiff(bycols, "GEO"), "TAB1", "TAB2"))
fylke2016 <- collapse::add_vars(g[["groups"]],
                                collapse::fsum(collapse::get_vars(fylke2016, sumvars), g = g),
                                collapse::fmean(collapse::get_vars(fylke2016, meanvars), g = g))

Fylke2122 <- data.table::copy(fylke2016[AARl %in% c(2021, 2022)]) # Ettårige fylkestall for 2021 og 2022
fylke2016[AARl == 2021, names(.SD) := 0, .SDcols = c("ANTALL", "NEVNER")] # Disse skal ikke inngå i glidende summer pga Covid19. 2022 skal inngå i 2023-2024-tall. 
allperiods <- khfunctions:::find_periods(unique(fylke2016$AARh), period = 3)
fylke2016 <- khfunctions:::extend_to_periods(fylke2016, allperiods)
g <- collapse::GRP(fylke2016, c(setdiff(bycols, "GEO"), "TAB1", "TAB2"))
fylke2016 <- collapse::add_vars(g[["groups"]],
                            collapse::fsum(collapse::get_vars(fylke2016, sumvars), g = g),
                            collapse::fmean(collapse::get_vars(fylke2016, meanvars), g = g))
fylke2016[, let(AARl = AARh)] # Setter AARl = AARh slik at AAR 2014 inneholder 2012_2014 osv. 

Fylke <- data.table::rbindlist(list(fylke2015, fylke2016), fill = TRUE, use.names = TRUE)
# Legge til fylkestall for første to år, settes lik det tredje året.
# For 2021 og 2022 erstattes radene av de ettårige tallene lagret over.
missingaar <- startaar:(startaar+1)
tredjeaar <- startaar+2
for(aar in missingaar){
  new <- data.table::copy(Fylke[AARl == tredjeaar])[, names(.SD) := aar, .SDcols = c("AARl", "AARh")]
  Fylke <- data.table::rbindlist(list(Fylke, new), use.names = TRUE, fill = TRUE)
}
Fylke <- data.table::rbindlist(list(Fylke[!AARl %in% c(2021, 2022)], Fylke2122), use.names = TRUE, fill = TRUE)
Fylke[, let(GEO = FYLKE, GEOniv = "F")]

Land <- data.table::copy(Fylke)
Land[, let(GEO = "0", FYLKE = "00", GEOniv = "L")]

g <- collapse::GRP(Land, c(bycols, "TAB1", "TAB2"))
Land <- collapse::add_vars(g[["groups"]],
                            collapse::fsum(collapse::get_vars(Fylke, sumvars), g = g),
                            collapse::fmean(collapse::get_vars(Fylke, meanvars), g = g))

# Legge til fylkes- og landstall og filtrere bort år før startåret
Filgruppe <- data.table::rbindlist(list(Filgruppe, Fylke, Land), use.names = T, fill = T)[AARl >= startaar]
Filgruppe[, let(vNEVNER = NULL)]
# Gammel kommentar fra Jørgen: 
# [Aggregering til fylke og land skjer] før kommunesammenslåing av undersøkelser. Burde det ikke vært motsatt rekkefølge? :-()
# Dette burde nok vært gjort i motsatt rekkefølge.Nå vil en undersøkelse telle i fylkes- og landstall for ett år men gå inn i kommunetallet et annet år. 
       
# Håndtere sammenslåing av kommuner/undersøkelser (slik det var hardkodet i opprinnelig STATA-snutt)
# Manuelle endringer
aarcols <- c("AARl", "AARh")
valcols <- c("ANTALL", "NEVNER")
# Flytte Nedre Eiker og Svelvik fra 2017 til 2016 for å havne sammen med resten av Drammen
Filgruppe[GEO %in% c("0625", "0711") & AARl == 2017, (aarcols) := 2016]
# Sammenslåing i trøndelag i 2018
Filgruppe[GEO == "1718" & AARl == "2016", (valcols) := 0]
# Fjerne høstundersøkelser dersom startåret er 2014 (finnes bare 2014-15, utilstrekkelig for lands- og fylkestall)
if(startaar >= 2014) Filgruppe[ALDERl %in% c(1,3,5), (valcols) := 0]

# AUTOMATISK GENERERTE SLETTINGER OG FLYTTINGER FOR 2020-SAMMENSLåINGENE
# Slettinger: Fjerne småundersøkelser som er dublett eller utenfor 3årsvindu.
Filgruppe[AARl == 2012 & GEO %in% c("1260", "1259", "1256", "1018") |
          AARl == 2013 & GEO %in% c("0711", "0625") |
          AARl == 2014 & GEO %in% c("1854", "1534", "1529") |
          AARl == 2015 & GEO %in% c("1523", "0628", "0627") |
          AARl == 2016 & GEO %in% c("1551", "1545", "1241") |
          AARl == 2017 & GEO %in% c("5023", "1636", "0711", "0625") |
          AARl == 2018 & GEO %in% c("0226", "0136") |
          AARl == 2019 & GEO %in% c("1231", "0123"), (valcols) := 0]

# Flyttinger: Rekode AAR for godkjente små-undersøkelser.
Filgruppe[(AARl == 2012 & GEO %in% c("1231", "0226")), (aarcols) := 2013]
Filgruppe[(AARl == 2012 & GEO %in% c("1439", "0628")) | (AARl == 2013 & GEO %in% c("1027", "1018", "1017", "0716")), (aarcols) := 2014]
Filgruppe[(AARl == 2013 & GEO %in% c("1551", "1543")) | (AARl == 2014 & GEO %in% c("1545", "0217")), (aarcols) := 2015]
Filgruppe[(AARl == 2014 & GEO %in% c("5023", "1636")) | (AARl == 2015 & GEO %in% c("1439", "0227", "0226")), (aarcols) := 2016]
Filgruppe[(AARl == 2016 & GEO %in% c("1231")), (aarcols) := 2017]
Filgruppe[(AARl == 2017 & GEO %in% c("1543", "1439")), (aarcols) := 2018]
Filgruppe[(AARl == 2017 & GEO %in% c("1260", "1259", "1256", "1245")) | (AARl == 2018 & GEO %in% c("0227")), (aarcols) := 2019]

# Slettinger: Fjerning av sammenslåtte undersøkelse som dekker mindre enn 85 % av ny kommune.

Filgruppe[AARl == 2012 & GEO %in% c("5024", "1638", "5011", "1612") |
          AARl == 2013 & GEO %in% c("1805", "5005", "1703", "5018", "1630", "5015", "1621", "1504") |
          AARl == 2014 & GEO %in% c("0821", "0628", "0220", "0104") |
          AARl == 2015 & GEO %in% c("1931", "1243") |
          AARl == 2016 & GEO %in% c("1913", "1524", "1263", "0104", "1439", "1401", "1636", "5023", "1638", "5024") |
          AARl == 2017 & GEO %in% c("5018", "1630", "5011", "1612") |
          AARl == 2019 & GEO %in% c("1805", "1032"), (valcols) := 0]

# 1545 Midsund i 2013 blir eneste gyldige undersøkelse for 1506 Nye Molde i 2015 for spørsmål som ble innført i 2014. 
# årsak: 1543 Nesset i 2013 har ikke spørsmålet, 1502 Gamle Molde i 2015 annullert pga. høstundersøkelse. 
if(startaar == 2014) Filgruppe[GEO == 1545 & AARl <= 2015, (valcols) := 0]

# Slette SOES-inndeling før 2016.
# Vi skal ikke ha med kommunetall etter SOES før kommunetallene kan sammenlignes
# med treårig landstall etter SOES. Det første treårige landstallet med SOES er
# 2014-2016, iom. at SOES ble tatt inn i 2014. Det første året med kommunetall 
# som kan sammenlignes med tre år med landstall etter SOES, er 2016 (sammenlignes *med landstall for siste tre år: 2014-2016). 
# Dette løser samtidig problemet med at sammenslåing av undersøkelser med og 
# uten SOES (etter flytting av en undersøkelse *uten* SOES til et år der alle undersøkelser er *med* SOES).  
Filgruppe[AARl < 2016 & TAB2 != 0, (valcols) := NA]

# Sørge for at ikke den gamle Narvik-koden o.l. settes til xx99 (se begrunnelse i kommentarer nederst).
Filgruppe[GEO %in% c("5011", "1612", "1571"), let(GEO = "5055")]
Filgruppe[GEO %in% c("5013", "1617"), let(GEO = "5056")]
Filgruppe[GEO %in% c("5024", "1638", "5023", "1636", "5016", "1622"), let(GEO = "5059")]
Filgruppe[GEO %in% c("1805", "1854"), let(GEO = "1806")]
Filgruppe[GEO == "1849", let(GEO = "1875")]

# Sørge for at Klæbu, Rennesøy og Finnøy kommer med i bydelstall

new_bydel <- Filgruppe[GEO %in% c("5030", "1662", "1141", "1142")][, let(GEOniv = "B")]
new_bydel[GEO %in% c("5030", "1662"), let(GEO = "500104")]
new_bydel[GEO == "1141", let(GEO = "110308")]
new_bydel[GEO == "1142", let(GEO = "110309")]
Filgruppe <- data.table::rbindlist(list(Filgruppe, new_bydel), fill = T)
data.table::setkeyv(Filgruppe, c(bycols, "TAB1", "TAB2"))

Filgruppe[, names(.SD) := lapply(.SD, as.character)]

# Gamle kommentarer
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

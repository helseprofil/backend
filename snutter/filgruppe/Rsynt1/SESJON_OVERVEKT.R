# Legge til rette for oppdatering av sesjon-overvekt data, som skal via orgdata. 


# /*
#   Ver. 2020: Årstall for sesjon ligger ikke lenger i filnavn, men i filen, TESK_KODE
# Ver. 2021: Årstall for sesjon ligger i en ny dato-variabel, men på formatet "antall 
# 		   dager siden 01/01/1900". Variabelen brukes ikke så vi plundrer ikke med 
# det. Dropper bare å lese den inn. Gjelder årgang 2021 og utover.
# 
# <STATA>
#   ******************************************************************************/
#   /*
#   Rsynt1_YYYY_Sesjon.do
# Hardkodet GEO: Nei. 
# Testet for robusthet mot implisitte nuller: Ja.
# */
#   
#   *version 14
# capture rename Kommunenr Bostedskommunenr
# replace KJONN="M" if KJONN=="Mann"
# replace KJONN="K" if KJONN=="Kvinne"
# keep ALDER KJONN Bostedskommunenr  HOYDE Vekt 
# replace ALDER=substr(ALDER,1,2)
# destring ALDER HOYDE Vekt, replace force
# * KMI
# su HOYDE
# assert `r(mean)'>150 & `r(mean)'<200 //verifisere at HOYDE er i cm
# su Vekt
# assert `r(mean)'>50 & `r(mean)'<100 //verifisere at Vekt er i kg
# capture drop KMI //det er feil i utregningene på noen individer
# gen KMI=Vekt/((HOYDE/100)^2)
# * VASK
# replace KMI=. if KMI<10 | KMI>100 //Jonas' opprinnelig kode
# * WHO CUT-OFF VERDIER. Kilde: Establishing a standard definition for child 
# *overweight and obesity worldwide: international survey. BMJ2000; 320 doi: 
#   *http://dx.doi.org/10.1136/bmj.320.7244.1240(Published 06 May 2000) 
# *Jonas' kommentar: Disse er på halvt-års nivå, mens ALDERsvariablen i  
#   *vernepliktsdataene er hele år. Jeg har derfor gitt cutoff-verdien for de som  
#   *er 18.5 til alle som er er 18, verdien for 17.5 til alle som er 17 osv.
# gen fedmeWHOcutoff=.
# replace fedmeWHOcutoff = 27.98 if ALDER == 14 & KJONN=="M"
# replace fedmeWHOcutoff = 28.6 if ALDER == 15 & KJONN=="M"
# replace fedmeWHOcutoff = 29.14 if ALDER == 16 & KJONN=="M"
# replace fedmeWHOcutoff = 28.70 if ALDER == 17 & KJONN=="M"
# replace fedmeWHOcutoff = 30 if ALDER> 17 & KJONN=="M"
# replace fedmeWHOcutoff = 28.87 if ALDER == 14 & KJONN=="K"
# replace fedmeWHOcutoff = 29.29 if ALDER == 15 & KJONN=="K"
# replace fedmeWHOcutoff = 29.56 if ALDER == 16 & KJONN=="K"
# replace fedmeWHOcutoff = 29.84 if ALDER == 17 & KJONN=="K"
# replace fedmeWHOcutoff = 30 if ALDER> 17 & KJONN=="K"
# gen WHOfedme = (KMI>=fedmeWHOcutoff) if KMI<.
# gen overvWHOcutoff=.
# replace overvWHOcutoff = 22.96 if ALDER == 14 & KJONN=="M"
# replace overvWHOcutoff = 23.60 if ALDER == 15 & KJONN=="M"
# replace overvWHOcutoff = 24.19 if ALDER == 16 & KJONN=="M"
# replace overvWHOcutoff = 24.73 if ALDER == 17 & KJONN=="M"
# replace overvWHOcutoff = 25 if ALDER> 17 & KJONN=="M"
# replace overvWHOcutoff = 23.66 if ALDER == 14 & KJONN=="K"
# replace overvWHOcutoff = 24.17 if ALDER == 15 & KJONN=="K"
# replace overvWHOcutoff = 24.54 if ALDER == 16 & KJONN=="K"
# replace overvWHOcutoff = 24.85 if ALDER == 17 & KJONN=="K"
# replace overvWHOcutoff = 25 if ALDER> 17 & KJONN=="K"
# gen WHOoverv = (KMI>=overvWHOcutoff) if KMI<.
# gen WHOikkeOverv = 1 if WHOoverv == 0 // trenger denne til nevneren
# gen WHOpreFedme=WHOoverv-WHOfedme
# * Reshape
# tempvar id 
# gen `id'=_n
# reshape long WHO, string i(`id') j(kategori) //NB hvert individ har 4 linjer
# rename WHO teller
# * Aggregere
# collapse (sum) teller, by(Bostedskommune KJONN ALDER kategori)
# * Nevner
# tempvar tmpN
# gen `tmpN' = 0 //NB <nevner> skal bare være = 1 på én av t individs 3 linjer
#                             replace `tmpN' = teller if kategori=="overv" | kategori=="ikkeOverv"
# egen nevner = total(`tmpN'), by(Bostedskommune KJONN ALDER)
# *Tilretelegge for eksport til R. NB; utelukkende stringvariabler i Rsynt1!!
#   tostring _all, replace force
# capture drop __0* //temp-variabelen  
# order Bostedskommune KJONN ALDER kategori

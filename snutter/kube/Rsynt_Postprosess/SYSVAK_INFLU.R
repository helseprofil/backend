# # Rsynt postprosess SYSVAK_INFLU
# 
# 
# 
# 
# * MODIFISERE EKSISTERENDE POSTPRO-SCRIPT TIL RSYNT:
#   * SYSVAK INFLUENSA - SLETTE BYDELSTALL for 2017 (nov-2017).
# * Slette alle bydeler UNNTATT Oslo for 2020 (nov-2020, oppdaget feil ifm Folkereg)
# * -Ditto 2021
# 
# /*	Disse tallene slettes fordi datakvaliteten ikke er god nok. 
# De kan dermed merkes "manglende data" (og ikke Anonymisert).
# Det er SPVflagg == 1
# 
# Nov-2020: Tilrettelegge for INCLUDE.
# */
#   /*-------------------------------------------------------------------------------
#   
#   *local datakatalog "O:/Prosjekt/FHP/PRODUKSJON\PRODUKTER\KUBER\KOMMUNEHELSA\KH2017NESSTAR"
# local datakatalog "O:/Prosjekt/FHP/PRODUKSJON\RUNTIMEDUMP"
# 
# * Innfiler:
#   local Sysvakfil "Sysvak_Influ-nov-20"	
# 
# *local targetkatalog: TRENGS IKKE i en Rsynt.
# 
# pause on
# use `datakatalog'/`Sysvakfil',clear
# 
# *------------------------------------------------------------------------------*/
# /*
# KOMMENTERE UT ALT SOM IKKE SKAL KJØRES.
# Hele scriptfilen hentes inn med INCLUDE.
# 
# *** OBS: KAN IKKE BRUKE "///" for å skjøte programlinjer, det virker ikke i Statas batchmodus.
# *** Må bruke /*   */  rundt linjeskifttegnet i stedet (sist på første linje og først på siste linje).
# 
# ************************************************/
# * Slette bydeler i TRD for 2017
# local Trondh_geo = "5001"		// (Was: fant om TRL var 16 eller 50. Derfor Local her.)
# 
# replace TELLER =. if substr(GEO, 1,4)=="`Trondh_geo'" & GEOniv=="B" & AAR=="2017_2017"
# replace RATE   =. if substr(GEO, 1,4)=="`Trondh_geo'" & GEOniv=="B" & AAR=="2017_2017"
# replace SMR    =. if substr(GEO, 1,4)=="`Trondh_geo'" & GEOniv=="B" & AAR=="2017_2017"
# replace MEIS   =. if substr(GEO, 1,4)=="`Trondh_geo'" & GEOniv=="B" & AAR=="2017_2017"
# * Sette SPVflagg til 1 "manglende data" dvs ".."
# replace TELLER_f =1 if substr(GEO, 1,4)=="`Trondh_geo'" & GEOniv=="B" & AAR=="2017_2017"
# replace RATE_f   =1 if substr(GEO, 1,4)=="`Trondh_geo'" & GEOniv=="B" & AAR=="2017_2017"
# 
# * Slette alle bydeler UNNTATT Oslo for 2020 og 2021
# local geouttrykk = `"inlist(substr(GEO, 1,4), "1103", "4601", "5001")"'
# 
# replace TELLER =. if `geouttrykk' & GEOniv=="B" & inlist(AAR, "2020_2020", "2021_2021")
# replace RATE   =. if `geouttrykk' & GEOniv=="B" & inlist(AAR, "2020_2020", "2021_2021")
# replace SMR    =. if `geouttrykk' & GEOniv=="B" & inlist(AAR, "2020_2020", "2021_2021")
# replace MEIS   =. if `geouttrykk' & GEOniv=="B" & inlist(AAR, "2020_2020", "2021_2021")
# * Sette SPVflagg til 1 "manglende data" dvs ".."
# replace TELLER_f =1 if `geouttrykk' & GEOniv=="B" & inlist(AAR, "2020_2020", "2021_2021")
# replace RATE_f   =1 if `geouttrykk' & GEOniv=="B" & inlist(AAR, "2020_2020", "2021_2021")
# 
# * Ferdig
# 

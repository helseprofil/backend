# /* Rsynt_Postprosess ENEFHIB
# 
# For 2015 og senere: SPVflagg er blitt feil for Stavangerbydelene: De er aktivt slettet i systemet, 
# pga. at tallene er inndelt etter TK-nummer som ikke lar seg mappe til bydeler. 
# Dermed er tallene flagget 3="anonymisert" ist.f. 1="missing". Det rettes opp her. 
# 2020: Finnøy og Rennesøy bydeler har brukbare kommunetall, som bevares. Flagging justert accordingly.
# 
# FOR 2020:
#   Kommunekode Stavanger hardkodet.
# 22.11.2019 filtrert så flagg ikke endres hvis det er 0. Da er det tall i raden.
# 
# 06.01.2023: Skjule tall for 1151 Utsira i siste periode (2019-2021). Tallene er "imputert" for å 
# få laget fylkestall, men vi vil ikke vise det imputerte tallet utad.
# 27.02.2023: Jeg bare satte ..._f =3 for Utsira, og antok at løypa da setter måltallene til missing. 
# Det ser ut som det ble feil - måltall var prikket i kuben, MEN IKKE I FRISKVIKFILA, og ble dermed vist i profilene!
#   Lagt inn eksplisitt sletting av alle måltall som skal vises ut - MEN BEVARER sumTELLER og sumNEVNER for QC-formål.
# 
# */ 
#   /*	FOR UTVIKLING:
#   use "O:/Prosjekt/FHP\PRODUKSJON\RUNTIMEDUMP\ENEFHIB_Rsynt_postpro.dta", clear
# */
#   ******************************************************************************/
#   *   ..._f==9 blir til SPVflagg==1.
# replace TELLER_f 	=9 if int(real(GEO)/100) == 1103 & TELLER_f > 0	//Bydeler i Stavanger der tall mangler
# replace RATE_f 		=9 if int(real(GEO)/100) == 1103 & TELLER_f > 0
# * SMR har ikke flagg
# 
# ****************
#   replace TELLER_f	=3 if real(GEO) == 1151 & AAR == "2019_2021"
# replace RATE_f		=3 if real(GEO) == 1151 & AAR == "2019_2021"
# 
# foreach maltall in TELLER NEVNER RATE MALTALL SMR MEIS {
#   replace `maltall' =. if real(GEO) == 1151 & AAR == "2019_2021"
# }
# 

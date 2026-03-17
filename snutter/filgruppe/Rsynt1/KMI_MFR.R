# /*	RSYNT1 for KMI_MFR_GK: Lage et par delsummer for grupper av KMI-kategori. 
# 
# Endringer:
#   - 12.01.2022. Tilpasse til ny ORGfil laget i Rådataløypa (nye variabelnavn, og at vi nå har KJONN="2").
# Tilpasse scriptet til å brukes med INCLUDE. (stbj)
# include "O:/Prosjekt/FHP\PRODUKSJON\BIN\Z_Statasnutter\Rsynt1_KMI_MFR_GK.do"
# */
#   version 14
# 
# /*******************************************************************
#   *KODE SOM KUN ER MED I TESTFASEN  (Jørgen)
# pause on
# set more off
# clear
# *Translate
# unicode encoding set latin1
# cd "O:/Prosjekt/FHP/PRODUKSJON\RUNTIMEDUMP"
# unicode translate KMI_MFR_GK_1111_RSYNT1post.dta
# use "KMI_MFR_GK_1111_RSYNT1post.dta", clear
# local tabulate_testfase = "tab KMI_FOER_KAT_3"
# *******************************************************************/
#   
#   
#   `tabulate_testfase'
# *count
# *describe	
# *tab KJONN
# tempfile mellomlager
# destring ATOTALT AEMFR_V10, replace force
# /*
# 	gen kommune=substr(MORS_BOSTED,1,4)
# 	preserve
# 		keep if kommune=="0301" | kommune=="1103" | kommune=="1201" | kommune=="1601"
# 		save `mellomlager', replace
# restore
# codebook MORS_BOSTED_KOMMUNE_GRUNNKR_HI
# drop if kommune=="0301" | kommune=="1103" | kommune=="1201" | kommune=="1601"
# collapse (sum) ATOTALT AEMFR_V10, by(FODSELSTIDSPUNKT MORS_ALDER_K7 KMI_FOER_KAT_3 kommune)
# rename kommune MORS_BOSTED_KOMMUNE_GRUNNKR_HI
# append using `mellomlager'
# 	count
# */
# fillin AAR KMI_FOER_KAT_3 GEO ALDER
# replace ATOTALT = 0 if ATOTALT == . & _fillin == 1
# replace AEMFR_V10 = 0 if AEMFR_V10 == . & _fillin == 1
# replace KJONN = "2" if KJONN == ""
# save `mellomlager', replace
# collapse (sum) ATOTALT AEMFR_V10, by(AAR GEO ALDER)
# gen KMI_FOER_KAT_3 = "sum1239"
# gen KJONN = "2"
# append using `mellomlager'
# save `mellomlager', replace
# `tabulate_testfase'
# keep if KMI_FOER_KAT_3 == "1" | KMI_FOER_KAT_3 == "2" | KMI_FOER_KAT_3 == "3"
# collapse (sum) ATOTALT AEMFR_V10, by(AAR GEO ALDER)
# gen KMI_FOER_KAT_3 ="sum123"
# gen KJONN = "2"
# append using `mellomlager'
# `tabulate_testfase'
# capture drop __*
# capture drop xxx
# capture drop _fillin
# *tab KJONN, missing
# tostring _all, replace force
# ******************************************************************************
# 

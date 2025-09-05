# <STATA>
#   **********************************************************/
#   /*
# GEO: Sårbart for nye kommune- eller bydelskoder for Stavanger og Trondheim.
# Navn på Stata do-fil denne snutten er hentet fra: Rsynt_Pre_FGlagring_enefhim ...    
# Skriptet er GEO2020-ready. Mye GEO i avsnittet om sammenslåinger, men skal bare
# håndtere gamle kommunenummer i gamle årganger (uten omkoding til nye), så trolig OK. 
# */
#   * UNIVERSELL KVALITETSKONTROLL AV SNUTTER (DEL 1/2)
# ****************************************************
#   *i. Lagre varlist i inndata (sjekkes mot ditto i utdata nederst i snutten)
# qui des, varlist
# local varlist_inn "`r(varlist)'"
# *ii. Lagre variabelTYPEne i inndata (for sjekking mot ditto i utdata)
# local vartypeListInn="" // Skal ende opp med f.eks. "str num num str ..."
# foreach var of varlist _all {
#   local vartype : type `var'
# 	if regexm("`vartype'","str") local vartypeListInn=`"`vartypeListInn'"'+"str "
#   else local vartypeListInn=`"`vartypeListInn'"'+"num "
# }
# 
# 
# * Sørge for at Klæbu, Rennesøy og Finnøy kommer med i bydelstallene for hhv. 
# *Trondheim og Stavanger, ikke bare i kommunetallet.
# ****************************************************************************** 		
#   
# replace GEO="500104" if GEO=="503000" | GEO=="166200"
# replace GEO="110308" if GEO=="114100"
# replace GEO="110309" if GEO=="114200"
# 
# preserve 
# levelsof GEOniv, local(nivaa) clean
# tempfile nyebydeler
# keep if GEO=="5030" | GEO=="1662" | GEO=="1141" | GEO=="1142"
# replace GEO="500104" if GEO=="5030" | GEO=="1662"
# replace GEO="110308" if GEO=="1141"
# replace GEO="110309" if GEO=="1142"
# replace GEOniv="B"
# save `nyebydeler', replace
# restore
# append using `nyebydeler'
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
# if regexm("`vartype'","str") local vartypeListUt=`"`vartypeListUt'"'+"str "
# else local vartypeListUt=`"`vartypeListUt'"'+"num "
# }
# assert `"`vartypeListUt'"'==`"`vartypeListInn'"'
# Rsynt_Pre_FGlagring SYSVAK og SYSVAK_INFLU
# GEO: Sårbart for nye kommune- eller bydelskoder for Stavanger og Trondheim.
#  Sørge for at Klæbu, Rennesøy og Finnøy kommer med i bydelstallene for hhv. Trondheim og Stavanger, ikke bare i kommunetallet.

new_bydel <- Filgruppe[GEO %in% c("5030", "1662", "1141", "1142")][, let(GEOniv = "B")]
new_bydel[GEO %in% c("5030", "1662"), let(GEO = "500104")]
new_bydel[GEO == "1141", let(GEO = "110308")]
new_bydel[GEO == "1142", let(GEO = "110309")]
Filgruppe <- data.table::rbindlist(list(Filgruppe, new_bydel), fill = T)

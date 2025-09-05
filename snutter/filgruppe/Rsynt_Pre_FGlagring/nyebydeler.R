# Rsynt_Pre_FGlagring for å sikre at Klæbu, Rennesøy og Finnøy kommer med i bydelstallene for hhv. Trondheim og Stavanger, ikke bare i kommunetallet.
# GEO: Sårbart for nye kommune- eller bydelskoder for Stavanger og Trondheim.

Filgruppe[GEO %in% c("503000", "166200"), let(GEO = "500104")]
Filgruppe[GEO == "114100", let(GEO = "110308")]
Filgruppe[GEO == "114200", let(GEO = "110309")]

new_bydel <- Filgruppe[GEO %in% c("5030", "1662", "1141", "1142")][, let(GEOniv = "B")]
new_bydel[GEO %in% c("5030", "1662"), let(GEO = "500104")]
new_bydel[GEO == "1141", let(GEO = "110308")]
new_bydel[GEO == "1142", let(GEO = "110309")]
Filgruppe <- data.table::rbindlist(list(Filgruppe, new_bydel), fill = T)

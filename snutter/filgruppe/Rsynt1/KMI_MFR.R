# Rektangulariserer filen og lager summer for KMI_FOER_KAT_3 = 123 og 1239

vals <- list()
for(dim in c("GEO", "AAR", "ALDER", "KMI_FOER_KAT_3")){
  vals[[dim]] <- unique(DF[, .SD, .SDcols = dim])
}

lev <- unique(DF[, .SD, .SDcols = c("GEO", "LEVEL")])

rect <- do.call(khfunctions:::expand.grid.dt, vals)
DF[, let(exist = 1)]
DF <- collapse::join(rect, DF, multiple = T, overid = 2, verbose = 0)
DF[is.na(exist), let(ATOTALT = 0, AEMFR_V10 = 0)][, let(exist = NULL)]
DF[is.na(KJONN), let(KJONN = 2)]

valcols <- c("AEMFR_V10", "ATOTALT")
bycols <- c("GEO", "AAR", "ALDER")
DF[, names(.SD) := lapply(.SD, as.integer), .SDcols = valcols]

# Aggreger verdikolonnene for å lage totalene sum123 og  sum1239
g1239 <- collapse::GRP(DF, bycols)
agg1239 <- collapse::add_vars(g1239[["groups"]], collapse::fsum(collapse::get_vars(DF, valcols), g = g1239))
agg1239[, let(KMI_FOER_KAT_3 = "sum1239", KJONN = 2)]

g123 <- collapse::GRP(DF[KMI_FOER_KAT_3 != 9], bycols)
agg123 <- collapse::add_vars(g123[["groups"]], collapse::fsum(collapse::get_vars(DF[KMI_FOER_KAT_3 != 9], valcols), g = g123))
agg123[, let(KMI_FOER_KAT_3 = "sum123", KJONN = 2)]

keepcols <- intersect(names(DF), names(agg123))

DF <- data.table::rbindlist(list(DF[, ..keepcols], 
                                 agg123[, ..keepcols], 
                                 agg1239[, ..keepcols]), 
                            use.names = T, fill = T)

DF <- collapse::join(DF, lev, on = "GEO", how = "l", multiple = T, overid = 2, verbose = 0)

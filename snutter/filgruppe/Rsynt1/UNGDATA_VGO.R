# Rsynt 1 for innlesing av vanlige ungdataindikatorer
# Bydelstall fra 2015 og kommunetall fra 2010

tab1 <- filedescription$TAB1
minaar <- collapse::fmin(unique(DF$AAR))
if(minaar > 2014) minaar <- 2014 # rektangulariser minst tilbake til 2014
maxaar <- collapse::fmax(unique(DF$AAR))
if(is.numeric(DF[[tab1]])) DF <- DF[x < 98, env = list(x = tab1)]
DF[is.na(SOES), let(SOES = 99)]
keepcols <- c(tab1, "GEO", "AAR", "KJONN", "ALDER", "SOES")
DF <- DF[, .SD, .SDcols = keepcols]
allgeos <- unique(DF$GEO)
DF <- DF[!is.na(ALDER) & !is.na(KJONN)]
DF[, let(teller = 1)]
# DF[is.na(vekt2020), let(vekt2020 = 1)]

dims <- c(tab1, "GEO", "AAR", "KJONN", "ALDER", "SOES")
g <- collapse::GRP(DF, dims)
DF <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(DF, "teller"), g = g))
DF[, let(exist = 1)]

full <- list()
full[["GEO"]] <- data.table::data.table(GEO = allgeos)
full[["ALDER"]] <- data.table::data.table(ALDER = c(4,5,6))
full[["AAR"]] <- data.table::data.table(AAR = minaar:maxaar)
for(dim in setdiff(dims, c("GEO", "ALDER", "AAR"))){
  full[[dim]] <- unique(DF[, .SD, .SDcols = dim])
}  

full <- do.call(khfunctions:::expand.grid.dt, full)
data.table::setcolorder(full, c("GEO", "AAR", "KJONN", tab1, "ALDER", "SOES"))
DF <- collapse::join(full, DF, multiple = T, overid = 2, verbose = 0)
DF[is.na(exist), let(teller = 0)][, let(exist = NULL)]

# Lag nevner som sum(teller) i hvert strata og gjør alt til tekst
DF[, let(nevner = collapse::fsum(teller)), by = setdiff(dims, tab1)]
DF[, names(.SD) := lapply(.SD, as.character)]

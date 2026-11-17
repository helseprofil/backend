# Rsynt 1 for innlesing av vanlige ungdataindikatorer
# Bydelstall fra 2015 og kommunetall fra 2010

tab1 <- filedescription$TAB1
tab2 <- filedescription$TAB2
tab3 <- filedescription$TAB3

tab13 <- c(tab1, tab3)
tab13 <- tab13[which(tab13 != "-" & !is.na(tab13))]

keepcols <- intersect(c(tab13, "GEO", "AAR", "KJONN", "ALDER", "SOES"), names(DF))
DF <- DF[, .SD, .SDcols = keepcols]
khtools::msg("-- koder XX00 (ukjente kommuner) om til XX99")
# Fra 2026 er små kommuner med N < 50 slått sammen til "ukjent kommune i fylket". Disse kommer inn med XX00-kode (XX = fylkeskoden)
# For å håndteres korrekt hos oss må disse kodes om til XX99 slik at de plasseres i riktig fylke ved aggregering
DF[grepl("00$", GEO), GEO := sub("00$", "99", GEO)]

DF[, names(.SD) := lapply(.SD, as.numeric), .SDcols = setdiff(keepcols, c("Kommune", tab13))]

minaar <- collapse::fmin(unique(DF$AAR))
# if(minaar > 2014) minaar <- 2014 # rektangulariser minst tilbake til 2014
maxaar <- collapse::fmax(unique(DF$AAR))

for(tab in tab13){
  x <- DF[[tab]]
  x_num <- suppressWarnings(as.numeric(x))
  if(all(is.na(x) | !is.na(x_num))) {
    idx_keep <- which(x_num < 98)
    DF <- DF[idx_keep]
  }
}

DF[is.na(SOES), let(SOES = 99)]

allgeos <- collapse::funique(DF$GEO)
DF <- DF[!is.na(ALDER) & !is.na(KJONN)]
DF[, let(teller = 1)]

dims <- c(tab13, "GEO", "AAR", "KJONN", "ALDER", "SOES")
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
data.table::setcolorder(full, c("GEO", "AAR", "KJONN", "ALDER", "SOES", tab13))
DF <- collapse::join(full, DF, multiple = T, overid = 2, verbose = 0)
DF[is.na(exist), let(teller = 0)][, let(exist = NULL)]

# Lag nevner som sum(teller) i hvert strata og gjør alt til tekst
DF[, let(nevner = collapse::fsum(teller)), by = setdiff(dims, tab1)]
DF[, names(.SD) := lapply(.SD, as.character)]

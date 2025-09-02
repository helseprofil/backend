# Rektangulariser filen på alle dimensjoner
# Sett teller = 1/0 
# Omdøp Kommunenr til Bostedskommunenr om den finnes
# Kast ubrukte kolonner

DF[, let(filgruppe = filedescription$FILGRUPPE, delid = filedescription$DELID, tab1_innles = filedescription$TAB1)]
DF[, let(ALDER = sub("(\\d{2}).*", "\\1", ALDER), teller = 1)]
data.table::setnames(DF, "Kommunenr", "Bostedskommunenr", skip_absent = T)
tabcol <- unique(DF$tab1_innles)
dims <- c("Bostedskommunenr", "KJONN", "ALDER", tabcol)
if("TESK_KODE" %in% names(DF)) dims <- c(dims, "TESK_KODE")

vals <- list()
for(dim in dims){
  vals[[dim]] <- unique(DF[, .SD, .SDcols = dim])
}

rect <- do.call(expand.grid.dt, vals)
DF <- collapse::join(rect, DF, multiple = T, overid = 2, verbose = 0)
DF[is.na(teller), let(teller = 0)]
delcols <- setdiff(names(DF), c(dims, "teller"))
DF[, (delcols) := NULL]

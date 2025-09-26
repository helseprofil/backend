# Rektangulariser filen på alle dimensjoner
# Sett teller = 1/0 
# Omdøp Kommunenr til Bostedskommunenr om den finnes
# Kast ubrukte kolonner

DF[, let(ALDER = sub("(\\d{2}).*", "\\1", ALDER), teller = 1)]
data.table::setnames(DF, "Kommunenr", "Bostedskommunenr", skip_absent = T)
tabcol <- unique(DF$tab1_innles) # Kan bruke filedescription$TAB1, men do_special_handling må også kunne ta med filedescription før dette kan brukes
dims <- c("Bostedskommunenr", "KJONN", "ALDER", tabcol)
if("TESK_KODE" %in% names(DF)) dims <- c(dims, "TESK_KODE")

vals <- list()
for(dim in dims){
  vals[[dim]] <- unique(DF[, .SD, .SDcols = dim])
}

rect <- do.call(khfunctions:::expand.grid.dt, vals)
DF <- collapse::join(rect, DF, multiple = T, overid = 2, verbose = 0)
DF[is.na(teller), let(teller = 0)]
delcols <- setdiff(names(DF), c(dims, "teller"))
DF[, (delcols) := NULL]

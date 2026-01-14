# RSYNT_POSTPROSESS for kube TRANGBODDHET
# Oppdatert juni 2025 (VL)

# Sletter tall på bydelsnivå dersom
# - > 5 %-poeng forskjell mellom ukjent sumTELLER og sumNEVNER for BODD == "trangt"
# - > 8% ukjent sumTELLER
# - > 10% har BODD == "uoppgitt" (sletter BODD == "trangt")

cat("\n\nSTARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\n**** Sletter bydelsdata med >8% ukjent sumTELLER eller >5%-poeng forskjell i ukjent sumTELLER/sumNEVNER")
keepcols <- c("GEO","AAR","ALDER","UTDANN","LANDBAK","INNVKAT","BODD","sumTELLER","sumNEVNER")
deletestrata <- data.table::copy(KUBE)[BODD == "trangt" & (GEOniv == "B" | GEO %in% c("0301", "1103", "4601", "5001")), .SD, .SDcols = keepcols]

deletestrata[, let(GEONIV = "BYDEL", GEOKODE = character())]
deletestrata[nchar(GEO) == 4, GEONIV := "KOMMUNE"]
deletestrata[, GEOKODE := sub("^(\\d{4}).*", "\\1", GEO)]
deletebydel <- unique(deletestrata[GEONIV == "BYDEL", .SD, .SDcols = c("GEO", "GEOKODE")])

bycols <- c("GEOKODE", "GEONIV", "AAR", "ALDER", "UTDANN", "LANDBAK", "INNVKAT", "BODD")
deletestrata[, MISSING := sum(is.na(sumTELLER)), by = bycols]
deletestrata <- deletestrata[MISSING == 0]
deletestrata <- deletestrata[, lapply(.SD, sum, na.rm = T), .SDcols = c("sumTELLER", "sumNEVNER"), by = bycols]

deletestrata <- data.table::melt(deletestrata, measure.vars = c("sumTELLER", "sumNEVNER"), variable.name = "MALTALL", value.name = "VALUE")
deletestrata <- data.table::dcast(deletestrata, ... ~ GEONIV, value.var = "VALUE")
deletestrata[, UKJENT := 1 - (BYDEL/KOMMUNE)]

deletestrata <- data.table::dcast(deletestrata, GEOKODE + AAR + ALDER + UTDANN + LANDBAK + INNVKAT + BODD ~ MALTALL, value.var = "UKJENT")
deletestrata[, DIFF := sumTELLER - sumNEVNER]

bydims <- c("GEOKODE", "AAR", "ALDER", "UTDANN", "INNVKAT")
deletestrata <- deletestrata[sumTELLER > 0.08 | (DIFF > 0.05 | DIFF < -0.05)][, .SD, .SDcols = bydims]
delete <- collapse::join(deletestrata, deletebydel, on = "GEOKODE", multiple = TRUE, verbose = FALSE, overid = 2)
delete[, let(GEOKODE = NULL, SLETT = 1)]
bydims <- sub("GEOKODE", "GEO", bydims)
delete <- delete[, .SD, .SDcols = c(bydims, "SLETT")]
KUBE <- collapse::join(KUBE, delete, on = bydims, overid = 2, verbose = 0)
KUBE[spv_tmp == 0 & SLETT == 1, c("TELLER.f", "RATE.f", "spv_tmp") := 1]
KUBE[, SLETT := NULL]

cat("\n****Sletter tall for BODD=='trangt' for strata med > 10% BODD=='uoppgitt'")
delete <- KUBE[BODD == "uoppgitt" & sumTELLER/sumNEVNER > 0.10 & GEOniv %in% c("B", "K"), .SD, .SDcols = bydims]
delete[, let(BODD = "trangt", SLETT = 1)]
KUBE <- collapse::join(KUBE, delete, on = c(bydims, "BODD"), overid = 2, verbose = FALSE)
KUBE[spv_tmp == 0 & SLETT == 1, c("TELLER.f", "RATE.f", "spv_tmp") := 1]
KUBE[, SLETT := NULL]

# januar 2026: 
# Etter utvidelse med utdann blir det tilfeller hvor UTDANN 1 og 4 får tall, men ikke de andre. 
# For å unngå forvirring fjerner vi alle undergrupper av UTDANN dersom minst to av disse er prikket. 
if(length(unique(KUBE$UTDANN)) > 1){
  cat("\n**** Sletter tall for undergrupper av UTDANN dersom minst 2 underkategorier er prikket i et strata")
  bydims <- c(setdiff(bydims, "UTDANN"), "BODD")
  KUBE[UTDANN != 0, n_prikk := sum(spv_tmp > 0), by = bydims]
  KUBE[n_prikk >= 2 & UTDANN != 0 & spv_tmp == 0, c("TELLER.f", "RATE.f", "spv_tmp") := 1]
  KUBE[, n_prikk := NULL]
}

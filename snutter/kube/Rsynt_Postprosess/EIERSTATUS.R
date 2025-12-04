# Snutt som sletter bydelstall dersom dekningen er for dårlig
# Kriterier
# >= 10% ukjent for sumTELLER
# >= 5%-poeng forskjell mellom ukjent sumTELLER og sumNEVNER

cat("\n\n* STARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\n** Sletter bydelstall med > 10% ukjent bydel for sumTELLER eller > 5%-poeng forskjell i ukjent bydel på sumNEVNER - sumTELLER")

bydeler <- KUBE[GEOniv == "B", unique(GEO)]
bydelskommuner <- unique(sub("(\\d{4})\\d{2}", "\\1", bydeler))
ukjentstrata <- data.table::copy(KUBE[GEO %in% c(bydeler, bydelskommuner), .SD, .SDcols = c("GEOniv", parameters$outdimensions, "sumTELLER", "sumNEVNER")])
ukjentstrata[, KOMMUNE := sub("(^\\d{4}).*", "\\1", GEO)]
slettbydel <- data.table::copy(ukjentstrata[GEOniv == "B", .SD, .SDcols = c("GEO", "KOMMUNE")])

# Finn komplette strata
bycols <- c("KOMMUNE", setdiff(parameters$outdimensions, "GEO"))
ukjentstrata <- ukjentstrata[, if (sum(is.na(sumTELLER)) == 0) .SD, by = bycols]
ukjentstrata <- data.table::melt(ukjentstrata, measure.vars = c("sumTELLER", "sumNEVNER"), variable.name = "MALTALL", value.name = "VALUE")
ukjentstrata <- ukjentstrata[, .(VALUE = sum(VALUE)), by = c(bycols, "GEOniv", "MALTALL")]
ukjentstrata <- data.table::dcast(ukjentstrata, ... ~ GEOniv, value.var = "VALUE")
ukjentstrata[, UKJENT := 1-(B/K)][, let(B = NULL, K = NULL)]
ukjentstrata <- data.table::dcast(ukjentstrata, ... ~ MALTALL, value.var = "UKJENT")
ukjentstrata[, DIFF := sumTELLER - sumNEVNER]

ukjentstrata <- ukjentstrata[sumTELLER > 0.10 | abs(DIFF) > 0.05, .SD, .SDcols = setdiff(names(ukjentstrata), c("sumTELLER", "sumNEVNER", "DIFF"))]

delete <- unique(collapse::join(slettbydel, ukjentstrata, on = "KOMMUNE", multiple = TRUE)[, let(KOMMUNE = NULL, SLETT = 1)])
KUBE[delete, on = intersect(names(KUBE), names(delete)), SLETT := i.SLETT]
cat("\n** Prikker", KUBE[SLETT == 1, .N], "rader")
KUBE[spv_tmp == 0 & SLETT == 1, let(spv_tmp = 1, TELLER.f = 1, RATE.f = 1)][, SLETT := NULL]

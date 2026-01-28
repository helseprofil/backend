# RSYNT_POSTPROSESS for kube NEET
# Skrevet av: VL Januar 2023

# Sletter tall på bydelsnivå der forskjellen i uoppgitt bydel for sumTELLER og sumNEVNER overskrider 5 %-poeng

# Finn geokoder for bydeler og relevante kommuner
# Bare inkluder bydelskoder fra de fire kommunene

cat("\n\nSTARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\nIdentifiserer relevante GEO-koder\n")
geo_k <- c("0301", "1103", "4601", "5001")
deletestrata <- KUBE[(GEO %in% geo_k | GEOniv == "B") & !grepl("99$", GEO) & !GEO %in% c( "030116", "030117"), 
                     .(GEOniv, GEO,AAR,KJONN,ALDER,UTDANN,LANDBAK,INNVKAT,sumTELLER,sumNEVNER)]

# Opprette .GEONIV og .GEOKODE
deletestrata[, let(KOMMUNE = sub("(^\\d{4}).*", "\\1", GEO))][, GEO := NULL]
# .deletestrata[, `:=` (.GEONIV = ".BYDEL",
#                       .GEOKODE = character())]
# .deletestrata[nchar(GEO) == 4, .GEONIV := ".KOMMUNE"]

# .deletestrata[grep("^0301", GEO), .GEOKODE := "^0301"]
# .deletestrata[grep("^1103", GEO), .GEOKODE := "^1103"]
# .deletestrata[grep("^4601", GEO), .GEOKODE := "^4601"]
# .deletestrata[grep("^5001", GEO), .GEOKODE := "^5001"]

# Identifiser og filtrer ut komplette strata
## Prikking er ikke et problem da sumTELLER ikke er prikket med unntak av for 99-koder og bydeler i Tromso (5401..)
bycols <- c("GEOniv", "KOMMUNE", "AAR", "KJONN", "ALDER", "UTDANN", "LANDBAK", "INNVKAT")

cat("\nFinner komplette strata og finner total sumTELLER og sumNEVNER \n")
deletestrata <- deletestrata[, MISSING := sum(is.na(sumTELLER)), by = bycols][MISSING == 0]
cat("\nOmstrukturerer tabell og beregner andelen ukjent bydel\n")
g <- collapse::GRP(deletestrata, bycols)
deletestrata <- collapse::add_vars(g[["groups"]], 
                                   collapse::fsum(collapse::get_vars(deletestrata, c("sumTELLER", "sumNEVNER")), g = g))
# Omstrukturer tabell, vis sum for Kommune og Bydel
deletestrata <- data.table::melt(deletestrata, measure.vars = c("sumTELLER", "sumNEVNER"), variable.name = "MALTALL", value.name = "VALUE")
deletestrata <- data.table::dcast(deletestrata, ... ~ GEOniv, value.var = "VALUE")
deletestrata[, UKJENT := 1 - (B/K)]

cat("\nOmstrukturerer og beregner diff ukjent sumTELLER og sumNEVNER\n")
deletestrata <- data.table::dcast(deletestrata, KOMMUNE + AAR + KJONN + ALDER + INNVKAT ~ MALTALL, value.var = "UKJENT")
deletestrata[, DIFF := sumTELLER - sumNEVNER]

# Filtrer ut strata hvor ukjent bydel sumTELLER > 8 % eller differansen er > 5 %-poeng
cat("\nFiltrerer ut rader med > 8 % ukjent sumTELLER eller > 5 %-poeng diff\n")
deletestrata <- deletestrata[sumTELLER > 0.08 | abs(DIFF) > 0.05, .(KOMMUNE, AAR, KJONN, ALDER, INNVKAT)]
cat("\nBydelstall for", deletestrata[, .N], "strata slettes\n")

deletestrata[, SLETT := 1]
# Loop gjennom identifiserte strata, slett bydelstall.
KUBE[GEOniv == "B", KOMMUNE := sub("(^\\d{4}).*", "\\1", GEO)]
KUBE <- collapse::join(KUBE, deletestrata, multiple = "T", on = c("KOMMUNE", "AAR", "KJONN", "ALDER", "INNVKAT"), overid = 2, verbose = F)
cat("\nSletter", KUBE[spv_tmp == 0 & SLETT == 1, .N], "rader hvor bydel har > 8% ukjent sumTELLER eller > 5%-poeng absolutt diff mellom ukjent sumTELLER og sumNEVNER")

flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp")
KUBE[spv_tmp == 0 & SLETT == 1, (flags) := 1]
KUBE[, SLETT := NULL]

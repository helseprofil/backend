# RSYNT_POSTPROSESS for kube NEET
# Skrevet av: VL Januar 2023

# Sletter tall på bydelsnivå der forskjellen i uoppgitt bydel for sumTELLER og sumNEVNER overskrider 5 %-poeng

# Finn geokoder for bydeler og relevante kommuner
# Bare inkluder bydelskoder fra de fire kommunene

cat("\n\nSTARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\nIdentifiserer relevante GEO-koder\n")

kommunegeo <- c("0301", "1103", "4601", "5001")
bydelsgeo <- grep(paste(paste0("^", kommunegeo), collapse = "|"), unique(KUBE[GEOniv == "B", GEO]), value = TRUE)
bydelsgeo <- bydelsgeo[!bydelsgeo %in% c(grep("99$", bydelsgeo, value = TRUE), # ukjent bydel m? ut f?r beregning
                                         "030116", "030117")] # Skal ikke vises ut, tas derfor ut av beregningen
cat("\nKommuner:\n")
paste(kommunegeo, collapse = ", ")
cat("\nBydeler:\n")
paste(bydelsgeo, collapse = ", ")

# Lag subset av KUBE med relevante geokoder og BODD == trangt, lag KOMMUNE og GEONIV-kolonner
cat("\nOppretter deletestrata\n")
.deletestrata <- copy(KUBE)
.deletestrata <- .deletestrata[GEO %in% c(kommunegeo, bydelsgeo), 
                               .(GEO,AAR,KJONN,ALDER,UTDANN,LANDBAK,INNVKAT,sumTELLER,sumNEVNER)]

# Opprette .GEONIV og .GEOKODE
.deletestrata[, `:=` (.GEONIV = ".BYDEL",
                      .GEOKODE = character())]
.deletestrata[nchar(GEO) == 4, .GEONIV := ".KOMMUNE"]

.deletestrata[grep("^0301", GEO), .GEOKODE := "^0301"]
.deletestrata[grep("^1103", GEO), .GEOKODE := "^1103"]
.deletestrata[grep("^4601", GEO), .GEOKODE := "^4601"]
.deletestrata[grep("^5001", GEO), .GEOKODE := "^5001"]

# Identifiser og filtrer ut komplette strata
## Prikking er ikke et problem da sumTELLER ikke er prikket med unntak av for 99-koder og bydeler i Tromso (5401..)
bycols <- c(".GEOKODE", ".GEONIV", "AAR", "KJONN", "ALDER", "UTDANN", "LANDBAK", "INNVKAT")

cat("\nFinner komplette strata og finner total sumTELLER og sumNEVNER \n")
.deletestrata[, MISSING := sum(is.na(sumTELLER)), by = bycols]
.deletestrata <- .deletestrata[MISSING == 0]
.deletestrata <- .deletestrata[, lapply(.SD, sum, na.rm = T), .SDcols = c("sumTELLER", "sumNEVNER"), by = bycols]

# Omstrukturer tabell, vis sum for Kommune og Bydel
cat("\nOmstrukturerer tabell og beregner andelen ukjent bydel\n")
.deletestrata <- melt(.deletestrata, measure.vars = c("sumTELLER", "sumNEVNER"), variable.name = "MALTALL", value.name = ".VALUE")
.deletestrata <- dcast(.deletestrata, ... ~ .GEONIV, value.var = ".VALUE")
.deletestrata[, .UKJENT := 1 - (.BYDEL / .KOMMUNE)]

cat("\nOmstrukturerer og beregner diff ukjent sumTELLER og sumNEVNER\n")
.deletestrata <- dcast(.deletestrata, .GEOKODE + AAR + KJONN + ALDER + INNVKAT ~ MALTALL, value.var = ".UKJENT")
.deletestrata[, .DIFF := sumTELLER - sumNEVNER]

# Filtrer ut strata hvor ukjent bydel sumTELLER > 8 % eller differansen er > 5 %-poeng
cat("\nFiltrerer ut rader med > 8 % ukjent sumTELLER eller > 5 %-poeng diff\n")
.deletestrata <- .deletestrata[sumTELLER > 0.08 | (.DIFF > 0.05 | .DIFF < -0.05)]
deletedbydel <<- copy(.deletestrata)
.deletestrata <- .deletestrata[, .(.GEOKODE, AAR, KJONN, ALDER, INNVKAT)]
cat("\nBydelstall for f?lgende strata slettes\n")
cat("Se objektet `deletedbydel` i environment for oversikt over andel missing sumTELLER, sumNEVNER og diff\n")
print(.deletestrata)

# Loop gjennom identifiserte strata, slett bydelstall.

cat("\nSletter bydelsdata med > 8% ukjent bydel sumTELLER > 5%-poeng absolutt diff mellom ukjent bydel sumTELLER og sumNEVNER")

for (i in 1:nrow(.deletestrata)) {
  KUBE[GEOniv == "B" & 
         grepl(.deletestrata[[".GEOKODE"]][i], GEO) & 
         AAR == .deletestrata[["AAR"]][i] & 
         KJONN == .deletestrata[["KJONN"]][i] &
         ALDER == .deletestrata[["ALDER"]][i] &
         INNVKAT == .deletestrata[["INNVKAT"]][i],
       `:=`  (TELLER = NA_real_,
              RATE = NA_real_,
              SMR = NA_real_,
              MEIS = NA_real_,
              RATE.n = NA_real_,
              sumTELLER = NA_real_,
              sumNEVNER = NA_real_,
              TELLER.f = 1,
              RATE.f = 1)]
}

# Remove unneedet objects
rm(.deletestrata)
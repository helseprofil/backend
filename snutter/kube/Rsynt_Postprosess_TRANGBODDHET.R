# RSYNT_POSTPROSESS for kube TRANGBODDHET
# Skrevet av: VL desember 2022

# Sletter tall p√• bydelsniv√• der forskjellen i uoppgitt bydel for sumTELLER og sumNEVNER overskrider 5 %-poeng for BODD == "trangt"
# Diff > 5 %-poeng for BODD == "trangt" vil medf√∏re sletting av alle tall for dette strataet, ogs√• BODD == "uoppgitt"

# Finn geokoder for bydeler og relevante kommuner
# Bare inkluder bydelskoder fra de fire kommunene

cat("\n\nSTARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\nIdentifiserer relevante GEO-koder\n")

kommunegeo <- c("0301", "1103", "4601", "5001")
bydelsgeo <- grep(paste(paste0("^", kommunegeo), collapse = "|"), unique(KUBE[GEOniv == "B", GEO]), value = TRUE)
bydelsgeo <- bydelsgeo[!bydelsgeo %in% c(grep("99$", bydelsgeo, value = TRUE), # ukjent bydel mÂ ut f¯r beregning
                                         "030116", "030117")] # Skal ikke vises ut, tas derfor ut av beregningen
cat("\nKommuner:\n")
print(kommunegeo)
cat("\nBydeler:\n")
print(bydelsgeo)

# Lag subset av KUBE med relevante geokoder og BODD == trangt, lag KOMMUNE og GEONIV-kolonner
cat("\nOppretter deletestrata\n")
.deletestrata <- copy(KUBE)
.deletestrata <- .deletestrata[BODD == "trangt" & GEO %in% c(kommunegeo, bydelsgeo), 
               .(GEO,AAR,ALDER,UTDANN,LANDBAK,INNVKAT,BODD,sumTELLER,sumNEVNER)]

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
bycols <- c(".GEOKODE", ".GEONIV", "AAR", "ALDER", "UTDANN", "LANDBAK", "INNVKAT", "BODD")

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
.deletestrata <- dcast(.deletestrata, .GEOKODE + AAR + ALDER + UTDANN + LANDBAK + INNVKAT + BODD ~ MALTALL, value.var = ".UKJENT")
.deletestrata[, .DIFF := sumTELLER - sumNEVNER]

# Filtrer ut strata hvor ukjent bydel sumTELLER > 8 % eller differansen er > 5 %-poeng
cat("\nFiltrerer ut rader med > 8 % ukjent sumTELLER eller > 5 %-poeng diff\n")
.deletestrata <- .deletestrata[sumTELLER > 0.08 | (.DIFF > 0.05 | .DIFF < -0.05)]
.deletestrata <- .deletestrata[, .(.GEOKODE, AAR, ALDER)]
cat("\nBydelstall for f¯lgende strata slettes\n")
print(.deletestrata)

# Loop gjennom identifiserte strata, slett bydelstall. Sletter tall for b√•de BODD == "trangt" og "uoppgitt"

cat("\nSletter bydelsdata med for stor diff mellom ukjent sumTELLER og sumNEVNER")

for (i in 1:nrow(.deletestrata)) {
   KUBE[GEO %in% bydelsgeo & 
       grepl(.deletestrata[[".GEOKODE"]][i], GEO) & 
       AAR == .deletestrata[["AAR"]][i] & 
       ALDER == .deletestrata[["ALDER"]][i],
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

# Hent Steinar sitt STATA-skript
cat("\n\nSTARTER RSYNT_POSTPROSESS, STATA-SNUTT: Rsynt_Postprosess_TRANGBODDHET_v2.do\n")

# Finner STATA-fil
sfile <- paste(globs[["path"]], "BIN/Z_Statasnutter/Rsynt_Postprosess_TRANGBODDHET_v2.do", sep = "/")
synt <- paste0('include "', sfile, '"')

RES <- KjorStataSkript(KUBE, script = synt, tableTYP = "DT", batchdate = batchdate, globs = globs)

if (RES$feil != "") {
  stop("Noe gikk galt i kj¯ring av STATA \n", RES$feil)
}

KUBE <- RES$TABLE

rm(RES)
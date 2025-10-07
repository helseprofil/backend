
# Slette totalkategorier for INNVKAT og LANDBAK
DF <- DF[LANDBAK != "0" & INNVKAT != "0"]

# Rektangulariser bydeler
dt_bydel <- DF[LEVEL == "bydel"][, newrow := 0]

# Lag alle kombinasjoner av GEO, LEVEL, AAR og KJONN
kombinasjoner <- data.table::CJ(
  GEO = unique(dt_bydel$GEO),
  LEVEL = "bydel",
  AAR = unique(dt_bydel$AAR),
  KJONN = unique(dt_bydel$KJONN),
  unique = TRUE
)

dt_bydel <- collapse::join(kombinasjoner, dt_bydel, how = "l", on = c("GEO", "LEVEL", "AAR", "KJONN"), multiple = T, verbose = F)
# Fyll inn manglende verdier
dt_bydel[is.na(newrow), let(ALDER = "1",
                            UTDANN = "1",
                            LANDBAK = "1",
                            INNVKAT = "8",
                            BEF = "0",
                            filgruppe = "BEF_GKny",
                            delid = "Raa_v1",
                            tab1_innles = "-",
                            newrow = 1)]
dt_bydel <- dt_bydel[newrow == 1][, newrow := NULL]
DF <- data.table::rbindlist(list(DF, dt_bydel), use.names = TRUE, fill = TRUE)

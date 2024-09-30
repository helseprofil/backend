# RSYNT_PRE_FGLAGRING for Filgruppe: HKR
# Sist redigert av: VL 13. Oktober 2022
# Opprettet fordi: Indirekte standardisering til tre?rsperiode, fors?ker ? lure khfunctions ved ? kj?re en tre?rig fil som om den var ett?rig

# Lage data.table objekt
Filgruppe <- setDT(Filgruppe)

# Rektangulariserer filgruppen for aa faa alle unike verdier av dimensjoner og AARl

                          # FORSØK PÅ FORENKLING
                          # joincols <- c("GEO", "ALDERl", "AARl", "KJONN", "UTDANN", "LANDBAK", "INNVKAT", "TAB1")
                          # 
                          # ALLDIMS2 <- Filgruppe[, c("AARl", dimensions), with = F]
                          # m <- ALLDIMS2[, do.call(CJ, c(.SD, unique = T)), .SDcols = c(dimensions)]
                          # ALLDIMS2 <- ALLDIMS2[m, on = c(dimensions)]
                          # 
                          # ALLDIMS3 <- Filgruppe[, .(joincols), with = F)][
                          #   CJ(c(joincols, unique = T), on = joincols]
                          # ALLDIMS2[CJ(c(dimensions), unique = T), on = c(dimensions)]
                          # 
                          # 
                          # [, do.call(CJ(c(dimensions, unique = T)), on=c(dimensions)]
                          # ]
                          # ALLDIMS <- ALLDIMS[(CJ(c("AARl", dimensions, unique = T)), .SDcols = c("AARl", dimensions), on = c(dimensions)]
                          # 
                          # 
                          # [
                          #   CJ(c(AARl, GEO, ALDERl, ALDERh, KJONN, UTDANN, INNVKAT, LANDBAK, TAB1), unique = T), 
                          #   on = dimensions, with = F]
                          # ALLDIMS <- unique(Filgruppe[, .(ALDERl, ALDERh, KOBLID)])[ALLDIMS, on = .(ALDERl)]
                          # ALLDIMS <- unique(Filgruppe[, .(AARl, AARh)])[ALLDIMS, on = .(AARl)]
                          # ALLDIMS <- unique(Filgruppe[, .(GEO, FYLKE, GEOniv)])[ALLDIMS, on = .(GEO)]

# Lage alle kombinasjoner av dimensjoner og AARl i Filgruppen
# merge inn ALDERh og KOBLID basert p? ALDERl
# merge inn AARh basert p? AARl
# merge inn FYLKE og GEOniv basert p? GEO

ALLDIMS <- Filgruppe[, .(GEO, AARl, ALDERl, KJONN, UTDANN, LANDBAK, INNVKAT, TAB1)][
  CJ(GEO, AARl, ALDERl, KJONN, UTDANN, LANDBAK, INNVKAT, TAB1, unique = T), 
  on = .(GEO, AARl, ALDERl, KJONN, UTDANN, LANDBAK, INNVKAT, TAB1)]
ALLDIMS <- unique(Filgruppe[, .(ALDERl, ALDERh, KOBLID)])[ALLDIMS, on = .(ALDERl)]
ALLDIMS <- unique(Filgruppe[, .(AARl, AARh)])[ALLDIMS, on = .(AARl)]
ALLDIMS <- unique(Filgruppe[, .(GEO, FYLKE, GEOniv)])[ALLDIMS, on = .(GEO)]

# Merge inn resterende kolonner
# Sette eksplisitt ANTOBS = 0, ANTOBS.a = 1, ANTOBS.f = 0

Filgruppe <- merge(Filgruppe, ALLDIMS, all.y = T)
Filgruppe[is.na(ANTOBS), `:=`
     (ANTOBS = 0,
      ANTOBS.a = 1,
      ANTOBS.f = 0)]

# Organiserer Filgruppen for rullende summer
# Lager liste over dimensjoner for å lage strata
# Oppretter rullende 3-aars sum av ANTOBS (innevaerende + to paafoelgende aar), innad i hvert strata

setkeyv(Filgruppe, c("GEO", "ALDERl", "ALDERh", "KJONN", "UTDANN", "INNVKAT", "LANDBAK", "TAB1", "AARl"))
dimensions <- c("GEO", "ALDERl", "ALDERh", "KJONN", "UTDANN", "INNVKAT", "LANDBAK", "TAB1")

Filgruppe[, ANTOBS := frollsum(ANTOBS, 3, align = "left"), by = c(dimensions)]

# Dersom VAL2 finnes i Filgruppen (nevnerkolonne), settes det explisitte 0 også her 
# før det lages flerårige summer også av denne
if("VAL2" %in% names(Filgruppe)){
  Filgruppe[is.na(VAL2), VAL2 := 0]
  Filgruppe[, VAL2 := frollsum(VAL2, 3, align = "left"), by = c(dimensions)]
}

# Fjerner to siste rader som ikke inngaar i komplett aargang (ANTOBS = NA). Her vil VAL2 også være = NA.
# Setter AARh = AARl + 2, og ANTOBS.a = 3

Filgruppe <- Filgruppe[!is.na(ANTOBS)]
Filgruppe[, `:=` 
     (AARh = AARl + 2,
      ANTOBS.a = 3)]

# NOTATER
# ROW er uendret, og derfor NA for alle nye rader. harmloest?
# Rectangularizing FG KUHR (not used, but may be useful later)

# # Rectanguralize FG
# Filgruppe[, `:=` (tempAAR = paste(AARl, AARh, sep = "_"),
#                   tempALDER = paste(ALDERl, ALDERh, sep = "_"))]
# 
# # Generate all strata
# .dims <- c("GEOniv", "tempAAR", "tempALDER", "KJONN", "UTDANN", "LANDBAK", "INNVKAT", "TAB1", "GEO")
# rect <- do.call(CJ, lapply(.dims, function(x) unique(Filgruppe[[x]])))
# rect <- setNames(rect, .dims)
# 
# # Add AARl, AARh, ALDERl, ALDERh, FYLKE, KOBLID, ROW
# rect <- collapse::join(rect, Filgruppe[, .(tempALDER, tempAAR, AARl, AARh, ALDERl, ALDERh)], 
#                        on  = c("tempALDER", "tempAAR"), how = "left")
# rect <- collapse::join(rect, Filgruppe[, .(GEO, FYLKE)], 
#                        on = "GEO", how = "left")
# rect[, `:=` (KOBLID = NA_integer_,
#              ROW = 1L:nrow(rect))]
# 
# # Merge value columns ANTOBS, ANTOBS.f, and ANTOBS.a
# joincols2 <- c("ANTOBS", "ANTOBS.f", "ANTOBS.a")
# rect <- collapse::join(rect, Filgruppe[, mget(c(.dims, joincols2))], 
#                        on = .dims, how = "left", multiple = T)
# 
# # Set explicit 0, exept for old GEO corresponding to AAlesund/Haram in 2020-2023
# rect[!complete.cases(ANTOBS, ANTOBS.a, ANTOBS.f) & !(AARl %in% c(2020, 2021, 2022, 2023) & GEO %in% oldcodes), 
#      `:=` (ANTOBS = 0,
#            ANTOBS.f = 0,
#            ANTOBS.a = 1)]
# 
# # Delete rows for year 2020-2023 and old GEO corresponding to AAlesund/Haram
# # rect <- rect[!(AARl %in% c(2020, 2021, 2022, 2023) & GEO %in% oldcodes)]
# 
# # Cleanup and replace Filgruppe with rectangularized file
# setcolorder(rect, names(Filgruppe))
# rect[, grep("temp", names(rect)) := NULL]
# 
# Filgruppe <- copy(rect)
# rm(rect)
# gc()

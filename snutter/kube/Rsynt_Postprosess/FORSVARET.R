# RSYNT_POSTPROSESS for kube FORSVARET_TRENING, FORSVARET_SVOMMING, and SESJON_1
# Author: Vegard Lysne
# Updated: 2026.01.16

# Delete data for AAlesund/Haram for years between 2018  and 2020, as they are in large part provided as 15079999, and not the correct gk-codes. 
flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp", "manuellprikket")
problemaar <- 2018:2020
idx <- KUBE[GEO %in% c("1508", "1580") & (AARl %in% problemaar | AARh %in% problemaar), which = TRUE]
data.table::set(KUBE, i = idx, j = flags, value = 1L)

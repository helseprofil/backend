# RSYNT_POSTPROSESS for kube FORSVARET_TRENING, FORSVARET_SVOMMING, and SESJON_1
# Author: Vegard Lysne
# Updated: 2026.01.16

# Delete data for AAlesund/Haram for years between 2018  and 2023, as they are in large part provided as 1507 which is invalid and coded to 1599. 

KUBE[GEO %in% c("1508", "1580") & ((AARl >= 2018 & AARh <= 2023) | (AARl < 2018 & AARh >= 2018) | (AARl <= 2023 & AARh > 2023)),
     let(RATE.f = 1,TELLER.f = 1, spv_tmp = 1)]

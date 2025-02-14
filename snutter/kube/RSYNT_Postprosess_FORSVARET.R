# RSYNT_POSTPROSESS for kube FORSVARET_TRENING, FORSVARET_SVOMMING, and SESJON_1
# Author: Vegard Lysne
# Updated: 2024.02.07

# Delete data for AAlesund/Haram for years between 2018  and 2023, as they are in large part provided as 1507 which is invalid and coded to 1599. 

KUBE[GEO %in% c("1508", "1580") & ((AARl >= 2018 & AARh <= 2023) | (AARl < 2018 & AARh > 2018) | (AARl < 2023 & AARh > 2023)),
     let(RATE = NA_real_,
         SMR = NA_real_,
         MEIS = NA_real_,
         RATE.f = 1,
         TELLER.f = 1)]

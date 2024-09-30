# RSYNT_POSTPROSESS for kube FORSVARET_TRENING, FORSVARET_SVOMMING, and SESJON_1
# Author: Vegard Lysne
# Updated: 2024.02.07

# Delete data for AAlesund/Haram for years prior to 2020, as they are in large part provided as 1507 which is invalid from 2024 and coded to 1599. 

KUBE[GEO %in% c("1508", "1580") &
    as.numeric(substr(AAR, 6, 9)) < 2020,
    `:=` (RATE = NA_real_,
          SMR = NA_real_,
          MEIS = NA_real_,
          RATE.f = 1,
          TELLER.f = 1)]

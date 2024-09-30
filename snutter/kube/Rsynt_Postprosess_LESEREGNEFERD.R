# RSYNT_POSTPROSESS for kube LESE og REGNEFERD. 
# Author: Vegard Lysne
# Updated: 2024.02.12

## Slette AAR == "2021_2022" pga brudd i tidslinjen

KUBE[AARl == 2021 & AARh == 2022,
     `:=` (RATE = NA_real_,
           MEIS = NA_real_,
           RATE.f = 1,
           TELLER.f = 1)]
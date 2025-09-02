# RSYNT_POSTPROSESS for kube KUHR
# Author: Vegard Lysne
# Updated: 2024.02.01

# Most bydel in Stavanger should have SPVFLAGG = 1
KUBE[nchar(GEO) > 4 & 
       grepl("^1103", GEO) & 
       !GEO %in% c("110308", "110309") & 
       TELLER.f > 0, 
     `:=` 
     (TELLER.f = 9,
       RATE.f = 9)]

# Delete bydels for 2023, due to too much unknown
KUBE[AAR == "2020_2022" & 
       nchar(GEO) > 4, 
     `:=` 
     (RATE = NA_real_,
       SMR = NA_real_,
       MEIS = NA_real_,
       TELLER.f = 1,
       RATE.f = 1)]

# Delete all numbers for Aalesund (1508) and Haram (1580) for periods including years 2020-2023.
# In this period, these data are provided using the common GEO-code 1507 valid before splitting up.

KUBE[GEO %in% c("1508", "1580") & !(AARl < 2020 & AARh < 2020 |AARl > 2023 & AARh > 2023),
     `:=`
     (RATE = NA_real_,
     SMR = NA_real_,
     MEIS = NA_real_,
     TELLER.f = 1,
     RATE.f = 1)]
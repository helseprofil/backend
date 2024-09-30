# RSYNT_POSTPROSESS for kube MOBBING_0 and TRIVSEL_3
# Author: Vegard Lysne
# Updated: 2024.02.23

# Remove 3-year data for AAlesund and Haram for periods 2019_2021 and 2021_2023,
# as they contain data on only one year (2019 and 2023).

KUBE[GEO %in% c("1508", "1580") & AAR %in% c("2019_2021", "2021_2023"),
     let(RATE.f = 1)]
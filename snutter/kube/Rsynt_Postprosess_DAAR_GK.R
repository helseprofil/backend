# RSYNT_POSTPROSESS for kube DAAR_GK
# Author: VL November 2023

# Some rows get RATE, but not SMR/MEIS do to sumPREDTELLER == 0

# Find rows with data on RATE but not SMR/MEIS, and no flags (TELLER, NEVNER, RATE).
# Set RATE = NA and RATE.f = 1
KUBE[!is.na(RATE) & is.na(SMR) & is.na(MEIS) & TELLER.f == 0 & RATE.f == 0 & NEVNER.f == 0,
     `:=` (RATE = NA_real_,
           RATE.f = 1)]

# Reduce number of 10-year periods to 17, due to limited space in NESSTAR
KUBE <- KUBE[AARl > max(AARl, na.rm = TRUE) - 16]
# RSYNT_POSTPROSESS for kube DAAR_GK
# Author: VL November 2023

# Some rows get RATE, but not SMR/MEIS do to sumPREDTELLER == 0
# Find rows with data on RATE but not SMR/MEIS, and no flags (TELLER, NEVNER, RATE).
# Set RATE = NA and RATE.f = 1
flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp", "manuellprikket")

idx <- KUBE[!is.na(RATE) & is.na(SMR) & is.na(MEIS) & spv_tmp == 0, which = TRUE]
data.table::set(KUBE, i = idx, j = flags, value = 1L)

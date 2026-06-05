# RSYNT_POSTPROSESS for kube UFORE
# Sist redigert av: VL desember 2025

# Flagger perioder før 2011_2013, da første år med tall er 2011
# Setter SPV-flagg til 1 (dvs ".." manglende data)
# Uavhengig av eksisterende flagg
flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp", "manuellprikket")
KUBE[AARl < 2011, (flags) := 1L]
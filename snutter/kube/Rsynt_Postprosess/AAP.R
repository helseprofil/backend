# RSYNT_POSTPROSESS for kube UFORE
# Sist redigert av: VL desember 2025

# Flagger perioder før 2011_2013, da første år med tall er 2011
# Setter SPV-flagg til 1 (dvs ".." manglende data)

KUBE[AARl < 2011, let(spv_tmp = 1, TELLER.f = 1, RATE.f = 1)]
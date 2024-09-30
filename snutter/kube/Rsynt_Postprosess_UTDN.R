# RSYNT_POSTPROSESS for kube UTDN
# Skrevet av: VL 6. oktober 2022

# Endrer AAR til AAR - 1, da utdanningsinformasjon i datafilen hører til forrige aar.

# AARl og AARh endres til x-1
KUBE[, `:=` (AARl = AARl-1,
             AARh = AARh-1)]
# AAR overskrives med AARl_AARh
KUBE[, AAR := paste0(AARl, "_", AARh)]

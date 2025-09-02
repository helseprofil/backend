# RSYNT_POSTPROSESS for kube KREFT_1 og KREFT_10
# Skrevet av: VL 2024.11.06

# Sletter ICD-kode C44

KUBE <- KUBE[ICD != "C44"]
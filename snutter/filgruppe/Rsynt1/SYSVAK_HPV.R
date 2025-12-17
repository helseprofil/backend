# RSYNT1 for HPV-tall fra SYSVAK for 2023

# Omformer fra en til to vaksiner (en per kjønn)

# Frem til 2021 fikk vi bare tall for jenter, med KJONN = 2
# For 2022 fikk vi tall for HPV (KJONN == 2) og HPV_M (KJONN == 0) separat
# For 2023 får vi tall for gutter og jenter i samme fil, hvor begge heter HPV og KJONN == "M"/"K"
# - Denne snutten omdøper radene med KJONN == "M" til "HPV_M"
# - KJONN settes deretter til 0 for begge vaksinene, da dette er hhv gutter og jenter.

# METODE:
# For gutter (kjønn == "M" i inndata, og RSYNT1 er før KODEBOK slår inn) 
# endres vaksinenavnet til "HPV_M".

data.table::setnames(DF, c("aar", "kjønn"), c("AAR", "KJONN"))
DF[sykdom == "HPV" & KJONN == "M", let(sykdom = "HPV_M")]
DF[let(KJONN = 0)]

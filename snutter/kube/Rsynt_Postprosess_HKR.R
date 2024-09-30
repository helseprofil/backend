# RSYNT_POSTPROSESS for kube HKR
# Skrevet av: VL 13.desember 2022

# Sletter tall på bydelsnivå for kodegruppene: 
# - Dod_med_hjerte_og_karsykdom
# - Dod_med_hjerneslag
# - Dod_med_hjerteinfarkt
# Fordi: For høy andel uoppgitt bydel for døde, sannsynligvis fordi folkeregisteret sletter bostedsinformasjon for de som er døde. 


# Setter utvalgte måltall til NA
.deletevals <- c("TELLER", "RATE", "SMR", "MEIS", "RATE.n", "sumTELLER", "sumNEVNER")
KUBE[str_detect(KODEGRUPPE, "Dod_") & GEOniv == "B", 
     (.deletevals) := NA_real_]

# Setter teller- og rateflagg til 1
.deletevals.f <- c("TELLER.f", "RATE.f")
KUBE[str_detect(KODEGRUPPE, "Dod_") & GEOniv == "B", 
     (.deletevals.f) := 1]
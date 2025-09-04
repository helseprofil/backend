# Rsynt postprosess SYSVAK_INFLU
# Sletter bydelstall for 2017, og for alle bydeler utenom Oslo for 2020 og 2021
# Gjøres fordi datakvaliteten ikke er god nok, og flagg settes til 1.

KUBE[GEOniv == "B" & grepl("^5001", GEO) & AARl == 2017, let(TELLER.f = 1, RATE.f = 1)]
KUBE[GEOniv == "B" & grepl("^1103|^4601|^5001", GEO) & AARl %in% c(2020, 2021), let(TELLER.f = 1, RATE.f = 1)]

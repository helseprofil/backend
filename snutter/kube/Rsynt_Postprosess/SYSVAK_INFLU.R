# Rsynt postprosess SYSVAK_INFLU
# Sletter bydelstall for Trondheim i 2017, og for alle bydeler utenom Oslo for 2020 og 2021
# Gjøres fordi datakvaliteten ikke er god nok, og flagg settes til 1 uavhengig av om radene var flagget fra før eller ikke.

flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp", "manuellprikket")
idx <- which(KUBE[["GEOniv"]] == "B" & 
               (grepl("^5001", KUBE[["GEO"]]) & KUBE[["AARl"]] == 2017 |
                grepl("^1103|^4601|^5001", KUBE[["GEO"]]) & KUBE[["AARl"]] %in% c(2020, 2021))
             )
data.table::set(KUBE, i = idx, j = flags, value = 1L)

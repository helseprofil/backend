flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp")

idx <- which(KUBE[["spv_tmp"]] != 0 & (KUBE[["sumTELLER"]] <= 6 || KUBE[["sumNEVNER"]] <= 20))
data.table::set(KUBE, i = idx, j = flags, value = 3L)
data.table::set(KUBE, i = idx, j = "manuellprikket", value = 1L)
flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp")

idx <- which(KUBE[["spv_tmp"]] == 0 & (KUBE[["sumTELLER"]] <= 4 | KUBE[["sumNEVNER"]] <= 29))
if(length(idx) > 0){
  khtools::msg("** Prikker ytterligere", length(idx), "rader fordi sumTELLER <= 4 eller sumNEVNER <= 29 i tråd med UDIR/SSB sine prikkeregler\n** Disse radene får SPVFLAGG 3 og manuellprikket = 1")
  data.table::set(KUBE, i = idx, j = flags, value = 3L)
  data.table::set(KUBE, i = idx, j = "manuellprikket", value = 1L)
}
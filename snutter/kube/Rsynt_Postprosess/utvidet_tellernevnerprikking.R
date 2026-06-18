flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp")

idx <- which(KUBE[["spv_tmp"]] == 0 & (KUBE[["sumTELLER"]] <= 6 | KUBE[["sumNEVNER"]] <= 20))
if(length(idx) > 0){
  cat("\n** Prikker ytterligere", length(idx), "rader fordi sumTELLER <= 6 eller sumNEVNER <= 20\n** Disse radene får SPVFLAGG 3 og manuellprikket = 1")
  data.table::set(KUBE, i = idx, j = flags, value = 3L)
  data.table::set(KUBE, i = idx, j = "manuellprikket", value = 1L)
}
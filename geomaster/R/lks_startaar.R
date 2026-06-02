get_lks_startaar <- function(bef_datotag = "2026-05-27-12-21", max_endring = 0.15){
  file <- file.path("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/KUBER/STATBANK/DATERT/parquet", 
                    paste0("BEFOLK_GK_", bef_datotag, ".parquet"))
  d <- data.table::setDT(arrow::read_parquet(file))
  d <- d[as.numeric(GEO) > 999999 & as.numeric(substr(AAR, 1,4)) >= 2002 & KJONN == 0 & ALDER == "0_120"]
  data.table::setkeyv(d, c("GEO", "AAR"))
  
  out <- data.table::copy(unique(d[, .(GEO)]))
  out[, lks_startaar := 0L]

  d[, endring := (data.table::shift(TELLER, type = "lag")/TELLER) - 1, by = GEO]
  d <- d[abs(endring) > max_endring]
  d <- d[, maxaar := max(AAR), by = GEO][AAR == maxaar]
  d <- d[, startaar := as.integer(substr(AAR, 1, 4))][, .(GEO, startaar)]
  
  out[d, on = "GEO", lks_startaar := i.startaar]
  
  return(out)  
}

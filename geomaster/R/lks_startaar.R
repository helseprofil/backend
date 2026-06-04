get_lks_startaar <- function(bef_datotag = "2026-06-03-13-22", 
                             max_endring = 0.15, 
                             basepath = root,
                             dbpath = khelsa,
                             write = F){
  
  cat("\n Connecting to databases")
  con <- DBI::dbConnect(
    odbc::odbc(),
    .connection_string = paste0(
      "Driver={Microsoft Access Driver (*.mdb, *.accdb)};",
      "DBQ=", file.path(basepath, dbpath), ";"
    ),
    encoding = "UTF-8"
  )
  on.exit(DBI::dbDisconnect(con), add = T)
  
  file <- file.path("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/KUBER/STATBANK/DATERT/parquet", 
                    paste0("BEFOLK_GK_", bef_datotag, ".parquet"))
  d <- data.table::setDT(arrow::read_parquet(file))
  d <- d[as.numeric(GEO) > 999999 & as.numeric(substr(AAR, 1,4)) >= 2002 & KJONN == 0 & ALDER == "0_120"]
  data.table::setkeyv(d, c("GEO", "AAR"))
  
  out <- data.table::copy(unique(d[, .(GEO)]))
  out[, lks_startaar := 0L]

  d[, endring := (TELLER / data.table::shift(TELLER, type = "lag")) - 1, by = GEO]
  d <- d[abs(endring) > max_endring]
  d <- d[, maxaar := max(AAR), by = GEO][AAR == maxaar]
  d <- d[, startaar := as.integer(substr(AAR, 1, 4))][, .(GEO, startaar, endring)]
  d[, endring := round(100*endring, 2)]
  out[d, on = "GEO", let(lks_startaar = i.startaar, endring = i.endring)]
  
  data.table::setnames(out, "endring", "befvekst_prosent")
  
  if(write){
    
    # Ask for confirmation before writing
    opts <- c("Overwrite", "Cancel")
    answer <- utils::menu(choices = opts, 
                          title = paste0("Whoops!! You are now replacing the table LKS_STARTAAR in:\n\n", 
                                         basepath, dbpath, 
                                         "\n\nPlease confirm or cancel:"))
    
    if(answer == 1){
      cat("\nUpdating the LKS_STARTAAR table in KHELSA...\n")
      DBI::dbWriteTable(conn = con,
                        name = "LKS_STARTAAR",
                        value = out,
                        batch_rows = 1,
                        overwrite = TRUE,
                        append = FALSE)
      cat(paste0("\nDONE! New table written to:\n", basepath, dbpath, "\n\n"))
    } else {
      cat(paste0("\nYou cancelled, and the table was not overwritten! Puh!\n"))
    }
  }
  
  
  
  
  return(out)  
}

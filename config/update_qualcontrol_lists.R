#' @title update_dimlist
#' @description 
#' Leser TAB1-3-kolonnene i ACCESS og lager en liste over alle potensielle dimensjonskolonner
#' Brukes for å identifisere dimensjoner og verdier. Returnerer en liste som kan limes rett inn i `config-qualcontrol.yml`
#' @noRd
update_dimlist <- function(){
  con <- qualcontrol:::ConnectKHelsa()
  on.exit(RODBC::odbcClose(con), add = TRUE)
  date <- qualcontrol:::SQLdate(Sys.time())
  standarddimensions <- c("GEO", "AAR", "ALDER", "KJONN", "UTDANN", "INNVKAT", "LANDBAK")
  tabdimensions <- data.table::setDT(RODBC::sqlQuery(con, paste0("SELECT TAB1, TAB2, TAB3 FROM FILGRUPPER WHERE VERSJONFRA <=",date, "AND VERSJONTIL >", date)))
  tabdimensions <- data.table::melt(tabdimensions, measure.vars = c("TAB1", "TAB2", "TAB3"))[!is.na(value), unique(value)]
  out <- c(standarddimensions, sort(tabdimensions))
  cat(paste("[", paste(out, collapse = ", "), "]", sep = ""))
}

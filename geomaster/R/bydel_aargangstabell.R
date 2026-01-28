geo_recode_bydel <- function(year, write = FALSE){
  
  if(write) {
    geoFile <- orgdata:::is_path_db(getOption("orgdata.geo"), check = TRUE)
    geo <- orgdata::KHelse$new(geoFile)
    on.exit(geo$db_close(), add = TRUE)
  } else {
    geo <- listenv::listenv()
  }
  
  bydeler <- norgeo::get_code("bydel", from = year, names = T)[, .(code, name)]
  batch = Sys.Date()
  data.table::setnames(bydeler, old = c("code", "name"), new = c("currentCode", "newName"))
  bydeler[, let(oldCode = NA_character_, oldName = NA_character_, changeOccurred = aargang, batch = batch)]
  colorder <- c("oldCode", "oldName", "currentCode", "newName", "changeOccurred", "batch")
  data.table::setcolorder(bydeler, colorder)
  
  geo$tblvalue <- bydeler
  geo$tblname <- paste0("bydel", year)
  
  if(write){
    orgdata:::is_write(write, geo$tblname, geo$dbconn)
  }
  
  if (write) {
    orgdata:::is_write_msg(msg = "write")
    geo$db_write(write = write)
    msgWrite <- paste0("Write table `", geo$tblname, "` is completed in: \n")
    orgdata:::is_verbose(x = geoFile, msg = msgWrite, type = "note")
  }
  
  return(geo$tblvalue[])
}

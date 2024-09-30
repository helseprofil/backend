# To run (change file year and name if needed):
# source("https://raw.githubusercontent.com/helseprofil/backend/main/misc/R/ungdata.R") 
# file <- readUngdata(2023, "Ungdata 2010-2022.sav")
# ungdataKey(file)

readUngdata <- function(year, file){
  basepath <- "O:/Prosjekt/FHP/PRODUKSJON/ORGDATA/NOVA/Ungdata/"
  path <- file.path(basepath, year, "ORG", file)
  haven::read_spss(path)
}

ungdataKey <- function(file){
  
  cols <- names(fil)
  cols <- cols[!cols %in% c("år", "tidspunkt", "kommune", "fylke", "søs", "vekt2020") & !grepl("bydel",cols)]
  
  id <- list() 
  colname <- list()
  col_label <- list()
  val <- list()
  val_label <- list()
  
  for(i in 1:length(cols)){
    
    id[i] <- which(names(fil) == cols[i])
    
    col <- cols[i]
    
    colname[i] <- col
    
    label <- attributes(fil[[col]])$label
    col_label[i] <- ifelse(is.null(label), "", label)
    
    values <- attributes(fil[[col]])$labels
    val[i] <- ifelse(is.null(values), c(""), list(values))
    val_label[i] <- ifelse(is.null(values), c(""), list(names(values)))
    
  }
  
  tab1 <- data.table::data.table(id = unlist(id),
                                 Column = unlist(colname),
                                 Question = unlist(col_label))
  
  tab2 <- data.table::data.table(id = rep(unlist(id), lengths(val)), 
                                 Value = unlist(val),
                                 Label = unlist(val_label))
  
  
  tab <- collapse::join(tab1, tab2, on = "id", how = "full")
  setkey(tab, id)
  tab[, id := NULL]
  
  rootDir <- file.path(fs::path_home(), "helseprofil")
  if (!fs::dir_exists(rootDir)){
    fs::dir_create(rootDir)
  }
  savepath <- file.path(rootDir, "ungdatakey.csv")
  
  data.table::fwrite(tab, savepath, sep = ";", sep2 = c("", "|",""), bom = T)
  cat("File written to", savepath)
}

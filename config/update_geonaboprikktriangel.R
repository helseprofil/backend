# Les inn nyeste befolkningsfil, genererer alle triangler for land-fylke, fylke-kommune, og kommune-bydel
# Lager en liste, som manuelt må kopieres inn i config-khfunctions.yml for å brukes i khfunctions

# d <- data.table::fread("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/KUBER/KOMMUNEHELSA/KH2025NESSTAR/BEFOLK_GK_2024-06-17-14-13.csv")
# data <- arrow::open_dataset("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/FILGRUPPER/NYESTE/BEF_GKny_aar_geo") |> 
#   dplyr::filter(AARl == 2025) |> dplyr::collect() |> data.table::as.data.table()

update_geonaboprikk_triangel <- function(refaar = 2024){
  
  folder <- "O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/KUBER/STATBANK/DATERT/parquet"
  files <- list.files(folder, pattern = "^BEFOLK_GK_\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}\\.parquet$")
  
  # Hent gyldige geokoder
  con <- qualcontrol:::ConnectKHelsa()
  on.exit(RODBC::odbcCloseAll(), add = TRUE)
  g <- RODBC::sqlQuery(con, "SELECT GEO FROM GeoKoder WHERE TIL = '9999' AND TYP = 'O'", as.is = TRUE)$GEO
  idx <- g != 0 & nchar(g) %in% c(1,3,5,7,9)
  g[idx] <- paste0("0", g[idx])
  
  file <- file.path(folder, max(files))
  d_org <- data.table::setDT(arrow::read_parquet(file, col_select = c("GEO", "AAR", "KJONN", "ALDER", "TELLER")))[KJONN == 0 & ALDER == "0_120"][, .(AAR, GEO, TELLER)]
  d_org[GEO != 0 & nchar(GEO) %in% c(1,3,5,7), let(GEO = paste0("0", GEO))]
  
  # Bare inkluder gyldige geokoder i trianglene, single og ugyldige LKS-koder inkluderes etter prikking.
  d_org <- d_org[GEO %in% g]
  max_aar <- as.integer(max(gsub("(^\\d{4})_\\d{4}$", "\\1", d_org$AAR)))
  
  out <- list()
  d <- d_org[grepl(refaar, AAR)]
  
  # Dersom noen geokoder ikke har teller (LKS-startår > refaar), hent disse fra første tilgjengelige
  mangler_teller <- d[is.na(TELLER), unique(GEO)]
  testaar <- refaar + 1
  while(length(mangler_teller) > 0 && testaar <= max_aar){
    dd <- d_org[GEO %in% mangler_teller & grepl(testaar, AAR) & !is.na(TELLER)]
    d <- d[!GEO %in% unique(dd$GEO)]
    d <- data.table::rbindlist(list(d, dd))
    testaar <- testaar + 1
    mangler_teller <- d[is.na(TELLER), unique(GEO)]
  }
  
  if(any(is.na(d$TELLER))){
    warning("Noen rader kommer ut med missing teller, setter disse til 0 i trianglene")
    d[is.na(TELLER), TELLER := 0]
  }
  
  
  d[, GEOniv := data.table::fcase(as.numeric(GEO) == 0, "L",
                                  nchar(GEO) == 2, "F",
                                  nchar(GEO) == 4, "K",
                                  nchar(GEO) == 6, "B",
                                  nchar(GEO) == 10, "V",
                                  default = NA_character_)]
  
  if(any(is.na(d$GEOniv))) stop("GEOniv ikke riktig definert, sjekk i funksjonen")  
  d <- d[order(-TELLER)]
  
  cat("Antall koder fra ulike år brukt til triangler:\n") 
  print(d[, .N, by = c("GEOniv", "AAR")])
  
  out[["LF"]] <- paste0("{0,", paste0(unique(d[GEOniv == "F"]$GEO), collapse = ","), "}")
  FK <- character()
  for(fylke in unique(d[GEOniv == "F"]$GEO)){
    kommuner <- paste0(grep(paste0("^", fylke), unique(d[GEOniv == "K"]$GEO), value = T), collapse = ",")
    FK <- paste0(FK, paste0("{",fylke,",", kommuner, "}"))
  }
  out[["FK"]] <- FK

  bydeler <- d[GEOniv == "B", unique(GEO)]
  bydelskommuner <- unique(substr(bydeler, 1, 4))
  KB <- character()
  for(bydel in bydelskommuner){
    bydeler <- paste0(grep(paste0("^", bydel), d[GEOniv == "B"]$GEO, value = T), collapse = ",")
    KB <- paste0(KB, paste0("{",bydel,",", bydeler, "}"))
  }
  out[["KB"]] <- KB
  
  LKS <- character()
  soner <- d[GEOniv == "V", unique(GEO)]
  overniv <-  unique(sub("00$", "", substr(soner, 1, 6)))
  for(parent in overniv){
    lks <- paste0(grep(paste0("^", parent), d[GEOniv == "V"]$GEO, value = T), collapse = ",")
    LKS <- paste0(LKS, paste0("{",parent,",", lks, "}"))
  }
  out[["LKS"]] <- LKS
  return(out)
}

# test_lks_triangel <- function(){
#  con <- khfunctions:::connect_khelsa() 
#  on.exit(RODBC::odbcCloseAll())
#  lks <- data.table::setDT(RODBC::sqlQuery(con, "SELECT GEO FROM GEOKODER WHERE GEONIV='V'", as.is = T))
#  lks[, overniv := sub("00$", "", substr(GEO, 1, 6))]
#  
#  LKS <- character()
#  for(top in unique(lks$overniv)){
#    lkskoder <- paste0(lks[overniv == top, unique(GEO)], collapse = ",")
#    LKS <- paste0(LKS, paste0("{", top, ",", lkskoder, "}"))
#  }
#  return(LKS)
# }
# 

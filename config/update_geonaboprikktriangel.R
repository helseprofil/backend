# Les inn nyeste befolkningsfil, genererer alle triangler for land-fylke, fylke-kommune, og kommune-bydel
# Lager en liste, som manuelt må kopieres inn i config-khfunctions.yml for å brukes i khfunctions

# d <- data.table::fread("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/KUBER/KOMMUNEHELSA/KH2025NESSTAR/BEFOLK_GK_2024-06-17-14-13.csv")
# data <- arrow::open_dataset("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/FILGRUPPER/NYESTE/BEF_GKny_aar_geo") |> 
#   dplyr::filter(AARl == 2025) |> dplyr::collect() |> data.table::as.data.table()

update_geonaboprikk_triangel <- function(refaar = 2024){
  
  folder <- "O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/KUBER/STATBANK/DATERT/parquet"
  files <- list.files(folder, pattern = "^BEFOLK_GK_\\d{4}-\\d{2}-\\d{2}-\\d{2}-\\d{2}\\.parquet$")
  
  file <- file.path(folder, max(files))
  d <- data.table::setDT(arrow::read_parquet(file))
  
  out <- list()
  d <- d[grepl(refaar, AAR) & KJONN == 0 & ALDER == "0_120"][, .(GEO, TELLER)][order(-TELLER)]
  d[, GEOniv := data.table::fcase(as.numeric(GEO) == 0, "L",
                                  as.numeric(GEO) <= 99, "F",
                                  as.numeric(GEO) <= 9999, "K",
                                  as.numeric(GEO) <= 999999, "B",
                                  default = "V")]
  # dt[qualcontrol:::.popinfo, let(GEOniv = i.GEOniv), on = "GEO"][, GEO := as.character(GEO)]
  d[GEO != 0 & nchar(GEO) %in% c(1,3,5,7), let(GEO = paste0("0", GEO))]
  
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

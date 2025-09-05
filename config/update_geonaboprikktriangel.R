# Les inn nyeste befolkningsfil, genererer alle triangler for land-fylke, fylke-kommune, og kommune-bydel
# Lager en liste, som manuelt må kopieres inn i config-khfunctions.yml for å brukes i khfunctions

d <- data.table::fread("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/KUBER/KOMMUNEHELSA/KH2025NESSTAR/BEFOLK_GK_2024-06-17-14-13.csv")
data <- arrow::open_dataset("O:/Prosjekt/FHP/PRODUKSJON/PRODUKTER/FILGRUPPER/NYESTE/BEF_GKny_aar_geo") |> 
  dplyr::filter(AARl == 2025) |> dplyr::collect() |> data.table::as.data.table()

update_geonaboprikk_triangel <- function(d = data, aar = 2024){
  
  out <- list()
  dt <- d[grepl(aar, AAR) & KJONN == 0 & ALDER == "0_120"][, .(GEO, TELLER)][order(-TELLER)]
  dt[qualcontrol:::.popinfo, let(GEOniv = i.GEOniv), on = "GEO"][, GEO := as.character(GEO)]
  dt[GEO != 0 & nchar(GEO) %in% c(1,3,5,7), let(GEO = paste0("0", GEO))]
  
  fylke <- dt[GEOniv == "F"]
  kommune <- dt[GEOniv == "K"]
  bydel <- dt[GEOniv == "B"]
  
  out[["LF"]] <- paste0("{0,", paste0(fylke$GEO, collapse = ","), "}")
  FK <- character()
  for(f in fylke$GEO){
    kommuner <- paste0(grep(paste0("^", f), kommune$GEO, value = T), collapse = ",")
    FK <- paste0(FK, paste0("{",f,",", kommuner, "}"))
  }
  out[["FK"]] <- FK

  byer <- c("0301", "1103", "4601", "5001")
  KB <- character()
  for(b in byer){
    bydeler <- paste0(grep(paste0("^", b), bydel$GEO, value = T), collapse = ",")
    KB <- paste0(KB, paste0("{",b,",", bydeler, "}"))
  }
  out[["KB"]] <- KB
  
  return(out)
}

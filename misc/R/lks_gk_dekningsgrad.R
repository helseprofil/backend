# Sjekke dekningsgrad for grunnkretser mtp datakvalitet for å kunne gi ut tall på LKS
# Bruker stablet orgfil med debug_opt("geo") for å få en stablet fil på grunnkretsnivå
# Lage kommunekolonne, og gk_ukjent-kolonne

# Output PDF
# Summere opp kommunetall med og uten gk_ukjent, beregne % ukjent per strata
# Gi ut gjennomsnittlig ukjent gk per kommune per år, og andel kommuner > 5,10,15% ukjent gk
# For dimensjoner, plotte % ukjent (y) per kategori over år (x)
format_data <- function(indikator, koblid = NULL){
  orgdata::debug_opt("geo")
  d <- orgdata::make_file(indikator, koblid = koblid)
  d[, names(.SD) := NULL, .SDcols = intersect(names(d), c("batch", "LANDSSB"))]
  
  # omkode geokoder og lage kommune
  d[, names(.SD) := lapply(.SD, as.character), .SDcols = c("oriGEO", "GEO")]
  d[is.na(GEO), GEO := oriGEO][, let(oriGEO = NULL)]
  d[nchar(GEO) == 7, GEO := paste0("0", GEO)]
  data.table::setnames(d, "GEO", "gk")
  d[, let(kommune = substr(gk, 1, 4), gk_ukjent = 0L)]
  d[grepl("99$", gk), let(gk_ukjent = 1L)][, let(gk = NULL)]
  
  # Identifisere kolonner og konvertere til integer
  valcols <- grep("^VAL\\d{1}", names(d), value = T)
  tabcols <- grep("^TAB\\d{1}", names(d), value = T)
  dims <- intersect(c("kommune", "AAR", "ALDER", "KJONN", "UTDANN", "LANDBAK", "INNVKAT"), names(d))
  d[, names(.SD) := lapply(.SD, as.integer), .SDcols = dims]
  
  # Aggregere alder hvis den finnes
  if("ALDER" %in% dims){
    data.table::setnames(d, "ALDER", "ALDERorg")
    d[, ALDER := ""]
    d[, ALDER := data.table::fcase(ALDERorg < 20, "<20",
                                   ALDERorg < 30, "20_29",
                                   ALDERorg < 60, "30_60",
                                   default = "60+")]
    d[, ALDERorg := NULL]
    g <- collapse::GRP(d, c(dims, tabcols, "gk_ukjent"))
    agg_sep <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(d, valcols), g = g))
    
    g <- collapse::GRP(d, c(setdiff(dims, "ALDER"), tabcols, "gk_ukjent"))
    agg_tot <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(d, valcols), g = g))
    agg_tot[, let(ALDER = "ALLE")]
    d <- data.table::rbindlist(list(agg_sep, agg_tot), use.names = T)
  }
  
  # Aggregere kjønn og landbak, bare beholde total
  for(dim in c("KJONN", "LANDBAK")){
    if(dim %in% dims){
      dims <- setdiff(dims, dim)
      g <- collapse::GRP(d, c(dims, tabcols, "gk_ukjent"))
      d <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(d, valcols), g = g))
    }
  }
  
  # Aggregere UTDANN, INNVKAT, beholde total og undergrupper
  for(dim in c("UTDANN", "INNVKAT")){
    if(dim %in% dims){
      g <- collapse::GRP(d, c(setdiff(dims, dim), tabcols, "gk_ukjent"))
      agg <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(d, valcols), g = g))
      agg[, (dim) := 0]
      d <- data.table::rbindlist(list(d, agg), use.names = T)
    }
  }
  
  data.table::setcolorder(d, c(dims, tabcols, valcols))
  
  # Aggregere filen til tall for kjent og ukjent gk i hvert strata
  g_tot <- collapse::GRP(d, c(dims, tabcols))
  agg_tot <- collapse::fmutate(g_tot[["groups"]], collapse::fsum(collapse::get_vars(d, valcols), g = g_tot))
  data.table::setnames(agg_tot, valcols, paste0(valcols, "_totalt"))
  
  g_ukjent <- collapse::GRP(d[gk_ukjent == 1], c(dims, tabcols))
  agg_ukjent <- collapse::fmutate(g_ukjent[["groups"]], collapse::fsum(collapse::get_vars(d[gk_ukjent == 1], valcols), g = g_ukjent))
  data.table::setnames(agg_ukjent, valcols, paste0(valcols, "_ukjent"))
  
  d <- collapse::join(agg_tot, agg_ukjent, on = c(dims, tabcols), how = "l", overid = 2, verbose = 0)
  
  # Beregne andel ukjent for verdikolonnene
  for(val in valcols){
    d[, prop := 0]
    d[!is.na(ukjent), prop := ukjent/totalt, env = list(ukjent = paste0(val, "_ukjent"),totalt = paste0(val, "_totalt"))]
    d[, names(.SD) := NULL, .SDcols = c(paste0(val, c("_ukjent", "_totalt")))]
    data.table::setnames(d, "prop", paste0(val))
  }
  
  d[, names(.SD) := lapply(.SD, factor), .SDcols = setdiff(dims, c("kommune", "AAR"))]
  return(d)
}

run_report <- function(indikator, koblid = NULL){
  
  url <- "https://raw.githubusercontent.com/helseprofil/backend/main/misc/gk_dekning.Rmd"
  local <- tempfile(fileext = ".Rmd")
  download.file(url, local)
  
  rmarkdown::render(input = local,
                    output_file = paste0(indikator, "_gkdekning"),
                    output_dir = "O:/Prosjekt/FHP/PRODUKSJON/VALIDERING/_ANNET/LKS_GK_DEKNING/2026", 
                    params = list(indikator = indikator, koblid = koblid),
                    envir = new.env(parent = globalenv()))
}

                       

  
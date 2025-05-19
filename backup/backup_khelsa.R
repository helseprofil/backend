## Backup av styringsdatabasen
## ---------------------------
backup_khelsa <- function(){
  date <- format(Sys.time(), "%Y%m%d%H%M")
  filename = "KHELSA.mdb"
  styring <- "O:/Prosjekt/FHP/PRODUKSJON/STYRING"
  arkiv <- "O:/Prosjekt/FHP/PRODUKSJON/STYRING/VERSJONSARKIV"
  oldfiles <- list.files(path = arkiv, pattern = ".mdb")
  
  orgfile <- file.path(styring, filename)
  archivefilepath <- file.path(arkiv, paste0("KHELSA", date, ".mdb"))
  
  i = 2
  while(file.exists(archivefilepath)){
    archivefilepath <- file.path(arkiv, paste0("KHELSA", date, "_v", i, ".mdb"))
    i <- i + 1
  }
  
  message("Kopierer:\n", orgfile, "\ntil:\n", archivefilepath, "\n...")
  file.copy(orgfile, archivefilepath)
  message("Ferdig!")
}

## Slik brukes den
## -----------------
## backup(2024)
## backup(2024, "KHELSA.mdb")

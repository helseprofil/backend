Sys.setlocale("LC_ALL", "nb-NO.UTF-8")
# Formattere og laste opp lks-filen
lks <- data.table::fread("geomaster/lks2025.csv", colClasses = "character", encoding = "Latin-1")[, .SD, .SDcols = c("sourceCode", "sourceName", "targetCode")]
data.table::setnames(lks, c("levekaar", "lksnavn", "grunnkrets"))
lks[levekaar == "03019999", levekaar := "0301999999"]

# Finn gk 2024->2025 for å kode om grunnkrets
gkrecode <- norgeo::track_change("grunnkrets", 2024, 2025)[!is.na(oldCode)][, .SD, .SDcols = c("currentCode", "oldCode")]
lks <- collapse::join(lks, gkrecode, on = setNames("oldCode", "grunnkrets"), multiple = T)
lks[!is.na(currentCode), grunnkrets := currentCode][, currentCode := NULL]
data.table::fwrite(lks, "geomaster/lks2025_omkodet.csv", encoding = "UTF-8")

# merge på tblGeo
tbl <- orgdata::geo_merge(id.table = "grunnkrets",
                          id.file = "grunnkrets", 
                          geo.col = "levekaar",
                          geo.level = "levekaar",
                          geo.name = "lksnavn",
                          file = "geomaster/lks2025_omkodet.csv",
                          year = 2025, write = F)




# Hent nyeste korrespondansetabell for levekaar (2022)

d <- norgeo:::find_correspond("levekaar", "grunnkrets", 2022)[, .SD, .SDcols = c("sourceCode", "sourceName", "targetCode")]
data.table::setnames(d, c("levekaar", "name", "grunnkrets"))

# Hent omkodingstabell for grunnkretser fra 2021-> 2025
gk <- orgdata::geo_recode("grunnkrets", 2021, 2025)[, .SD, .SDcols = c("oldCode", "currentCode")][!is.na(oldCode)]
data.table::setnames(gk, c("grunnkrets", "grunnkrets_omk"))

# Kod om grunnkretskoder i korrespondansetabellen
d[gk, on = "grunnkrets", grunnkrets := i.grunnkrets_omk]

# Lagre grunnkretstabellen som csv
data.table::fwrite(d, file.path(fs::path_home(), "helseprofil/levekaar25.csv"), sep = ";")



# merge på tblGeo
tbl <- orgdata::geo_merge(id.table = "grunnkrets",
                          id.file = "grunnkrets", 
                          geo.col = "levekaar",
                          geo.level = "levekaar",
                          geo.name = "name",
                          file = file.path(fs::path_home(), "helseprofil/levekaar25.csv"),
                          year = 2025)

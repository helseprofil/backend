# Fix geo codes manually, to handle splitting of geographical units

# ------------------------------------------------------
# norgeo::track_change() tracks all changes in geographical codes in Norway, 
# making it possible to make reference tables to map old codes to the currently valid codes. 
# When geographical units split, however, old codes will be mapped to multiple new codes.
# This is a challenge when creating time series data, as the mapping is incorrect. 
#
# When using `norgeo::track_change(type = "kommune")`, setting the argument fix = TRUE will run this 
# postprocessing script on the final table, handling all duplicates due to municipalities splitting
#
# Input object is a data.table named DT
#
# For development of this script, start with 
# DT <- norgeo::track_change("k", 1990, 2024, fix = FALSE)
# ------------------------------------------------------

# Handle previous splitting of Snillfjord and Tysfjord

## Snillfjord (1613/5012) split into Heim (5055), Hitra (5056) and Orkland (5059),
### Snillfjord (1613/5012) + Agdenes (1622/5016) + Meldal (1636/5023) + Orkdal (1638/5024) = Orkland
### Snillfjord (1613/5012) + Hitra (1617/5013) = Hitra
### Snillfjord (1613/5012) + Hemne (1612/5011) + Halsa (1571) = Heim
# All codes representing the municipalities before splitting is set to 5099 Trondelag if the period includes the split

old1 <- c("1613", "5012",  # Snillfjord
              "1622", "5016", # Agdenes
              "1571",  # Halsa
              "1612", "5011",  # Hemne
              "1617", "5013", # Hitra
              "1636", "5023",  # Meldal
              "1638", "5024") # Orkdal
current1 <- c("5055", "5056", "5059")

DT[oldCode %in% old1 & currentCode %in% current1,
   let(currentCode = "5099", newName = "Trøndelag")]
DT <- unique(DT)
anywrong1 <- DT[oldCode %in% old1 & currentCode != "5099"]
if(nrow(anywrong1) > 0){
  cat("OBS! Omkoding fra Snillfjord/Agdenes/Halsa/Hemne/Hitra/Meldal/Orkdal til Heim/Hitra/Orkdal er ikke håndtert korrekt.\nHar Heim/Hitra/Orkdal fått nye koder?\nDette må håndteres i `geo-kommune.R`:\n")
  print(anywrong1)
}

## Tysfjord (1850) split into Narvik (1806) and Hamaroy (1875)
### Tysfjord (1850) + Narvik (1805) + Ballangen (1854) became Narvik (1806)
### Tysfjord (1850) + Hamaroy (1849) became Hamaroy (1875)
# Narvik and Hamaroy cannot be reliably estimated backwards because they both got parts of Tysfjord,
# All codes representing the municipalities before splitting is set to  set to 1899 if the period includes the split
old2 <-  c("1850", "1805", "1854", "1849")  # Tysfjord, Narvik, Ballangen, Hamarøy
current2 <- c("1806", "1875") # Narvik, Hamarøy

DT[oldCode %in% old2 & currentCode %in% current2,
   let(currentCode = "1899", newName = "Nordland")]
DT <- unique(DT)
anywrong2 <- DT[oldCode %in% old2 & currentCode != "1899"]
if(nrow(anywrong2) > 0){
  cat("OBS! Omkoding fra Tysfjord/Narvik/Ballangen/Hamarøy til Narvik/Hamarøy er ikke håndtert korrekt.\nHar Narvik/Hamarøy fått nye koder?\nDette må håndteres i `geo-kommune.R`:\n")
  print(anywrong2)
}

# Changes October 2023:
## In 2020, the municipalities Aalesund (1504), Orskog (1523), Skodje (1529), Sandoy (1546) and Haram (1534) became Aalesund (1507)
## In 2024, Haram and Aalesund split up, and were given the codes 1508 (Aalesund) and 1580 (Haram)
## To avoid duplicates, delete the rows where
## - Haram (1534) is recoded to AAlesund (1508)
## - Aalesund (1504), Orskog (1523), Skodje (1529), or Sandoy (1546) is recoded to Haram (1580)

old3 <- c("1504", "1523", "1529", "1546", "1534")
current3 <- c("1508", "1580")
anywrong3 <- DT[oldCode %in% old3 & !currentCode %in% current3]
if(nrow(anywrong3) > 0){
  cat("OBS! Splitting av Ålesund og Haram (omkoding til 1508/1580) er ikke håndtert korrekt\nHar Ålesund/Haram fått nye koder?\nDette må håndteres i `geo-kommune.R`")
  print(anywrong3)
}

DT[oldCode == "1534" & currentCode == "1508" | # Haram -> Aalesund
   oldCode %in% c("1504", "1523", "1529", "1546") & currentCode == "1580", # Others -> Haram
   let(currentCode = "DELETE")]
DT <- DT[currentCode != "DELETE"]

# Geographical code 1507 in data files must be deemed invalid and recoded to 1599, as this represents the sum of AAlesund (1508) + Haram (1580)
DT[oldCode == "1507" & currentCode %in% c("1508", "1580"), 
   let(currentCode = 1599, newName = "Møre og Romsdal")]
DT <- unique(DT)
anywrong4 <- DT[oldCode == "1507" & currentCode != "1599"]
if(nrow(anywrong4) > 0){
  cat("OBS! Splitting av Ålesund og Haram (1507) er ikke håndtert korrekt.\nHar Ålesund/Haram fått nye koder?\nDette må håndteres i `geo-kommune.R`")
  print(anywrong4)
}

# Changes 2025
# These changes appeared in 2025 due to updates in KLASS. 
## 0114 Varteig should only be recoded to 3105 Sarpsborg, not to 3120 Rakkestad (only 1 house)
## 0412 Ringsaker should only be recoded to 3411 Ringsaker, not to Hamar 3403
## 0720 Stokke should only be recoded to 3907 Sandefjord, not to 3905 Tønsberg ()
DT[(oldCode == "0114" & currentCode == "3120") |
   (oldCode == "0412" & currentCode == "3403") |
   (oldCode == "0720" & currentCode == "3905"), currentCode := "DELETE"]
DT <- DT[currentCode != "DELETE"]

anywrong5 <- DT[oldCode %in% c("0114", "0412", "0720") & !currentCode %in% c("3105", "3411", "3907")]
if(nrow(anywrong5) > 0){
  cat("OBS! Splitting av Varteig/Ringsaker/Stokke er ikke håndtert korrekt.\nHar Sarpsborg/Ringsaker/Sandefjord fått nye koder?\nDette må håndteres i `geo-kommune.R`")
  print(anywrong5)
}

# Test whether any geographical code in oldCode is duplicated
duplicated <-  DT[!is.na(oldCode)][duplicated(oldCode) | duplicated(oldCode, fromLast = T)]

if(nrow(duplicated) > 0){
  message("The following lines contains duplicated oldCodes, and must be handled in the config script to avoid recoding errors")
  print(duplicated)
}

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

DT[oldCode %in% c(1613,  # Snillfjord
                  5012,  # Snillfjord
                  1622,  # Agdenes
                  5016,  # Agdenes
                  1571,  # Halsa
                  1612,  # Hemne
                  5011,  # Hemne
                  1617,  # Hitra
                  5013,  # Hitra
                  1636,  # Meldal
                  5023,  # Meldal
                  1638,  # Orkdal
                  5024) & # Orkdal
     currentCode %in% c(5055, # Heim
                        5056, # Hitra
                        5059), # Orkland
   `:=` (currentCode = 5099,
         newName = "Trøndelag")]
# Remove duplicated rows
DT <- unique(DT)

## Tysfjord (1850) split into Narvik (1806) and Hamaroy (1875)
### Tysfjord (1850) + Narvik (1805) + Ballangen (1854) became Narvik (1806)
### Tysfjord (1850) + Hamaroy (1849) became Hamaroy (1875)
# Narvik and Hamaroy cannot be reliably estimated backwards because they both got parts of Tysfjord,
# All codes representing the municipalities before splitting is set to  set to 1899 if the period includes the split

DT[oldCode %in% c(1850,  # Tysfjord
                  1805,  # Narvik
                  1854,  # Ballangen
                  1849) & # Hamaroy
   currentCode %in% c(1806, # Narvik
                      1875), # Hamaroy
   `:=` (currentCode = 1899,
         newName = "Nordland")]
# Remove duplicated rows
DT <- unique(DT)

# Changes October 2023:
## In 2020, the municipalities Aalesund (1504), Orskog (1523), Skodje (1529), Sandoy (1546) and Haram (1534) became Aalesund (1507)
## In 2024, Haram and Aalesund split up, and were given the codes 1508 (Aalesund) and 1580 (Haram)
## To avoid duplicates, delete the rows where
## - Haram (1534) is recoded to AAlesund (1508)
## - Aalesund (1504), Orskog (1523), Skodje (1529), or Sandoy (1546) is recoded to Haram (1580)

delete2024 <- DT[oldCode == 1534 & currentCode == 1508 | # Haram -> Aalesund
                 oldCode %in% c(1504, 1523, 1529, 1546) & currentCode == 1580, # Others -> Haram
                 which = TRUE]

# To avoid deleting the whole table in cases where length(delete2024) == 0
if(length(delete2024) > 0){
  DT <- DT[-delete2024]
}

# Geographical code 1507 in data files must be deemed invalid and recoded to 1599, as this represents the sum of AAlesund (1508) + Haram (1580)
DT[oldCode == 1507 &
   currentCode %in% c(1508, 1580), 
   `:=` (currentCode = 1599,
         newName = "Møre og Romsdal")]
DT <- unique(DT)

# Test whether any geographical code in oldCode is duplicated
duplicated <-  DT[!is.na(oldCode)][duplicated(oldCode) | duplicated(oldCode, fromLast = T)]

if(nrow(duplicated) > 0){
  message("The following lines contains duplicated oldCodes, and must be handled in the config script to avoid recoding errors")
  print(duplicated)
}

rm(duplicated)
rm(delete2024)

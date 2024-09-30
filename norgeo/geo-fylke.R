## Fix geo codes manually, to handle splitting of geographical units

## Although some municipalities moved between counties, 
##  we track old county codes to new codes to be able to estimate time series

# ------------------------------------------------------
# norgeo::track_change() tracks all changes in geographical codes in Norway, 
# making it possible to make reference tables to map old codes to the currently valid codes. 
# When geographical units split, however, old codes will be mapped to multiple new codes.
# This is a challenge when creating time series data, as the mapping is incorrect. 
#
# When using `norgeo::track_change(type = "fylke")`, setting the argument fix = TRUE will run this 
# postprocessing script on the final table, handling all duplicates due to municipalities splitting
#
# Input object is a data.table named DT
#
# For development of this script, start with 
# DT <- norgeo::track_change("f", 1990, 2024, fix = FALSE)
# ------------------------------------------------------

# Changes October 2023:
## In 2020, Østfold (01), Akershus (02), and Buskerud (06) was joined into Viken (30)
## In 2024, this was reversed and Viken (30) split into Østfold (31), Akershus (32), and Buskerud (33)
## In 2020, Vestfold (07) and Telemark (08) joined into Vestfold og Telemark (38)
## In 2024, this was reversed and Vestfold og Telemark (38) split into Vestfold (39) and Telemark (40)
## In 2020, Troms (19) and Finnmark (20) joined into Troms og Finnmark (54)
## In 2024, this was reversed and Troms og Finnmark (54) split into Troms (55) and Finnmark (56)

delete <- DT[oldCode == "01" & currentCode %in% c("32", "33") | # Ostfold -> Akershus/Buskerud
             oldCode == "02" & currentCode %in% c("31", "33") | # Akershus -> Ostfold/Buskerud
             oldCode == "06" & currentCode %in% c("31", "32") | # Buskerud -> Ostfold/Akershus
             oldCode == "07" & currentCode == "40" |            # Vestfold -> Telemark
             oldCode == "08" & currentCode == "39" |            # Telemark -> Vestfold
             oldCode == "19" & currentCode == "56" |            # Troms -> Finnmark
             oldCode == "20" & currentCode == "55",             # Finnmark -> Troms
             which = TRUE]

# To avoid deleting the whole table in cases where length(delete) == 0
if(length(delete) > 0){
DT <- DT[-delete]
}

# Geographical codes 30, 38 and 54 in data files must be deemed invalid and recoded to 99
DT[oldCode %in% c("30", "38", "54") &
   currentCode %in% c("31", "32", "33", "39", "40", "55", "56"), 
   `:=` (currentCode = 99,
         newName = "Invalid due to split")]
DT <- unique(DT)

# Test whether any geographical code in oldCode is duplicated
duplicated <-  DT[!is.na(oldCode)][duplicated(oldCode) | duplicated(oldCode, fromLast = T)]

if(nrow(duplicated) > 0){
  message("The following lines contains duplicated oldCodes, and must be handled in the config script to avoid recoding errors")
  print(duplicated)
}

rm(duplicated)
rm(delete)

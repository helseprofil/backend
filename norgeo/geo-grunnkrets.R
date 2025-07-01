# Fix geo codes manually, to handle splitting of geographical units

# ------------------------------------------------------
# norgeo::track_change() tracks all changes in geographical codes in Norway, 
# making it possible to make reference tables to map old codes to the currently valid codes. 
# When geographical units split, however, old codes will be mapped to multiple new codes.
# This is a challenge when creating time series data, as the mapping is incorrect. 
#
# When using `norgeo::track_change(type = "grunnkrets")`, setting the argument fix = TRUE will run this 
# postprocessing script on the final table, handling all duplicates due to municipalities splitting
#
# Input object is a data.table named DT
#
# For development of this script, start with 
# DT <- norgeo::track_change("g", 1990, 2025, fix = FALSE)
# ------------------------------------------------------

# In some instances, when a grunnkrets is split, the old geographical code is reused
# When the same grunnkrets is mapped to several new geographical codes due to splitting, the system selects the code with the lowest numerical value
# This is not problematic whenever the new units are within the same geographical unit higher in the hiearachy (the same bydel/kommune)
# Whenever the new units are placed in different units higher in the hieararchy, the unit keeping the geographical code must be prioritized.
# The following code make sure this is the case when the correct code is not the numerically smallest. 


# 03013809 was split into Gransdalen and Bjorkheim, we only want to keep currentCode = 03013809 to be mapped to bydel Alna
# 05290409 Smagarda was split to Smagarda, Haugerud, and Gronli. We only want to keep currentCode = 05290409 or 34430409 (new code from 2020)
# 18200107 was split into 18200107 and 18240107 (both Bærøyvågen), we only want to keep currentCode = 18200107

delete <- DT[oldCode == "03013809" & currentCode != "03013809" |
             oldCode == "05290409" & !currentCode %in% c("05290409", "34430409") | 
             oldCode == "18200107" & currentCode != "18200107",
             which = T]

# To avoid deleting the whole table in cases where length(delete) == 0
if(length(delete) > 0) DT <- DT[-delete]

# July 2025
# To handle splitting whenever the original code is reused (e.g. A -> A and B), we do not want to recode anything as the old code is still valid
# Therefore, all rows with oldCode-values also found in currentCode must be deleted.
n_old_valid <- DT[oldCode %in% unique(currentCode), .N]
if(n_old_valid > 0){
  cat("\nFant", n_old_valid, "koder i oldCode som fremdeles er gyldige, sletter disse omkodingene")
  old_valid_which <- DT[oldCode %in% unique(currentCode), which = T]
  DT <- DT[-old_valid_which]
  old_valid_ok <- DT[oldCode %in% unique(currentCode), .N] == 0
  if(!old_valid_ok) cat("\nOBS! det er fortsatt koder i oldCode som finnes i currentCode, dette må sjekkes og håndteres i geo-grunnkrets.R")
}

# Some rows are duplicated with different 'validTo'. We only need one row per unique recoding, and select the most recent entry
n_duplicated_old_current <- DT[duplicated(DT[, .SD, .SDcols = c("oldCode", "currentCode")]), .N]
if(n_duplicated_old_current > 0){
  cat("\nFant", n_duplicated_old_current, "rader med duplikater for oldCode og currentCode, beholder bare nyeste oppføring")
  DT <- unique(DT, by = c("oldCode", "currentCode"), fromLast = TRUE)
  duplicated_old_current_ok <- DT[duplicated(DT[, .SD, .SDcols = c("oldCode", "currentCode")]), .N] == 0
  if(!duplicated_old_current_ok) cat("\nOBS! det er fortsatt rader med duplikater av oldCode og currentCode (har sannsynligvis ingen konsekvenser)")
}



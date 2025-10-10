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
# When the same grunnkrets is mapped to several new geographical codes due to splitting, the orgdata system selects the code with the lowest numerical value
# This is not problematic whenever the new units are within the same geographical unit higher in the hiearachy (the same bydel/kommune)
# Whenever the new units are placed in different units higher in the hierarchy, the unit keeping the geographical code must be prioritized.
# The following code handles duplicates originating from splitting of grunnkrets codes, resulting in a recoding table with only unique recodings.

# October 2025
# Rewrite script to handle the following:

# # 1. For duplicated rows on both old and current code, keep only most recent entry
# data.table::setkeyv(DT, c("oldCode", "currentCode", "changeOccurred"))
# DT <- unique(DT, by = c("oldCode", "currentCode"), fromLast = TRUE)

# 2. Rows where oldCode also exists in currentCode is deleted, as the code is still valid and should not be recoded.
# To handle splitting whenever the original code is reused (e.g. A -> A and B), we do not want to recode anything as the old code is still valid
# Therefore, all rows with oldCode-values also found in currentCode must be deleted.
old_valid <- DT[oldCode %in% unique(currentCode), unique(oldCode)]
if(length(old_valid) > 0){
  cat("\nFant", length(old_valid), "koder i oldCode som fremdeles er gyldige, sletter disse omkodingene")
  DT[oldCode %in% old_valid, let(oldCode = NA_character_)]
  old_valid_ok <- DT[oldCode %in% unique(currentCode), .N] == 0
  if(!old_valid_ok) cat("\nOBS! det er fortsatt koder i oldCode som finnes i currentCode, dette må sjekkes og håndteres i geo-grunnkrets.R")
}

# 3. For rows where the same oldCode is recoded to several currentCodes, the most recent code change is kept
# This handles cases where a code initially was reused after a split (A->A, A->B), but is later recoded resulting in multiple rows (e.g. A->A->C, A->B).
# We only want to keep the most recent recoding (e.g. A->A->C)
duplicated_oldcode <- DT[duplicated(DT$oldCode)][!is.na(oldCode), unique(oldCode)]
if(length(duplicated_oldcode) > 0){
  cat("\nFant", length(duplicated_oldcode), "dupliserte koder i oldCode, beholder bare nyeste omkoding om mulig")
  DT_without_duplicates <- DT[!oldCode %in% duplicated_oldcode] # Keep unique oldCodes
  duplicates <- DT[oldCode %in% duplicated_oldcode][order(oldCode, changeOccurred)]
  duplicates[, mostrecent := max(changeOccurred), by = oldCode]
  duplicates[changeOccurred != mostrecent, let(oldCode = NA_character_)][, let(mostrecent = NULL)]
  DT <- data.table::rbindlist(list(DT_without_duplicates, duplicates), use.names = TRUE)
}

# 4. Check for codes that are still duplicated
# Keep the numerically smallest, corresponding to what has been practiced in orgdata
# Set oldCode to NA for the other rows, they cannot be deleted as that would remove valid currentCodes from the table. 
# Print an informative message, and a list of the codes being split into separate geographical units
duplicated_oldcode <- DT[duplicated(DT$oldCode)][!is.na(oldCode), unique(oldCode)]
if(length(duplicated_oldcode) > 0){
  cat("\nFinner fortsatt", length(duplicated_oldcode), "dupliserte koder i oldCode. For å følge logikken i orgdata, velges laveste numeriske currentCode")
  DT_without_duplicates <- DT[!oldCode %in% duplicated_oldcode] # Keep unique oldCodes
  duplicates <- DT[oldCode %in% duplicated_oldcode][order(oldCode, currentCode)][, let(kommune = sub("(\\d{4})\\d{4}", "\\1", currentCode))]
  duplicates[, let(sammekommune = ifelse(length(unique(kommune)) == 1, 1, 0)), by = oldCode]
  
  differentkommune <- duplicates[sammekommune == 0, unique(oldCode)]
  if(length(differentkommune) > 0){
    cat("\nOBS, følgende grunnkretser er splittet til ulike kommuner, og vil plasseres i den numerisk laveste koden:\n\n")
    print(duplicates[sammekommune == 0, .SD, .SDcols = grep("sammekommune", names(duplicates), value = T, invert = T)])
  }
  
  duplicates[, mincurrentcode := min(currentCode), by = oldCode]
  duplicates[currentCode != mincurrentcode, let(oldCode = NA_character_)]
  duplicates[, let(kommune = NULL, sammekommune = NULL, mincurrentcode = NULL)]
  DT <- data.table::rbindlist(list(DT_without_duplicates, duplicates), use.names = TRUE)
}

# 5. Some duplicates may have been generated 
data.table::setkeyv(DT, c("oldCode", "currentCode", "changeOccurred"))
DT <- unique(DT, by = c("oldCode", "currentCode"), fromLast = TRUE)

onlyunique <- isFALSE(any(duplicated(DT[!is.na(oldCode)]$oldCode)))
if(!onlyunique){
  cat("\nOBS! det er fortsatt duplikater oldCode, dette må sjekkes og håndteres i geo-grunnkrets.R")
  oldcode <- DT[!is.na(oldCode), oldCode]
  duplicates <- oldcode[duplicated(oldcode)]
  cat("\n Følgende koder er duplisert: ", paste0(duplicates, collapse = ", "))
}

# 5. Some duplicates may have been generated 
data.table::setkeyv(DT, c("currentCode", "oldCode", "changeOccurred"))
DT <- unique(DT, by = c("oldCode", "currentCode"), fromLast = TRUE)


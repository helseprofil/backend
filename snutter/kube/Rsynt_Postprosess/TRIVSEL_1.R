# title: "Rsynt_Postprosess_TRIVSEL_1"
# author: "Vegard"
# updated: "2024-01-24"
# 
# Retrieve data from UDIR via API
# Identifies all strata which is censored by UDIR to make sure we do not show these data
# Identifies bydelstrata with only one censored school, where we cannot show data on bydel

cat("\n\nSTARTER RSYNT_POSTPROSESS, R-SNUTT\n")
cat("\nHenter prikkeinformasjon fra UDIR, f.o.m. 2021-2022")
trivselapi <- "https://api.statistikkbanken.udir.no/api/rest/v2/Eksport/148"

# Get all available years
filterverdier <- httr2::request(trivselapi) |>
  httr2::req_url_path_append("filterVerdier") |> 
  httr2::req_retry(max_tries = 5) |>
  httr2::req_perform() |> 
  httr2::resp_body_json(simplifyDataFrame = TRUE)

aar <- paste(filterverdier$TidID$id, collapse = "_")

# Define query
qry <- list(filter = I(paste0("TidID(", aar, ")_EierformID(-10)_SpoersmaalID(436)_TrinnID(6_9)")),
            format = 0)

# Find number of pages
pages <- httr2::request(trivselapi) |>
  httr2::req_url_path_append("sideData") |>
  httr2::req_url_query(!!!qry) |>
  httr2::req_perform() |>
  httr2::resp_body_json(simplifyDataFrame = TRUE)
pages <- pages$JSONSider

# Get data
udirprikk <- data.table::data.table()
for(i in 1:pages){
  newpage <- httr2::request(trivselapi) |>
    httr2::req_url_path_append("data") |> 
    httr2::req_retry(max_tries = 5) |>
    httr2::req_url_query(!!!qry) |> 
    httr2::req_url_query(sideNummer=i) |> 
    httr2::req_perform() |> 
    httr2::resp_body_json(simplifyDataFrame = TRUE)
  
  udirprikk <- data.table::rbindlist(list(udirprikk,
                                          newpage))
}

udirprikk[, `:=` (KJONN = data.table::fcase(KjoennKode == "A", "0",
                                            KjoennKode == "G", "1",
                                            KjoennKode == "J", "2"),
                  TRINN = TrinnKode,
                  AARl = paste0(substr(Skoleaarnavn, 1,4)))]

# Identify censored strata kommune
udirprikk_kommune <- udirprikk[EnhetNivaa == 3 & (AndelSvaralternativ4 == "*" | AndelSvaralternativ5 == "*")]
udirprikk_kommune[, let(GEO = Kommunekode, UDIRPRIKK = 1)]
udirprikk_kommune <- udirprikk_kommune[, .(GEO, AARl, KJONN, TRINN, UDIRPRIKK)]

# Identify censored strata bydel
udirprikk_bydel <- udirprikk[EnhetNivaa == 4, .(AARl, KJONN, TRINN, Organisasjonsnummer, EnhetNavn, AndelSvaralternativ4, AndelSvaralternativ5)]
skolebydel <- data.table::fread("https://raw.githubusercontent.com/helseprofil/backend/refs/heads/main/snutter/misc/SkoleBydel.csv", 
                                colClasses=list(character=c("OrgNo","GEO")))
udirprikk_bydel[skolebydel, GEO := i.GEO, on = c(Organisasjonsnummer = "OrgNo")]
udirprikk_bydel <- udirprikk_bydel[!is.na(GEO)]

udirprikk_bydel[, prikkskole := 0]
udirprikk_bydel[AndelSvaralternativ4 == "*" | AndelSvaralternativ5 == "*", prikkskole := 1]
udirprikk_bydel <- udirprikk_bydel[, .(UDIRPRIKK = sum(prikkskole, na.rm = T)),
                                   by = c("GEO", "AARl", "KJONN", "TRINN")]
udirprikk_bydel <- udirprikk_bydel[UDIRPRIKK == 1]

# Combine lists of strata to censor
censor <- data.table::rbindlist(list(udirprikk_kommune,
                                     udirprikk_bydel))

# Merge udirdata
KUBE <- collapse::join(KUBE, censor, how = "l", on = c("GEO", "AARl", "KJONN", "TRINN"))

# Save object UDIRPRIKKpre
UDIRPRIKKpre <<- KUBE[UDIRPRIKK == 1]
cat(paste0("\n Allerede prikket: ", KUBE[spv_tmp > 0, .N]))
cat(paste0("\n Nye prikker: ", KUBE[spv_tmp == 0 & UDIRPRIKK == 1, .N]))

# Delete data for rows where UDIRPRIKK == 1
flags <- grep("\\.f$", names(KUBE), value = T)
KUBE[spv_tmp == 0 & UDIRPRIKK == 1, c("spv_tmp", flags) := 3]

# Save object UDIRPRIKKpost
UDIRPRIKKpost <<- KUBE[UDIRPRIKK == 1]
cat("\nRSYNT_POSTPROSESS ferdig")

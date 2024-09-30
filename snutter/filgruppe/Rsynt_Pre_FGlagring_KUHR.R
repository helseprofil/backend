# title: "Rsynt_Pre_FGlagring_KUHR
# author: "Vegard"
# updated: "2024-01-25"
# 
# Handle kommune -> bydel (Stavanger)
# Set old GEO codes corresponding to Aalesund/Haram to 1507 for years 2020-2023
setDT(Filgruppe)

# Handle kommune which became bydel
Filgruppe[GEO %in% c("503000", "166200"), GEO := "500104"]
Filgruppe[GEO %in% c("114100" ), GEO := "110308"]
Filgruppe[GEO %in% c("114200"), GEO := "110309"]

# old GEO codes corresponding to AAlesund/Haram
oldcodes <- c("150400", "152300", "152900", "153400", "154600")

# For years 2020-2023, set 1504, 1523, 1534, 1529, 1546 to 1507
Filgruppe[AARl %in% c(2020, 2021, 2022, 2023) & GEO %in% oldcodes,
          GEO := "150700"]

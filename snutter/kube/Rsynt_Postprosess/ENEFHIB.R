flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp")

# Sette flagg for stavangerbydelene til 1 siden de er missing pga tknr ikke kan mappes til bydel. 
# Finnøy og Rennessøy har brukbare tall, så flagger bare dersom radene ikke skulle fått tall. 
KUBE[GEOniv == "B" & grepl("^1103", GEO) & spv_tmp > 0, (flags) := 1]

# Slette utsira i 2015_2017 og 2019_2021 siden 2015- og 2021-tallet er imputert. Vi vil derfor ikke vise disse. 
KUBE[GEO == 1151 & AAR %in% c("2015_2017", "2019_2021"), (flags) := 3]

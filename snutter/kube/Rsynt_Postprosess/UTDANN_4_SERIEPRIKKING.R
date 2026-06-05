# Uoppgitt utdanning har vært en liten gruppe, som har vært med i totalen men ikke som egen gruppe.
# I senere år har denne gruppen blitt større, og vi må derfor gi den ut som egen gruppe. 

# Ettersom UTDANN = 4 har vært veldig liten, blir den stort sett serieprikket. 
# Siden det er et poeng å vise denne gruppen, vil vi "avprikke" de radene som er 
# serieprikket men IKKE personvernprikket (primær eller naboprikket)
# Disse radene kjennes igjen ved at de har serieprikket == 1 og pvern == 0

# Gjelder også bare rader som har spv_tmp = 4, for å hindre at rader som er satt til 
# spv_tmp = 1 i andre snutter, # f.eks pga dekningsgrad, blir avprikket dersom denne snutten kommer etterpå.

# Koden under fjerner prikkeflaggene for disse radene.

# Setter alle flaggkolonner og spv_tmp = 0. Serieprikket settes til 2 og manuellprikket settes til -1 for å indikere manuell avprikking. 

flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp")
idx <- which(KUBE[["UTDANN"]] == 4 & KUBE[["serieprikket"]] == 1 & KUBE[["pvern"]] == 0 & KUBE[["spv_tmp"]] == 4)

data.table::set(KUBE, i = idx, j = flags, value = 0L)
data.table::set(KUBE, i = idx, j = "serieprikket", value = 2L)
data.table::set(KUBE, i = idx, j = "manuellprikket", value = -1L)

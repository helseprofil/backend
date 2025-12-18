# Uoppgitt utdanning har vært en liten gruppe, som har vært med i totalen men ikke som egen gruppe.
# I senere år har denne gruppen blitt større, og vi må derfor gi den ut som egen gruppe. 

# Ettersom UTDANN = 4 har vært veldig liten, blir den stort sett serieprikket. 
# Siden det er et poeng å vise denne gruppen, vil vi "avprikke" de radene som er serieprikket men IKKE personvernprikket (primær eller naboprikket)
# Disse radene kjennes igjen ved at de har serieprikket == 1 og pvern == 0

# Koden under fjerner prikkeflaggene for disse radene.

flags <- intersect(c("spv_tmp", grep("\\.f$", names(KUBE), value = T)), names(KUBE))
KUBE[UTDANN == 4 & serieprikket == 1 & pvern == 0, 
     names(.SD) := as.list(c(rep(0L, length(flags)),2L)), .SDcols = c(flags, "serieprikket")]

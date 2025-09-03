# Korrigerer ALDERSkolonnen B slik at bare tallet hentes ut. 
DF[, B := sub(".*(\\d+)-.*", "\\1", B)]
data.table::setnames(DF, "B", "ALDER")

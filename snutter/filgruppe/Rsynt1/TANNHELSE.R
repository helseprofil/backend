# Korrigerer ALDERSkolonnen B slik at bare tallet hentes ut. 
DF[, ALDER := sub(".*?(\\d+)-.*", "\\1", B)]
DF[, B := trimws(gsub("[1-9][1-9]?-.ringer", "", B))]

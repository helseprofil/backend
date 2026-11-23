# Koder om spørsmålet livetditt til tre spørsmål for å lage kategoriene 0-5, 6+ (fornøyd) og 8+ (svært fornøyd)
DF[, let(livetditt = as.numeric(livetditt),
         mindre_tilfreds = NA_character_,
         tilfreds = NA_character_,
         svaert_tilfreds = NA_character_)]
DF[!is.na(livetditt), let(mindre_tilfreds = "nei",
                          tilfreds = "nei", 
                          svaert_tilfreds = "nei")]
DF[livetditt <= 5, mindre_tilfreds := "ja"]
DF[livetditt >= 6, tilfreds := "ja"]
DF[livetditt >= 8, svaert_tilfreds := "ja"]
DF <- ungdata_reshape_questions(data = DF, 
                                questions = c("mindre_tilfreds", 
                                              "tilfreds", 
                                              "svaert_tilfreds"), 
                                fd = filedescription)
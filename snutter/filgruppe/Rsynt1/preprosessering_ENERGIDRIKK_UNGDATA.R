# Setter opp nytt spørsmål for å kunne lage frekvensen daglig i tillegg til ukentlig
# Daglig = svaralternativ 6+7. 
# 3-4 ganger = svaralternativ 4-7
# Ukentlig = svaralternativ 3-7
DF[, let(kosthold22 = as.numeric(kosthold22),
         energidrikk_ukentlig = NA_character_,
         energidrikk_3_4_ganger = NA_character_,
         energidrikk_daglig = NA_character_)]

DF[!is.na(kosthold22), let(energidrikk_ukentlig = "nei",
                           energidrikk_3_4_ganger = "nei",
                           energidrikk_daglig = "nei")]

DF[kosthold_22 >= 3, energidrikk_ukentlig := "ja"]
DF[kosthold_22 >= 4, energidrikk_3_4_ganger := "ja"]
DF[kosthold_22 >= 6, energidrikk_daglig := "ja"]

DF <- ungdata_reshape_questions(data = DF, questions = c("energidrikk_ukentlig", 
                                                         "energidrikk_3_4_ganger", 
                                                         "energidrikk_daglig"), 
                                fd = filedescription)
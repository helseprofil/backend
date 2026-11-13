# Setter opp nytt spørsmål for å kunne lage frekvensen daglig i tillegg til ukentlig
# Daglig = svaralternativ 6+7. 
# For verdier < 6 (sjeldnere en daglig) kodes svaralternativet om til 1 for å senere kodes til nei
# I kodebok blir 1-2 kodet om til "nei" og 3-7 kodes til "ja" for ukentlig inntak. 
# For daglig-spørsmålet vil dette korrespondere til daglig/sjeldnere
DF[, kosthold22_daglig := kosthold22]
DF[kosthold22_daglig < 6, kosthold22_daglig := "1"]
DF <- ungdata_reshape_questions(data = DF, questions = c("kosthold22", "kosthold22_daglig"), fd = filedescription)
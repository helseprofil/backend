# Setter opp nytt spørsmål for å kunne lage frekvensen daglig i tillegg til ukentlig
# Daglig = svaralternativ 6+7. 
# 3-4 ganger = svaralternativ 4-7
# For verdier < 6 (sjeldnere en daglig) kodes svaralternativet om til 1 for å senere kodes til nei
# I kodebok blir 1-2 kodet om til "nei" og 3-7 kodes til "ja" for ukentlig inntak. 
# For daglig-spørsmålet vil dette korrespondere til daglig/sjeldnere
DF[, let(energidrikk_ukentlig = kosthold22,
         energidrikk_daglig = kosthold22, 
         energidrikk_3_4_ganger = kosthold22)]
DF[energidrikk_daglig < 6, energidrikk_daglig := "1"]
DF[energidrikk_3_4_ganger < 4, energidrikk_3_4_ganger := "1"]
DF <- ungdata_reshape_questions(data = DF, questions = c("energidrikk_ukentlig", "energidrikk_3_4_ganger", "energidrikk_daglig"), fd = filedescription)
# Lager kombinasjonsindikator for daglig inntak av både frukt og grønnsaker
# Setter verdien til 1 og 7, da 1-5 senere blir kodet om til "sjeldnere" og 6-7 kodes til "daglig". 
DF[, fruktoggront := "1"]
DF[kosthold20 >= 6 & kosthold21 >= 6, fruktoggront := "7"]
DF[is.na(kosthold20) | is.na(kosthold21), fruktoggront := NA_character_]
DF <- ungdata_reshape_questions(data = DF, questions = c("kosthold20", "kosthold21", "fruktoggront"), fd = filedescription)
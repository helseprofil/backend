# Rsynt 1 for innlesing av gammel bydelsfil Ungdata

tab1 <- unique(DF$tab1_innles) # Kan bruke filedescription$TAB1, men do_special_handling må også kunne ta med filedescription før dette kan brukes
DF <- DF[, .SD, .SDcols = c(tab1, "Kommune", "AAR", "Tidspunkt", "KJONN", "Klasse", grep("^Bydel", names(DF), value = T))]
if(is.numeric(DF[[tab1]])) DF <- DF[get(tab1) < 98]
DF <- DF[!((Kommune == 301 & (Bydel_Oslo >= 98 | Bydel_Oslo == 17)) | 
           (Kommune == 1103 & Bydel_Stavanger >= 98) |
           (Kommune == 1601))] # Trondheim Kan ikke konverteres til de offisielle bydelene, droppes

DF[Kommune == 301, Kommune := data.table::fcase(Bydel_Oslo == 1, 30107,
                                                Bydel_Oslo == 2, 30106,
                                                Bydel_Oslo == 3, 30105,
                                                Bydel_Oslo == 4, 30108,
                                                Bydel_Oslo == 5, 30104,
                                                Bydel_Oslo == 6, 30103,
                                                Bydel_Oslo == 7, 30102,
                                                Bydel_Oslo == 8, 30101,
                                                Bydel_Oslo == 9, 30109,
                                                Bydel_Oslo == 10, 30116,
                                                Bydel_Oslo == 11, 30112,
                                                Bydel_Oslo == 12, 30111,
                                                Bydel_Oslo == 13, 30110,
                                                Bydel_Oslo == 14, 30113,
                                                Bydel_Oslo == 15, 30114, 
                                                Bydel_Oslo == 16, 30115,
                                                is.na(Bydel_Oslo), 30199)]

DF[Kommune == 1103, Kommune := data.table::fcase(Bydel_Stavanger == 1, 110304,
                                                 Bydel_Stavanger == 2, 110302,
                                                 Bydel_Stavanger == 3, 110301,
                                                 Bydel_Stavanger == 4, 110305,
                                                 Bydel_Stavanger == 5, 110306,
                                                 Bydel_Stavanger == 6, 110307,
                                                 Bydel_Stavanger == 7, 110303)]

DF[Klasse < 98, let(klasse_6delt = paste0(Klasse + 7, "_", 2/Tidspunkt))]
DF[Klasse >= 98, let(klasse_6delt = paste0(Klasse, "_", 2/Tidspunkt))]
DF[, let(teller = 1, vekt2020 = 1)]

dims <- c(tab1, "Kommune", "AAR", "KJONN", "klasse_6delt")
g <- collapse::GRP(DF, dims)
DF <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(DF, c("teller", "vekt2020")), g = g))
DF[, let(exist = 1)]

# Rektangulariser for å få alle strata med. Setter teller og vekt2020 = 0
full <- list()
full[["klasse_6delt"]] <- data.table::data.table(klasse_6delt = c("10_1", "10_2", "9_1", "9_2", "8_1", "8_2", "98_1", "98_2", "99_1", "99_2"))
full[["AAR"]] <- data.table::data.table(AAR = 2010:2016)
for(dim in setdiff(dims, c("klasse_6delt", "AAR"))){
  full[[dim]] <- unique(DF[, .SD, .SDcols = dim])
}

full <- do.call(expand.grid.dt, full)
data.table::setcolorder(full, c("Kommune", "AAR", "KJONN", tab1, "klasse_6delt"))
DF <- collapse::join(full, DF, multiple = T, overid = 2, verbose = 0)
DF[is.na(exist), let(teller = 0, vekt2020 = 0)][, let(exist = NULL)]

# Lag nevner som sum(teller) i hvert strata og gjør alt til tekst
DF[, let(nevner = collapse::fsum(teller)), by = setdiff(dims, tab1)]
DF[, names(.SD) := lapply(.SD, as.character)]

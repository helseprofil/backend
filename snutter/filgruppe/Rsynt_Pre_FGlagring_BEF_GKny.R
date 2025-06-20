# RSYNT_PRE_FGLAGRING for Filgruppe: BEF_GKny
# Sist redigert av: VL 2025.06.20
# Hensikt:
# -Lager middelfolkemengde
# -Omskriving av gammel snutt

dims <- get_dimension_columns(names(Filgruppe))

Filgruppe[UTDANN == 0, UTDANN := 888]
Filgruppe[LANDBAK == 0, LANDBAK := 888]
Filgruppe[INNVKAT == 0, INNVKAT := 888]
Filgruppe[, names(.SD) := NULL, .SDcols = c("BEF.f", "BEF.a")]
alder_max <- collapse::fmax(Filgruppe$ALDERl)
aar_alle <- collapse::funique(Filgruppe$AARl)
aar_max <- collapse::fmax(Filgruppe$AARl)

g <- collapse::GRP(Filgruppe, dims)
Filgruppe <- collapse::add_vars(g[["groups"]], collapse::fsum(collapse::get_vars(Filgruppe, "BEF"), g = g))
Filgruppe[, let(BEF_am1_p = 0, BEF_ap1_pp1 = 0, BEF_a_pp1 = 0)]

Filgruppe <- data.table::rbindlist(list(Filgruppe, 
                                        data.table::copy(Filgruppe)[, let(ALDERl = ALDERl+1, ALDERh = ALDERh+1, BEF = 0, BEF_am1_p = BEF)][ALDERh <= alder_max],
                                        data.table::copy(Filgruppe)[, let(AARl = AARl-1, AARh = AARh-1, ALDERl = ALDERl-1, ALDERh = ALDERh-1, BEF = 0, BEF_ap1_pp1 = BEF)][AARl %in% aar_alle & ALDERl >= 0],
                                        data.table::copy(Filgruppe)[, let(AARl = AARl-1, AARh = AARh-1, BEF = 0, BEF_a_pp1 = BEF)][AARl %in% aar_alle]))

g <- collapse::GRP(Filgruppe, dims)
Filgruppe <- collapse::add_vars(g[["groups"]], 
                                collapse::fsum(collapse::get_vars(Filgruppe, c("BEF", "BEF_am1_p", "BEF_ap1_pp1", "BEF_a_pp1")), g = g))

data.table::setkeyv(Filgruppe, dims)

#Beregner personår-estimater for de tre rektanglene i Lexis-daigrammet (se Carstensen, ?????)
Filgruppe[,LA:=1/3*BEF_am1_p+1/6*BEF_a_pp1]
Filgruppe[,LB:=1/6*BEF_am1_p+1/3*BEF_a_pp1]
Filgruppe[,LC:=1/3*BEF+1/6*BEF_ap1_pp1]
Filgruppe[ALDERl==0,LA:=0]
Filgruppe[ALDERl==0,LB:=1/2*BEF_a_pp1]
#Beregner de to middelfolkemengdene
Filgruppe[,mBEFc:=LA+LB]
Filgruppe[,mBEFa:=LB+LC]

data.table::setnames(Filgruppe,c("BEF","BEF_a_pp1","BEF_ap1_pp1"),c("BEF0101","BEF3112a","BEF3112c"))
befcols <- c("BEF0101","BEF3112a","BEF3112c","mBEFc","mBEFa")
Filgruppe <- Filgruppe[,.SD, .SDcols = c(dims, befcols)]

Filgruppe[, paste0(names(.SD), ".f") := 0, .SDcols = befcols]
Filgruppe[, paste0(names(.SD), ".a") := 1, .SDcols = befcols]
Filgruppe[AARl == aar_max, names(.SD) := NA_real_, .SDcols = grep("BEF0101", befcols, invert = T, value = T)]
Filgruppe[AARl == aar_max, paste0(names(.SD), ".f") := 2, .SDcols = grep("BEF0101", befcols, invert = T, value = T)]

Filgruppe[UTDANN == 888, UTDANN := 0]
Filgruppe[LANDBAK == 888, LANDBAK := 0]
Filgruppe[INNVKAT == 888, INNVKAT := 0]
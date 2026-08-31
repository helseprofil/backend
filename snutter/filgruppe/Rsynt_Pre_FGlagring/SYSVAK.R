# Håndterer rader for HPV der kjønn = 2. Setter disse til KJONN == 0
# Frem til 2021 fikk vi bare tall for KJONN == 2, mens fra 2022 har vi også tall for gutter
# Disse blir flyttet til egen vaksine HPV_M, med KJONN == 0. 
Filgruppe[TAB1 == "HPV" & KJONN == 2, let(KJONN = 0)]

# Generere tellerkolonne fra nevner og vaksinasjonsgrad
data.table::set(Filgruppe, j = "ANTVAKS", value = round(Filgruppe[["VAKSGRAD"]] * (Filgruppe[["DEKNINGSGRUNNLAG"]]/100), 0))
data.table::set(Filgruppe, j = "ANTVAKS.f", value = pmax(Filgruppe[["VAKSGRAD.f"]], Filgruppe[["DEKNIGSGRUNNLAG.f"]], na.rm = T))
data.table::set(Filgruppe, j = "ANTVAKS.a", value = pmax(Filgruppe[["VAKSGRAD.a"]], Filgruppe[["DEKNIGSGRUNNLAG.a"]], na.rm = T))
                
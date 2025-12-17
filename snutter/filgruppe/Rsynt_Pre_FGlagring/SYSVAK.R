# Håndterer rader for HPV der kjønn = 2. Setter disse til KJONN == 0
# Frem til 2021 fikk vi bare tall for KJONN == 2, mens fra 2022 har vi også tall for gutter
# Disse blir flyttet til egen vaksine HPV_M, med KJONN == 0. 
Filgruppe[TAB1 == "HPV" & KJONN == 2, let(KJONN = 0)]

# RSYNT1 for HPV-tall fra SYSVAK
# Omforme SYSVAK fra én vaksine HPV og to kjønn:
#   - til separate vaksiner HPV og HPV_M 
#   - sette Kjønn lik 0 for HPV_M (som for alle andre), og 2 for HPV.
# Det fikses i Rsynt_Postpro i det gamle systemet.
# 
# HENSIKT:
#   Alle andre vaksiner leveres uten Kjønn. HPV telles for gutter og jenter separat.
# Dette kom inn etter at hele databehandlingen var satt opp for data uten kjønn, 
# og da ble det vanskelig å håndtere. Vi ønsker å eliminere Kjønn fra dataene.
# I gamle årgangsfiler trikset vi det til slik at Kjønn er en variabel, og det 
# står "2" for jentene, men dette fikses med en Rsynt_Postprosess i kuben.
# 
# METODE:
#   For gutter (kjønn == "M" i inndata, og RSYNT1 er før KODEBOK slår inn) 
# endres vaksinenavnet til "HPV_M".
# For jenter lar vi det stå som "HPV".
# Så settes Kjønn lik 2 for jentene og 0 ellers.

data.table::setnames(DF, c("aar", "kjønn"), c("AAR", "KJONN"))
DF[sykdom == "HPV" & KJONN == "M", let(sykdom = "HPV_M")]
DF[KJONN == "M", let(KJONN = 0)]
DF[KJONN == "K", let(KJONN = 2)]

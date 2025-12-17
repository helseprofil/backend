# Postprosessering av SYSVAK

# - Prikke alle data på 2-åringer før 2011 for bydeler i Stavanger og Trondheim
flaggcol <- intersect(c("TELLER.f", "RATE.f", "spv_tmp"), names(KUBE))
KUBE[GEOniv == "B" & grepl("^5001|^1103", GEO) & AARl < 2011 & ALDERl == 2, (flaggcol) := 1]

# Slette alle tall på Kikhoste for 16-åringer for år før perioden 2014-2018 dersom 5-årig kube. Setter flagg til 1. 

# Retting av SPV-flagg, skal være 1 for følgende strata
#   Verdiene er altså: 1 .. mangler ELLER kan ikke forekomme, 2 . Lar seg ikke beregne, 3 : anonymisert/skjult.
#   - Difteri, stivkrampe, polyomyelitt: 16år har tall fra 2009. Har flagg 1 før (OK).
#   - Kikhoste: 16år skal være 1 til 2013 og har tall deretter. MEN den må postprosesseres, serieprikkes i løypa, så det er egentlig ingen vits i å behandle her... Gjør det likevel i tilfelle vi klarer å styre serieprikkingen senere.
#   - Hib: oppgis kun for 2år, dvs. sett flagg 1 for 9år og 16år.
#   - Pneumokokk 	:har tall bare for 2år og etter 2007. Flagg er 1 (OK) for 2år til 07, sett det for de andre alderne også, alle år.
#   - Meslinger	:før 2009 sett flagg 1
#   - Kusma 		:ditto
#   - Røde hunder	:ditto
#   - Meslinger, kusma og røde hunder (MMR-vaksine) :Etter 2008 sett flagg 1. 16år har flere flagg før 2008, sett til 1.
#   - HPV-infeksjon (for jenter 16 år) : Sett Flagg 1 for 2år og 9år.
#   				 16år har flagg=1 før 2013 (OK).
#   - Rotavirusinfeksjon: har tall for 2år fra 2017. Flere flagg tidligere, sett til 1 for de andre alderne og for 2år før 2017.
#   - Hepatitt B	:(ny fra mars-20) Data fra 2019. Flagg 1 for tidligere år (delingskommuner hadde fått 3),
#   				og for andre aldersgrupper enn 2år.

KUBE[VAKSINE %in% c("Difteri", "Stivkrampe", "Polyomyelitt") & ALDERl ==  16 & AARl < 2009, (flaggcol) := 1]
KUBE[VAKSINE == "Kikhoste" & ALDERl == 16 & AARl < 2014, (flaggcol) := 1]
KUBE[VAKSINE == "HIB" & ALDERl %in% c(9, 16), (flaggcol) := 1]
KUBE[VAKSINE == "Pneumokokk" & (ALDERl %in% c(9, 16) | (ALDERl == 2 & AARl <= 2007)), (flaggcol) := 1]
KUBE[VAKSINE %in% c("Meslinger", "Kusma", "Rodehunder")  & AARl < 2009, (flaggcol) := 1]
KUBE[VAKSINE == "MMR" & (AARl > 2008 | ALDERl == 16), (flaggcol) := 1]
KUBE[VAKSINE %in% c("HPV", "HPV_M") & ALDERl %in% c(2,9), (flaggcol) := 1]
KUBE[VAKSINE ==  "HPV" & ALDERl == 16 & AARl < 2013, (flaggcol) := 1]
KUBE[VAKSINE ==  "Rotavirusinfeksjon" & (ALDERl %in% c(9,16) | AARl < 2017) , (flaggcol) := 1]
KUBE[VAKSINE ==  "HepatittB" & (AARl < 2019 | ALDERl != 2), (flaggcol) := 1]

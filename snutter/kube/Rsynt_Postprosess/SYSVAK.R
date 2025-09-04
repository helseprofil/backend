# * POSTPROSESSERING: Sysvak Ettårige tall (store kommuner) - KH og NH FELLESfil
# *  -  OGSÅ for 5-årig fil - denne filen dekket alt som sto i separat script "Rsynt_postprosess_SYSVAK". (stbj 15.05.25)
# *
#   * HUSK: Datasettet for RSYNT inneholder oppdelte intervallvariabler og mange hjelpevariabler.
# * Bl.a. SPVflagg fins ikke ennå.
# * START UTVIKLING med å ta ut fildump "STATAPRIKKpost" - eller med flg. Statakommando (lim inn i feltet):
#   /*
#   save "O:/Prosjekt/FHP/PRODUKSJON\RUNTIMEDUMP\SYSVAK_1_rsynt_postpro.dta", replace
# exit
# */
#   /*	Håndtere KJONN 
# Rette diverse SPVflagg, som kommer ut med inkonsekvent merking.
# Slette MMR-tall etter 2008.
# 
# 03.04.19 (V5): Rotavirus er kommet med fra 2017.
# 27.03.20 (V6): Hepatitt B er kommet med fra 2019.
# 19.04.2024 (V8): Lagt inn bydelsfikser fra femårig fil, de var uteglemt her.
# 
# 
# (Ikke nødvendig apr-2019: "Ferdig fil må i tillegg postprosesseres - vi må skjøte på 
# 	kikhoste 16-åringer fra 2014, den serieprikkes av systemet."
#   
#   */
#     /*-------------------------------------------------------------------------------
#     * INNPAKNING I UTVIKLINGSFASEN
#   
#   local datakatalog "O:/Prosjekt/FHP/PRODUKSJON\RUNTIMEDUMP"
#   local Sysvakfil "SYSVAK_1_rsynt_postpro"
#   
#   *local targetkatalog: Lagrer ikke, det fikser R-innpakningen.
#   
#   use "`datakatalog'/`Sysvakfil'.dta", clear
#   
#   *-------------------------------------------------------------------------------
#     * KJØRING
#   
#   ******************************************************************************/
#     * Script: Rsynt_Postprosess_SYSVAK_1_v8.do
#   log close _all
#   log using "O:/Prosjekt/FHP/PRODUKSJON\DEVELOP\POSTPROS\logg_SYSVAK_1", replace
#   
#   destring GEO, generate(NUMgeo)
#   
#   * HÅNDTERE KJONN: For å få med HPV har vi bedt om både kjonn==0 og ==2 i kubedatafilen.
#   * OBS: For HPV_M (gutter) er kjønn satt til 0, så den omfattes ikke av denne snutten.
#   * For kjonn==2 er det data kun for HPV. For vaks=="HPV" er det data kun for kjonn==2.
#   * M.a.o.: Slette alle HPV med kjonn==0, Endre kjonn til 0 for HPV med kjonn==2, 
#   * og dropp alle kjonn==2 etterpå.
#   drop if KJONN==0 & VAKSINE=="HPV"
#   replace KJONN=0 if KJONN==2 & VAKSINE=="HPV"
#   drop if KJONN==2
#   
#   *-------------------------------------------
#     * -Bydeler i Trondheim og Stavanger: Aldersgruppen 2 år skal prikkes på alle vaksiner, før 2011. 
#   *  Dette er data av dårlig kvalitet, flagges "Manglende data"(1).
#   replace TELLER 		=. if ( int(NUMgeo/100) == 5001 | int(NUMgeo/100) == 1103) & ALDER == "2_2" & AARl <2011
#   replace TELLER_f 	=1 if ( int(NUMgeo/100) == 5001 | int(NUMgeo/100) == 1103) & ALDER == "2_2" & AARl <2011
#   
#   replace RATE 		=. if ( int(NUMgeo/100) == 5001 | int(NUMgeo/100) == 1103) & ALDER == "2_2" & AARl <2011
#   replace RATE_f 		=1 if ( int(NUMgeo/100) == 5001 | int(NUMgeo/100) == 1103) & ALDER == "2_2" & AARl <2011
#   
#   replace SMR 		=. if ( int(NUMgeo/100) == 5001 | int(NUMgeo/100) == 1103) & ALDER == "2_2" & AARl <2011
#   * SMR har ikke flagg
#   
#   *-------------------------------------------
#     * Slette alle tall for MMR etter 2008.
#   replace TELLER		=. if ( VAKSINE=="MMR") & AARl >2008
#   replace RATE		=. if ( VAKSINE=="MMR") & AARl >2008
#   replace SMR 		=. if ( VAKSINE=="MMR") & AARl >2008
#   //Setter SPVflagg nedenfor
#   *exit
#   
#   *-------------------------------------------
#     * Bydeler: Kikhoste, 16år slettes (flagg=1) før 2014.
#   replace TELLER 		=. if VAKSINE=="Kikhoste" & GEOniv=="B" & ALDER == "16_16" & AARl <2014
#   replace TELLER_f 	=1 if VAKSINE=="Kikhoste" & GEOniv=="B" & ALDER == "16_16" & AARl <2014
#   replace RATE 		=. if VAKSINE=="Kikhoste" & GEOniv=="B" & ALDER == "16_16" & AARl <2014
#   replace RATE_f 		=1 if VAKSINE=="Kikhoste" & GEOniv=="B" & ALDER == "16_16" & AARl <2014
#   replace SMR 		=. if VAKSINE=="Kikhoste" & GEOniv=="B" & ALDER == "16_16" & AARl <2014
#   
#   * Rette SPVflagg for Kikhoste 16år til 1 for årganger før 2014-2018. Tall vises deretter.
#   replace TELLER_f 	=1 if VAKSINE=="Kikhoste" & ALDER == "16_16" & AARh < 2018
#   replace RATE_f 		=1 if VAKSINE=="Kikhoste" & ALDER == "16_16" & AARh < 2018
#   
#   
#   * Rette SPVflagg: Tidsseriene har inkonsekvent merking. Sjekket påstandene mot fasitfilen nov-2016
#   *------------------------------------------------------
#     * Verdiene er altså: 1 .. mangler ELLER kan ikke forekomme, 2 . Lar seg ikke beregne, 3 : anonymisert/skjult.
#   *- Difteri		:16år har tall fra 2009. Har flagg 1 før (OK).
#   *- Stivkrampe	:ditto
#   *- Kikhoste		:16år skal være 1 til 2013 og har tall deretter. MEN den må postprosesseres, 
#   *				 serieprikkes i løypa, så det er egentlig ingen vits i å behandle her... Gjør det likevel,
#   *				 i tilfelle vi klarer å styre serieprikkingen senere.
#   *- Poliomyelitt	:som Difteri
#   *- Hib 			:oppgis kun for 2år, dvs. sett flagg 1 for 9år og 16år.
#   *- Pneumokokk 	:har tall bare for 2år og etter 2007. Flagg er 1 (OK) for 2år til 07, 
#   *				 sett det for de andre alderne også, alle år.
#   *- Meslinger	:før 2009 sett flagg 1
#   *- Kusma 		:ditto
#   *- Røde hunder	:ditto 
#   *- Meslinger, kusma og røde hunder (MMR-vaksine) :Etter 2008 sett flagg 1. 16år har flere flagg før 2008, sett til 1.
#   *- HPV-infeksjon (for jenter 16 år) : Sett Flagg 1 for 2år og 9år.
#   *				 16år har flagg=1 før 2013 (OK).
#   *- Rotavirusinfeksjon: har tall for 2år fra 2017. Flere flagg tidligere, sett til 1 for de andre alderne og for 2år før 2017.
#   *- Hepatitt B	:(ny fra mars-20) Data fra 2019. Flagg 1 for tidligere år (delingskommuner hadde fått 3),
#   *				og for andre aldersgrupper enn 2år.
#   
#   replace RATE_f =1 if (VAKSINE=="Difteri" | VAKSINE=="Stivkrampe" | VAKSINE=="Poliomyelitt") & ALDER=="16_16" & AARl<2009
#   replace RATE_f =1 if VAKSINE=="Kikhoste" & ALDER=="16_16" & AARl<=2013
#   replace RATE_f =1 if VAKSINE=="HIB" & (ALDER=="9_9" | ALDER=="16_16")
#   replace RATE_f =1 if VAKSINE=="Pneumokokk" & (ALDER=="9_9" | ALDER=="16_16")
#   replace RATE_f =1 if (VAKSINE=="Meslinger" | VAKSINE=="Kusma" | VAKSINE=="Rodehunder") & AARl<2009
#   replace RATE_f =1 if VAKSINE=="MMR" & AARl>2008 
#   replace RATE_f =1 if VAKSINE=="MMR" & AARl<=2008 & ALDER=="16_16"
#   replace RATE_f =1 if VAKSINE=="HPV" & (ALDER=="2_2" | ALDER=="9_9")
#   replace RATE_f =1 if VAKSINE=="HPV_M" & (ALDER=="2_2" | ALDER=="9_9")
#   replace RATE_f =1 if VAKSINE=="HPV" & ALDER=="16_16" & AARl<2013
#   replace RATE_f =1 if VAKSINE=="Rotavirusinfeksjon" & AARl<2017 
#   replace RATE_f =1 if VAKSINE=="Rotavirusinfeksjon" & (ALDER=="9_9" | ALDER=="16_16")
#   replace RATE_f =1 if VAKSINE=="HepatittB" & AARl<2019
#   replace RATE_f =1 if VAKSINE=="HepatittB" & AARl >= 2019 & ALDER != "2_2"
#   
#   replace TELLER_f =1 if (VAKSINE=="Difteri" | VAKSINE=="Stivkrampe" | VAKSINE=="Poliomyelitt") & ALDER=="16_16" & AARl<2009
#   replace TELLER_f =1 if VAKSINE=="Kikhoste" & ALDER=="16_16" & AARl<=2013
#   replace TELLER_f =1 if VAKSINE=="HIB" & (ALDER=="9_9" | ALDER=="16_16")
#   replace TELLER_f =1 if VAKSINE=="Pneumokokk" & (ALDER=="9_9" | ALDER=="16_16")
#   replace TELLER_f =1 if (VAKSINE=="Meslinger" | VAKSINE=="Kusma" | VAKSINE=="Rodehunder") & AARl<2009
#   replace TELLER_f =1 if VAKSINE=="MMR" & AARl>2008 
#   replace TELLER_f =1 if VAKSINE=="MMR" & AARl<=2008 & ALDER=="16_16"
#   replace TELLER_f =1 if VAKSINE=="HPV" & (ALDER=="2_2" | ALDER=="9_9")
#   replace TELLER_f =1 if VAKSINE=="HPV_M" & (ALDER=="2_2" | ALDER=="9_9")
#   replace TELLER_f =1 if VAKSINE=="HPV" & ALDER=="16_16" & AARl<2013
#   replace TELLER_f =1 if VAKSINE=="Rotavirusinfeksjon" & AARl<2017 
#   replace TELLER_f =1 if VAKSINE=="Rotavirusinfeksjon" & (ALDER=="9_9" | ALDER=="16_16")
#   replace TELLER_f =1 if VAKSINE=="HepatittB" & AARl<2019
#   replace TELLER_f =1 if VAKSINE=="HepatittB" & AARl >= 2019 & ALDER != "2_2"
#   
#   *-------------------------------------------
#     **** MIDLERTIDIG FIKS: SLETTE DELTE FYLKER I AFFISERTE ÅRGANGER  ****
#     **** TATT UT
#   * include "O:/Prosjekt/FHP\PRODUKSJON\BIN\Z_Statasnutter\Rsynt_Postprosess_SYSVAK_skjuleF.do"
#   
#   
#   *-------------------------------------------
#     * Rydding
#   drop NUMgeo
#   log close _all
#   * Ferdig
#   
#   
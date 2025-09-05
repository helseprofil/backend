# RSYNT_POSTPROSESS for kube ENEFHIB_3
# Forfatter: VL
# Sist oppdatert juni 2025

# Fikser opp SPVFLAGG i Stavangerbydeler som har blitt feil 

KUBE[GEOniv == "B" & grepl("^1103", GEO) & TELLER.f > 0, let(TELLER.f = 9, RATE.f = 9)]

# Slette siste 
# DENNE KODEN ER VANSKELIG Å FORSTÅ BAKGRUNNEN FOR, OG MÅ TAS PÅ ET REDAKSJONSMØTE
# Tall for utsira er slettet for perioden 2019-2021, fordi inntallet er imputert (i kodebok er missing -> 1)
# I filgruppen er det flere rader med TELLER = 1, som da er imputert med kodebok. Dette gjelder for kommunene 
# - 5604 (2004) i 2022
# - 3301 (0602) i 2022 
# - 4633 i 2024
# - 1151 i 2015, 2021, 2022, 2023, 2024
# Det treårige tallet for Utsira blir eksplisitt slettet i 2019-2021, men var dette fordi det kom med i profilen?
# Hvorfor er ikke de andre treårige tallene som påvirkes av denne imputeringen håndtert på samme måte? De har også kommet med i profiler.
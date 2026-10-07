# Generere tellerkolonne fra ANDEL og ANTALL_SVAR. Kopiert fra SYSVAK.
Filgruppe[, let(ANTALL = round(ANDEL * (ANTALL_SVAR/100), 0),
                ANTALL.f = pmax(ANDEL.f, ANTALL_SVAR.f, na.rm = T),
                ANTALL.a = pmax(ANDEL.a, ANTALL_SVAR.a, na.rm = T))]

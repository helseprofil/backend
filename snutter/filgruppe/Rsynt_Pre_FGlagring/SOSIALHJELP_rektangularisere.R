# Behov: Rådatafilen for 2017 mangler helt rader for alder 18-19 år.
# Det får senere rektangularisering (innen hvert år) til å hoppe over den aldersgruppen, med diverse følgefeil.
# Jeg vil gjøre en komplett rektangularisering, og fylle inn Teller = 0 eksplisitt for de nye radene.
#
# Det er helt annerledes enn Statas "fillin"! Her må man gjøre det temmelig manuelt.
# Koden for å rektangularisere: Kan stjele fra \backend\snutter\Filgruppe\Rsynt1\UNGDATA_B2015_K2010.R.

# UTVIKLING:
## Gi fildumpen (som bare ligger i Environment etter filgruppekjøring) riktig navn som datasett
## Filgruppe <- DUMPS$SOSIALHJELP_RSYNT_PRE_FGLAGRINGpre
## Hent parametre for filgruppen (kolonnenavn) - aner ikke hvordan.

# KJØR:
# Lag en liste over dimensjonsvariabler. Det finnes sikkert en function for det ...

# - Les ut alle unike kategorier av hver dimensjonsvariabel, og lagre dem i en list().
## Hmm. Vi skal ikke ha alle kombinasjoner av alt, f.eks. AARl og -h.
## Vegard: Da kan de variablene som henger sammen, settes opp sammen i lista!
## Dette trikset plukker ut de _eksisterende_ kombinasjonene, og da unngår jeg at expand.grid lager nye.

full <- list()
full[["geo"]]   <- unique(Filgruppe[, .SD, .SDcols = c("GEO", "GEOniv", "FYLKE")])
full[["aar"]]   <- unique(Filgruppe[, .SD, .SDcols = c("AARl", "AARh")])
full[["alder"]] <- unique(Filgruppe[, .SD, .SDcols = c("ALDERl", "ALDERh")])

dims <- c("KJONN", "UTDANN", "INNVKAT", "LANDBAK", "TAB1")
for(dim in dims){
  full[[dim]] <- unique(Filgruppe[, .SD, .SDcols = dim])
}

# - Gi denne lista til en "expand.grid"-kommando (som Yusman opprinnelig laget).
# Denne ligger i khfunctions, men er ikke en eksportert funksjon, så den krever spes. syntaks :::
full <- do.call(khfunctions:::expand.grid.dt, full)

# - Nå har du et rektangulært dataobjekt med bare dimensjonene! Server dette,
#   pluss selve datasettet, til en join-kommando, slik at tallene merges på.
#   Da settes det missing i alle de nye radene.
# - Først flagger vi alle eksisterende rader i datasettet med "exist". Den vil mangle i nye rader.
Filgruppe[, let(exist = 1)]
Filgruppe <- collapse::join(full, Filgruppe, multiple = T, overid = 2, verbose = 0)

# - Fyll inn de nye radene med verdi null for antall.
# Filgruppe[is.na(exist), let(teller = 0)][, let(exist = NULL)]
Filgruppe[is.na(exist), let(ANTSOSHJ = 0)][, let(ANTSOSHJ.a = 1)][, let(ANTSOSHJ.f = 0)][, let(exist = NULL)]

# Ferdig - nå er også "exist"-kolonnen fjernet.

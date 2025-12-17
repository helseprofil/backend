# postpros-sntt for AAP og UFORE
# Begrunnelse: Vi har ikke informasjon om foreldres utdanning for personer < 25 år
# Sletter undergrupper av UTDANN for aldersgruppene som inkluderer de under 25

flaggcols <- intersect(c("TELLER.f", "RATE.f", "spv_tmp"), names(KUBE))
KUBE[ALDERl < 25 & UTDANN != 0, (flaggcols) := 1]
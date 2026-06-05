# postpros-sntt for AAP og UFORE
# Begrunnelse: Vi har ikke informasjon om foreldres utdanning for personer < 25 år
# Sletter undergrupper av UTDANN for aldersgruppene som inkluderer de under 25
flags <- c(grep("\\.f$", names(KUBE), value = T), "spv_tmp", "manuellprikket")
KUBE[spv_tmp == 0 & ALDERl < 25 & UTDANN != 0, (flags) := 1L]

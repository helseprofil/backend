# RSYNT postprosess TANNHELSE
# For at det ikke skulle bli kluss i aggregering etter omkoding av gamle til nye fylkeskoder, hvor
# det var missing på den ene (som deretter medfører at det aggregerte tallet blir flagget), settes alle implisitte
# nuller til 0. Det vil si at tall som ikke finnes inn får SPVFLAGG = 3, som må ordnes her slik at flagget blir 2. 

KUBE[AARl %in% 2020:2023 & GEO %in% c("31", "32", "33", "39", "40", "55", "56"),
     let(TELLER.f = 1, RATE.f = 1)]
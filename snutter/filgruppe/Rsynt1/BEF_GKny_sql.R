# Fjerne totalverdier for LANDBAK og INNVKAT
# Rektangularisere bydeler for AAR og KJONN

DBI::dbExecute(
  conn = duckdb_con,
  statement = sprintf("
    -- Fjern totalkategorier
    DELETE FROM %s 
    WHERE LANDBAK = '0'
       OR INNVKAT = '0';

    -- Opprett manglende bydelsrader
    INSERT INTO %s (
        GEO,
        LEVEL,
        AAR,
        KJONN,
        ALDER,
        UTDANN,
        LANDBAK,
        INNVKAT,
        BEF
    )
    SELECT
        komb.GEO,
        'bydel' AS LEVEL,
        komb.AAR,
        komb.KJONN,
        '1' AS ALDER,
        '1' AS UTDANN,
        '1' AS LANDBAK,
        '8' AS INNVKAT,
        '0' AS BEF
    FROM (
        SELECT DISTINCT
            GEO,
            AAR,
            KJONN
        FROM %s
    ) komb
    WHERE NOT EXISTS (
        SELECT 1
        FROM %s t
        WHERE t.GEO   = komb.GEO
          AND t.AAR   = komb.AAR
          AND t.KJONN = komb.KJONN
          AND t.LEVEL = 'bydel'
    );
  ",
                      tablename,
                      tablename,
                      tablename,
                      tablename
  )
)

# Fjerne totalverdier for LANDBAK og INNVKAT
# Rektangularisere bydeler og levekårssoner for AAR og KJONN

DBI::dbExecute(
  conn = duckdb_con,
  statement = sprintf("
    -- Fjern totalkategorier
    DELETE FROM %s
    WHERE LANDBAK = '0'
       OR INNVKAT = '0';

    -- Opprett manglende rader for bydel/levekårssone
    WITH komb AS (
        SELECT
            g.GEO,
            a.AAR,
            k.KJONN
        FROM (
            SELECT DISTINCT GEO
            FROM %s
            WHERE LENGTH(CAST(GEO AS VARCHAR)) BETWEEN 5 AND 6
               OR LENGTH(CAST(GEO AS VARCHAR)) BETWEEN 9 AND 10
        ) g
        CROSS JOIN (
            SELECT DISTINCT AAR
            FROM %s
        ) a
        CROSS JOIN (
            SELECT DISTINCT KJONN
            FROM %s
        ) k
    )
    INSERT INTO %s (
        GEO,
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
        komb.AAR,
        komb.KJONN,
        '1' AS ALDER,
        '1' AS UTDANN,
        '1' AS LANDBAK,
        '8' AS INNVKAT,
        '0' AS BEF
    FROM komb
    WHERE NOT EXISTS (
        SELECT 1
        FROM %s t
        WHERE t.GEO   = komb.GEO
          AND t.AAR   = komb.AAR
          AND t.KJONN = komb.KJONN
    );
  ",
                      tablename,
                      tablename,
                      tablename,
                      tablename,
                      tablename,
                      tablename
  )
)

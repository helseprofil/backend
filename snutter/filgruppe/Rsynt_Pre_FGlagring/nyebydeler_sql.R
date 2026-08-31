# Rsynt_Pre_FGlagring for å sikre at Klæbu, Rennesøy og Finnøy kommer med i bydelstallene for hhv. Trondheim og Stavanger, ikke bare i kommunetallet.
# GEO: Sårbart for nye kommune- eller bydelskoder for Stavanger og Trondheim.


sql <- sprintf(
  " 
  -- Oppdater eksisterende rader
  UPDATE %1$s 
    SET GEO = '500104' WHERE GEO IN ('503000', '166200');
  UPDATE %1$s
    SET GEO = '110308' WHERE GEO = '114100';
  UPDATE %1$s 
    SET GEO = '110309' WHERE GEO = '114200';
    -- Legg til nye bydelsrader
  INSERT INTO %1$s
  SELECT
  * REPLACE (
    CASE
    WHEN GEO IN ('5030', '1662') THEN '500104'
    WHEN GEO = '1141' THEN '110308'
    WHEN GEO = '1142' THEN '110309'
    END AS GEO,
    'B' AS GEOniv
  )
  FROM %1$s 
  WHERE GEO IN ('5030', '1662', '1141', '1142');",
  tablename)

invisible(DBI::dbExecute(duckdb_con, sql))
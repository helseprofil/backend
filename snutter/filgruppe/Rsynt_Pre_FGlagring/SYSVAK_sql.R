# Håndterer rader for HPV der kjønn = 2. Setter disse til KJONN == 0
# Frem til 2021 fikk vi bare tall for KJONN == 2, mens fra 2022 har vi også tall for gutter
# Disse blir flyttet til egen vaksine HPV_M, med KJONN == 0. 

vaksgradF <- DBI::dbQuoteIdentifier(duckdb_con, "VAKSGRAD.f")
vaksgradA <- DBI::dbQuoteIdentifier(duckdb_con, "VAKSGRAD.a")
dekningF <- DBI::dbQuoteIdentifier(duckdb_con, "DEKNINGSGRUNNLAG.f")
dekningA <- DBI::dbQuoteIdentifier(duckdb_con, "DEKNINGSGRUNNLAG.a")
antvaksF <- DBI::dbQuoteIdentifier(duckdb_con, "ANTVAKS.f")
antvaksA <- DBI::dbQuoteIdentifier(duckdb_con, "ANTVAKS.a")
tab_sql <- DBI::dbQuoteIdentifier(duckdb_con, tablename)

sql <- sprintf(
  "CREATE OR REPLACE TABLE %s AS
    SELECT * REPLACE (
              CASE
                WHEN TAB1 = 'HPV' AND KJONN = 2 THEN 0 ELSE KJONN
              END AS KJONN),
    ROUND(VAKSGRAD * (DEKNINGSGRUNNLAG / 100.0), 0) AS ANTVAKS,
    GREATEST(%s, %s) AS %s,
    GREATEST(%s, %s) AS %s
  FROM %s",
  tab_sql,
  vaksgradF, dekningF, antvaksF,
  vaksgradA, dekningA, antvaksA,
  tab_sql
) 

invisible(DBI::dbExecute(conn = duckdb_con, statement = sql))

# RSYNT_PRE_FGLAGRING for Filgruppe: BEF_GKny
# Sist redigert av: VL 2026-17-08
# Hensikt:
# -Lager middelfolkemengde

dims <- khfunctions:::identify_nonvalues(khtools::duckdb_get_columns(duckdb_con, tablename))
dims_sql <- paste(khtools::sql_quote_I(duckdb_con, dims), collapse = ", ")
tbl_sql <- khtools::sql_quote_I(duckdb_con, tablename)
# Fjern BEF.a og BEF.f
sql <- paste0(sprintf('ALTER TABLE %s DROP COLUMN IF EXISTS %s', 
                      tbl_sql, 
                      khtools::sql_quote_I(duckdb_con, c("BEF.a", "BEF.f"))), collapse = ";\n")
invisible(DBI::dbExecute(duckdb_con, sql))

# Hent min/max år og max alder
aar_range <- DBI::dbGetQuery(duckdb_con, sprintf("SELECT MIN(AARl) AS aar_min, MAX(AARl) AS aar_max FROM %s", tbl_sql))
aar_min <- aar_range$aar_min
aar_max <- aar_range$aar_max
alder_max <- DBI::dbGetQuery(duckdb_con, sprintf("SELECT MAX(ALDERl) AS alder_max FROM %s", tbl_sql))$alder_max

# BEF_aggregering
sql_bef_grunnlag <- sprintf("SELECT %s, SUM(BEF) AS BEF FROM %s GROUP BY %s", dims_sql, tbl_sql, dims_sql)
khtools::duckdb_replace_existing_table(con = duckdb_con, target = tablename, select_sql = sql_bef_grunnlag)

# LEXIS
alder_plus1_sql <- paste(
  vapply(dims, function(x){
    if(x %in% c("ALDERl", "ALDERh")){
      sprintf("%s + 1 AS %s", khtools::sql_quote_I(duckdb_con, x), khtools::sql_quote_I(duckdb_con, x))
    } else {
      khtools::sql_quote_I(duckdb_con, x)
    }
  }, character(1)),
  collapse = ",\n      "
)

aar_alder_minus1_sql <- paste(
  vapply(dims, function(x){
    if(x %in% c("AARl", "AARh", "ALDERl", "ALDERh")){
      sprintf("%s - 1 AS %s", khtools::sql_quote_I(duckdb_con, x), khtools::sql_quote_I(duckdb_con, x))
    } else {
      khtools::sql_quote_I(duckdb_con, x)
    }
  }, character(1)),
  collapse = ",\n      "
)

aar_minus1_sql <- paste(
  vapply(dims, function(x){
    if(x %in% c("AARl", "AARh")){
      sprintf("%s - 1 AS %s", khtools::sql_quote_I(duckdb_con, x), khtools::sql_quote_I(duckdb_con, x))
    } else {
      khtools::sql_quote_I(duckdb_con, x)
    }
  }, character(1)),
  collapse = ",\n      "
)

sql_lexis <- sprintf(
  "SELECT %s,
    SUM(BEF) AS BEF0101,
    SUM(BEF_am1) AS BEF_am1,
    SUM(BEF3112a) AS BEF3112a,
    SUM(BEF3112c) AS BEF3112c
FROM (SELECT %s,
        BEF,
        CAST(0 AS DOUBLE) AS BEF_am1,
        CAST(0 AS DOUBLE) AS BEF3112a,
        CAST(0 AS DOUBLE) AS BEF3112c
      FROM %s

    UNION ALL

      SELECT %s,
        CAST(0 AS DOUBLE) AS BEF,
        BEF AS BEF_am1,
        CAST(0 AS DOUBLE) AS BEF3112a,
        CAST(0 AS DOUBLE) AS BEF3112c
      FROM %s WHERE ALDERh + 1 <= %s

    UNION ALL

      SELECT %s,
        CAST(0 AS DOUBLE) AS BEF,
        CAST(0 AS DOUBLE) AS BEF_am1,
        CAST(0 AS DOUBLE) AS BEF3112a,
        BEF AS BEF3112c
      FROM %s WHERE ALDERl - 1 >= 0 AND AARl - 1 >= %s

    UNION ALL

      SELECT %s, 
        CAST(0 AS DOUBLE) AS BEF,
        CAST(0 AS DOUBLE) AS BEF_am1,
        BEF AS BEF3112a,
        CAST(0 AS DOUBLE) AS BEF3112c
    FROM %s WHERE AARl - 1 >= %s
) x
GROUP BY %s",
  dims_sql, 
  dims_sql, tbl_sql,
  alder_plus1_sql, tbl_sql, alder_max,
  aar_alder_minus1_sql, tbl_sql, aar_min,
  aar_minus1_sql, tbl_sql, aar_min,
  dims_sql
)

khtools::duckdb_replace_existing_table(con = duckdb_con, target = tablename, select_sql = sql_lexis)

# Lage befvarianter
sql_befvarianter <- sprintf(
  "SELECT 
    %s, BEF0101,
    
    CASE 
      WHEN AARl = %s THEN CAST(NULL AS DOUBLE)
      ELSE BEF3112a
    END AS BEF3112a,

    CASE
      WHEN AARl = %s THEN CAST(NULL AS DOUBLE)
      ELSE BEF3112c
    END AS BEF3112c,

    CASE
      WHEN AARl = %s THEN CAST(NULL AS DOUBLE)
      WHEN ALDERl = 0 THEN 0.5 * BEF3112a
      ELSE 0.5 * BEF_am1 + 0.5 * BEF3112a
    END AS mBEFc,

    CASE
      WHEN AARl = %s THEN CAST(NULL AS DOUBLE)
      WHEN ALDERl = 0 THEN 0.5 * BEF3112a + (1.0/3.0) * BEF0101 + (1.0/6.0) * BEF3112c
      ELSE (1.0/6.0) * BEF_am1 + (1.0/3.0) * BEF3112a + (1.0/3.0) * BEF0101 + (1.0/6.0) * BEF3112c
    END AS mBEFa,

    0 AS \"BEF0101.f\",

    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS \"BEF3112a.f\",
    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS \"BEF3112c.f\",
    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS \"mBEFc.f\",
    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS \"mBEFa.f\",

    1 AS \"BEF0101.a\",
    1 AS \"BEF3112a.a\",
    1 AS \"BEF3112c.a\",
    1 AS \"mBEFc.a\",
    1 AS \"mBEFa.a\"
    
    FROM %s",
  dims_sql,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  tbl_sql
)

khtools::duckdb_replace_existing_table(con = duckdb_con, target = tablename, select_sql = sql_befvarianter)


# Gamle beregninger av personår-estimater for de tre rektanglene i Lexis-diagrammet (se Carstensen, ?????)
# Filgruppe[,LA:=1/3*BEF_am1+1/6*BEF_a_pp1]    # 1/3 * BEF_am1 + 1/6 BEF3112a 
# Filgruppe[,LB:=1/6*BEF_am1+1/3*BEF_a_pp1]    # 1/6 * BEF_am1 + 1/3 BEF3112a
# Filgruppe[,LC:=1/3*BEF+1/6*BEF_ap1_pp1] # 1/3*BEF + 1/6 * BEF3112c
# Filgruppe[ALDERl==0,LA:=0]
# Filgruppe[ALDERl==0,LB:=1/2*BEF_a_pp1] # 0.5 * BEF3112a
# #Beregner de to middelfolkemengdene
# Filgruppe[,mBEFc:=LA+LB]
# Filgruppe[,mBEFa:=LB+LC]

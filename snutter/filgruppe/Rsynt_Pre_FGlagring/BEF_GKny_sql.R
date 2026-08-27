# RSYNT_PRE_FGLAGRING for Filgruppe: BEF_GKny
# Sist redigert av: VL 2026-17-08
# Hensikt:
# -Lager middelfolkemengde

dims <- khfunctions:::get_dimension_columns(DBI::dbListFields(duckdb_con, tablename))
dims_sql <- paste(dims, collapse = ", ")
# Fjern BEF.a og BEF.f
sql <- paste0(sprintf('ALTER TABLE "%s" DROP COLUMN IF EXISTS "%s"',
                      tablename,
                      c("BEF.a", "BEF.f")),
              collapse = ";\n")
invisible(DBI::dbExecute(duckdb_con, sql))

# Hent max år
aar_max <- DBI::dbGetQuery(duckdb_con, sprintf("SELECT MAX(AARl) AS aar_max FROM %s", tablename))$aar_max

khfunctions:::print_console_message("\n - Aggregerer BEF")
# Første aggregering, lage sum av BEF for alle kombinasjoner av dims, lagres som mellomtabell bef_grunnlag
invisible(DBI::dbExecute(duckdb_con,
  sprintf('
  CREATE OR REPLACE TEMP TABLE bef_grunnlag AS SELECT %s, 
  SUM(BEF) AS BEF FROM %s 
  GROUP BY %s',
  dims_sql,
  tablename,
  dims_sql
  )
))

khfunctions:::print_console_message("\n - Lager grunnlag for BEF-varianter")
# Legge til forskjøvet BEF med tre selvjoins, lagres i mellomtabell bef_lexis
# am1/ap1 = alder minus/pluss 1
# aam1/aap1 = aar minus/pluss 1
join_base <- setdiff(dims, c("AARl", "AARh", "ALDERl", "ALDERh", "FYLKE", "GEOniv"))
join_base_sql <- paste(sprintf("b.%s = x.%s", join_base, join_base), collapse = "\n   AND ")
dims_b_sql <- paste0("b.", dims, collapse = ", ")

sql2 <- sprintf(
  'CREATE OR REPLACE TEMP TABLE bef_lexis AS
SELECT
    %s,
    b.BEF AS BEF0101,
    COALESCE(am1.BEF, 0)   AS BEF_am1,
    COALESCE(ap1aap1.BEF, 0) AS BEF3112c,
    COALESCE(aap1.BEF, 0)   AS BEF3112a
FROM bef_grunnlag b
LEFT JOIN bef_grunnlag am1
    ON %s
    AND am1.AARl   = b.AARl
    AND am1.ALDERl = b.ALDERl - 1
LEFT JOIN bef_grunnlag ap1aap1
    ON %s
    AND ap1aap1.AARl   = b.AARl + 1
    AND ap1aap1.ALDERl = b.ALDERl + 1
LEFT JOIN bef_grunnlag aap1
    ON %s
    AND aap1.AARl   = b.AARl + 1
    AND aap1.ALDERl = b.ALDERl',
  dims_b_sql,
  gsub("x\\.", "am1.", join_base_sql),
  gsub("x\\.", "ap1aap1.", join_base_sql),
  gsub("x\\.", "aap1.", join_base_sql)
)

invisible(DBI::dbExecute(duckdb_con, sql2))

khfunctions:::print_console_message("\n - Beregner ulike BEF-varianter")
# Beregne de ulike befolkningsvariantene, og sette siste år til NA for de ulike befolkningskolonnene utenom BEF0101
# Overskrive den originale tabellen.
sql3 <- sprintf(
  'CREATE OR REPLACE TABLE %s AS 
  SELECT
    %s,
    BEF0101,
    CASE WHEN AARl = %s THEN CAST(NULL AS DOUBLE) ELSE BEF3112a END AS BEF3112a,
    CASE WHEN AARl = %s THEN CAST(NULL AS DOUBLE) ELSE BEF3112c END AS BEF3112c,
    CASE
        WHEN AARl = %s THEN CAST(NULL AS DOUBLE)
        WHEN ALDERl = 0 
        THEN 0.5 * BEF3112a
        ELSE 0.5 * BEF_am1 + 0.5 * BEF3112a
    END AS mBEFc,

    CASE
        WHEN AARl = %s THEN CAST(NULL AS DOUBLE)
        WHEN ALDERl = 0 THEN
            0.5 * BEF3112a + 
            (1.0/3.0) * BEF0101 + 
            (1.0/6.0) * BEF3112c
        ELSE
            (1.0/6.0) * BEF_am1 +
            (1.0/3.0) * BEF3112a +
            (1.0/3.0) * BEF0101 +
            (1.0/6.0) * BEF3112c
    END AS mBEFa,

    0 AS "BEF0101.f",
    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS "BEF3112a.f",
    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS "BEF3112c.f",
    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS "mBEFc.f",
    CASE WHEN AARl = %s THEN 2 ELSE 0 END AS "mBEFa.f",

    1 AS "BEF0101.a",
    1 AS "BEF3112a.a",
    1 AS "BEF3112c.a",
    1 AS "mBEFc.a",
    1 AS "mBEFa.a"

  FROM bef_lexis',
  tablename,
  dims_sql,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max,
  aar_max
)

invisible(DBI::dbExecute(duckdb_con, sql3))


# Gamle beregninger av personår-estimater for de tre rektanglene i Lexis-diagrammet (se Carstensen, ?????)
# Filgruppe[,LA:=1/3*BEF_am1+1/6*BEF_a_pp1]    # 1/3 * BEF_am1 + 1/6 BEF3112a 
# Filgruppe[,LB:=1/6*BEF_am1+1/3*BEF_a_pp1]    # 1/6 * BEF_am1 + 1/3 BEF3112a
# Filgruppe[,LC:=1/3*BEF+1/6*BEF_ap1_pp1] # 1/3*BEF + 1/6 * BEF3112c
# Filgruppe[ALDERl==0,LA:=0]
# Filgruppe[ALDERl==0,LB:=1/2*BEF_a_pp1] # 0.5 * BEF3112a
# #Beregner de to middelfolkemengdene
# Filgruppe[,mBEFc:=LA+LB]
# Filgruppe[,mBEFa:=LB+LC]
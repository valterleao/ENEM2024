-- Script: 05_criar_tabelas_powerbi.sql
-- Objetivo: criar tabelas fisicas e agregadas para importacao estavel no Power BI.
-- Use estas tabelas no Power BI quando a importacao direta das views do schema olap falhar.

CREATE SCHEMA IF NOT EXISTS powerbi;

DROP TABLE IF EXISTS powerbi.pb_01_desempenho_estado_regiao;
CREATE TABLE powerbi.pb_01_desempenho_estado_regiao AS
SELECT * FROM olap.vw_01_desempenho_estado_regiao;

DROP TABLE IF EXISTS powerbi.pb_02_desempenho_faixa_socioeconomica;
CREATE TABLE powerbi.pb_02_desempenho_faixa_socioeconomica AS
SELECT * FROM olap.vw_02_desempenho_faixa_socioeconomica;

DROP TABLE IF EXISTS powerbi.pb_03_top_redacoes_localidade;
CREATE TABLE powerbi.pb_03_top_redacoes_localidade AS
SELECT *
FROM olap.vw_03_maiores_redacoes_localidade
WHERE ranking_no_municipio <= 10;

DROP TABLE IF EXISTS powerbi.pb_04_top_notas_area_geografica;
CREATE TABLE powerbi.pb_04_top_notas_area_geografica AS
SELECT *
FROM olap.vw_04_maiores_notas_area_geografica
WHERE ranking_area <= 1000;

DROP TABLE IF EXISTS powerbi.pb_05_notas_genero_socioeconomica;
CREATE TABLE powerbi.pb_05_notas_genero_socioeconomica AS
SELECT * FROM olap.vw_05_notas_genero_socioeconomica;

DROP TABLE IF EXISTS powerbi.pb_06_notas_faixa_etaria;
CREATE TABLE powerbi.pb_06_notas_faixa_etaria AS
SELECT * FROM olap.vw_06_notas_faixa_etaria;

DROP TABLE IF EXISTS powerbi.pb_07_notas_raca_cor;
CREATE TABLE powerbi.pb_07_notas_raca_cor AS
SELECT * FROM olap.vw_07_notas_raca_cor;

DROP TABLE IF EXISTS powerbi.pb_08_capital_interior;
CREATE TABLE powerbi.pb_08_capital_interior AS
SELECT * FROM olap.vw_08_capital_interior;

DROP TABLE IF EXISTS powerbi.pb_09_genero_por_area;
CREATE TABLE powerbi.pb_09_genero_por_area AS
SELECT * FROM olap.vw_09_genero_por_area;

DROP TABLE IF EXISTS powerbi.pb_10_rede_escola_por_area;
CREATE TABLE powerbi.pb_10_rede_escola_por_area AS
SELECT * FROM olap.vw_10_rede_escola_por_area;

CREATE INDEX IF NOT EXISTS ix_pb_01_uf ON powerbi.pb_01_desempenho_estado_regiao (uf);
CREATE INDEX IF NOT EXISTS ix_pb_02_faixa ON powerbi.pb_02_desempenho_faixa_socioeconomica (faixa_socioeconomica);
CREATE INDEX IF NOT EXISTS ix_pb_03_uf_municipio ON powerbi.pb_03_top_redacoes_localidade (uf, municipio);
CREATE INDEX IF NOT EXISTS ix_pb_04_area ON powerbi.pb_04_top_notas_area_geografica (area_conhecimento);
CREATE INDEX IF NOT EXISTS ix_pb_05_genero_faixa ON powerbi.pb_05_notas_genero_socioeconomica (sexo, faixa_socioeconomica);
CREATE INDEX IF NOT EXISTS ix_pb_06_faixa ON powerbi.pb_06_notas_faixa_etaria (cod_faixa_etaria);
CREATE INDEX IF NOT EXISTS ix_pb_07_raca ON powerbi.pb_07_notas_raca_cor (cod_cor_raca);
CREATE INDEX IF NOT EXISTS ix_pb_08_capital ON powerbi.pb_08_capital_interior (capital_interior);
CREATE INDEX IF NOT EXISTS ix_pb_09_genero ON powerbi.pb_09_genero_por_area (sexo);
CREATE INDEX IF NOT EXISTS ix_pb_10_rede ON powerbi.pb_10_rede_escola_por_area (rede_escola);

ANALYZE powerbi.pb_01_desempenho_estado_regiao;
ANALYZE powerbi.pb_02_desempenho_faixa_socioeconomica;
ANALYZE powerbi.pb_03_top_redacoes_localidade;
ANALYZE powerbi.pb_04_top_notas_area_geografica;
ANALYZE powerbi.pb_05_notas_genero_socioeconomica;
ANALYZE powerbi.pb_06_notas_faixa_etaria;
ANALYZE powerbi.pb_07_notas_raca_cor;
ANALYZE powerbi.pb_08_capital_interior;
ANALYZE powerbi.pb_09_genero_por_area;
ANALYZE powerbi.pb_10_rede_escola_por_area;

SELECT 'pb_01_desempenho_estado_regiao' AS tabela, COUNT(*) AS linhas FROM powerbi.pb_01_desempenho_estado_regiao
UNION ALL SELECT 'pb_02_desempenho_faixa_socioeconomica', COUNT(*) FROM powerbi.pb_02_desempenho_faixa_socioeconomica
UNION ALL SELECT 'pb_03_top_redacoes_localidade', COUNT(*) FROM powerbi.pb_03_top_redacoes_localidade
UNION ALL SELECT 'pb_04_top_notas_area_geografica', COUNT(*) FROM powerbi.pb_04_top_notas_area_geografica
UNION ALL SELECT 'pb_05_notas_genero_socioeconomica', COUNT(*) FROM powerbi.pb_05_notas_genero_socioeconomica
UNION ALL SELECT 'pb_06_notas_faixa_etaria', COUNT(*) FROM powerbi.pb_06_notas_faixa_etaria
UNION ALL SELECT 'pb_07_notas_raca_cor', COUNT(*) FROM powerbi.pb_07_notas_raca_cor
UNION ALL SELECT 'pb_08_capital_interior', COUNT(*) FROM powerbi.pb_08_capital_interior
UNION ALL SELECT 'pb_09_genero_por_area', COUNT(*) FROM powerbi.pb_09_genero_por_area
UNION ALL SELECT 'pb_10_rede_escola_por_area', COUNT(*) FROM powerbi.pb_10_rede_escola_por_area
ORDER BY tabela;


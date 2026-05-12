-- Script: 02_carregar_staging.sql
-- Objetivo: carregar os CSVs originais do ENEM 2024 no schema staging.
-- Execucao sugerida:
--   psql -h localhost -d ENEM2024 -U postgres -f sql/01_criar_staging.sql
--   psql -h localhost -d ENEM2024 -U postgres -f sql/02_carregar_staging.sql

TRUNCATE TABLE staging.stg_participantes_2024 RESTART IDENTITY;
TRUNCATE TABLE staging.stg_resultados_2024 RESTART IDENTITY;

SET client_encoding TO 'LATIN1';

\copy staging.stg_participantes_2024 (nu_inscricao, nu_ano, tp_faixa_etaria, tp_sexo, tp_estado_civil, tp_cor_raca, tp_nacionalidade, tp_st_conclusao, tp_ano_concluiu, tp_ensino, in_treineiro, co_municipio_prova, no_municipio_prova, co_uf_prova, sg_uf_prova, q001, q002, q003, q004, q005, q006, q007, q008, q009, q010, q011, q012, q013, q014, q015, q016, q017, q018, q019, q020, q021, q022, q023) FROM 'H:/UNI7/SAD-Lina/AV2-TRABALHO-1-ENEM/microdados_enem_2024/DADOS/PARTICIPANTES_2024.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

\copy staging.stg_resultados_2024 (nu_sequencial, nu_ano, co_escola, co_municipio_esc, no_municipio_esc, co_uf_esc, sg_uf_esc, tp_dependencia_adm_esc, tp_localizacao_esc, tp_sit_func_esc, co_municipio_prova, no_municipio_prova, co_uf_prova, sg_uf_prova, tp_presenca_cn, tp_presenca_ch, tp_presenca_lc, tp_presenca_mt, co_prova_cn, co_prova_ch, co_prova_lc, co_prova_mt, nu_nota_cn, nu_nota_ch, nu_nota_lc, nu_nota_mt, tx_respostas_cn, tx_respostas_ch, tx_respostas_lc, tx_respostas_mt, tp_lingua, tx_gabarito_cn, tx_gabarito_ch, tx_gabarito_lc, tx_gabarito_mt, tp_status_redacao, nu_nota_comp1, nu_nota_comp2, nu_nota_comp3, nu_nota_comp4, nu_nota_comp5, nu_nota_redacao) FROM 'H:/UNI7/SAD-Lina/AV2-TRABALHO-1-ENEM/microdados_enem_2024/DADOS/RESULTADOS_2024.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

RESET client_encoding;

ANALYZE staging.stg_participantes_2024;
ANALYZE staging.stg_resultados_2024;

SELECT
    (SELECT COUNT(*) FROM staging.stg_participantes_2024) AS qtd_participantes,
    (SELECT COUNT(*) FROM staging.stg_resultados_2024) AS qtd_resultados;


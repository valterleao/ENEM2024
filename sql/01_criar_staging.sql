-- Script: 01_criar_staging.sql
-- Objetivo: criar a area de staging para os arquivos brutos do ENEM 2024.
-- Banco alvo: PostgreSQL local, base ENEM2024.

CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.stg_participantes_2024;
CREATE TABLE staging.stg_participantes_2024 (
    id_carga BIGSERIAL PRIMARY KEY,
    nu_inscricao TEXT,
    nu_ano TEXT,
    tp_faixa_etaria TEXT,
    tp_sexo TEXT,
    tp_estado_civil TEXT,
    tp_cor_raca TEXT,
    tp_nacionalidade TEXT,
    tp_st_conclusao TEXT,
    tp_ano_concluiu TEXT,
    tp_ensino TEXT,
    in_treineiro TEXT,
    co_municipio_prova TEXT,
    no_municipio_prova TEXT,
    co_uf_prova TEXT,
    sg_uf_prova TEXT,
    q001 TEXT,
    q002 TEXT,
    q003 TEXT,
    q004 TEXT,
    q005 TEXT,
    q006 TEXT,
    q007 TEXT,
    q008 TEXT,
    q009 TEXT,
    q010 TEXT,
    q011 TEXT,
    q012 TEXT,
    q013 TEXT,
    q014 TEXT,
    q015 TEXT,
    q016 TEXT,
    q017 TEXT,
    q018 TEXT,
    q019 TEXT,
    q020 TEXT,
    q021 TEXT,
    q022 TEXT,
    q023 TEXT
);

DROP TABLE IF EXISTS staging.stg_resultados_2024;
CREATE TABLE staging.stg_resultados_2024 (
    id_carga BIGSERIAL PRIMARY KEY,
    nu_sequencial TEXT,
    nu_ano TEXT,
    co_escola TEXT,
    co_municipio_esc TEXT,
    no_municipio_esc TEXT,
    co_uf_esc TEXT,
    sg_uf_esc TEXT,
    tp_dependencia_adm_esc TEXT,
    tp_localizacao_esc TEXT,
    tp_sit_func_esc TEXT,
    co_municipio_prova TEXT,
    no_municipio_prova TEXT,
    co_uf_prova TEXT,
    sg_uf_prova TEXT,
    tp_presenca_cn TEXT,
    tp_presenca_ch TEXT,
    tp_presenca_lc TEXT,
    tp_presenca_mt TEXT,
    co_prova_cn TEXT,
    co_prova_ch TEXT,
    co_prova_lc TEXT,
    co_prova_mt TEXT,
    nu_nota_cn TEXT,
    nu_nota_ch TEXT,
    nu_nota_lc TEXT,
    nu_nota_mt TEXT,
    tx_respostas_cn TEXT,
    tx_respostas_ch TEXT,
    tx_respostas_lc TEXT,
    tx_respostas_mt TEXT,
    tp_lingua TEXT,
    tx_gabarito_cn TEXT,
    tx_gabarito_ch TEXT,
    tx_gabarito_lc TEXT,
    tx_gabarito_mt TEXT,
    tp_status_redacao TEXT,
    nu_nota_comp1 TEXT,
    nu_nota_comp2 TEXT,
    nu_nota_comp3 TEXT,
    nu_nota_comp4 TEXT,
    nu_nota_comp5 TEXT,
    nu_nota_redacao TEXT
);

CREATE INDEX IF NOT EXISTS ix_stg_participantes_id_carga
    ON staging.stg_participantes_2024 (id_carga);

CREATE INDEX IF NOT EXISTS ix_stg_resultados_nu_sequencial
    ON staging.stg_resultados_2024 ((NULLIF(nu_sequencial, '')::BIGINT));


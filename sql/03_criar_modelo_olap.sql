-- Script: 03_criar_modelo_olap.sql
-- Objetivo: transformar os dados de staging em um modelo estrela OLAP.

CREATE SCHEMA IF NOT EXISTS olap;

CREATE OR REPLACE FUNCTION olap.to_numeric_br(valor TEXT)
RETURNS NUMERIC
LANGUAGE SQL
IMMUTABLE
AS $$
    SELECT NULLIF(REPLACE(TRIM(valor), ',', '.'), '')::NUMERIC;
$$;

DROP TABLE IF EXISTS olap.fato_desempenho_enem CASCADE;
DROP TABLE IF EXISTS olap.dim_prova CASCADE;
DROP TABLE IF EXISTS olap.dim_escola CASCADE;
DROP TABLE IF EXISTS olap.dim_socioeconomica CASCADE;
DROP TABLE IF EXISTS olap.dim_localidade CASCADE;
DROP TABLE IF EXISTS olap.dim_participante CASCADE;

CREATE TABLE olap.dim_participante AS
SELECT
    ROW_NUMBER() OVER (ORDER BY p.id_carga)::INTEGER AS id_participante,
    p.id_carga,
    p.nu_inscricao,
    NULLIF(p.nu_ano, '')::INTEGER AS ano_enem,
    NULLIF(p.tp_faixa_etaria, '')::INTEGER AS cod_faixa_etaria,
    CASE p.tp_faixa_etaria
        WHEN '1' THEN 'Menor de 17 anos'
        WHEN '2' THEN '17 anos'
        WHEN '3' THEN '18 anos'
        WHEN '4' THEN '19 anos'
        WHEN '5' THEN '20 anos'
        WHEN '6' THEN '21 anos'
        WHEN '7' THEN '22 anos'
        WHEN '8' THEN '23 anos'
        WHEN '9' THEN '24 anos'
        WHEN '10' THEN '25 anos'
        WHEN '11' THEN 'Entre 26 e 30 anos'
        WHEN '12' THEN 'Entre 31 e 35 anos'
        WHEN '13' THEN 'Entre 36 e 40 anos'
        WHEN '14' THEN 'Entre 41 e 45 anos'
        WHEN '15' THEN 'Entre 46 e 50 anos'
        WHEN '16' THEN 'Entre 51 e 55 anos'
        WHEN '17' THEN 'Entre 56 e 60 anos'
        WHEN '18' THEN 'Entre 61 e 65 anos'
        WHEN '19' THEN 'Entre 66 e 70 anos'
        WHEN '20' THEN 'Maior de 70 anos'
        ELSE 'Nao informado'
    END AS faixa_etaria,
    p.tp_sexo AS cod_sexo,
    CASE p.tp_sexo WHEN 'M' THEN 'Masculino' WHEN 'F' THEN 'Feminino' ELSE 'Nao informado' END AS sexo,
    NULLIF(p.tp_estado_civil, '')::INTEGER AS cod_estado_civil,
    CASE p.tp_estado_civil
        WHEN '0' THEN 'Nao informado'
        WHEN '1' THEN 'Solteiro(a)'
        WHEN '2' THEN 'Casado(a)/Mora com companheiro(a)'
        WHEN '3' THEN 'Divorciado(a)/Separado(a)'
        WHEN '4' THEN 'Viuvo(a)'
        ELSE 'Nao informado'
    END AS estado_civil,
    NULLIF(p.tp_cor_raca, '')::INTEGER AS cod_cor_raca,
    CASE p.tp_cor_raca
        WHEN '0' THEN 'Nao declarado'
        WHEN '1' THEN 'Branca'
        WHEN '2' THEN 'Preta'
        WHEN '3' THEN 'Parda'
        WHEN '4' THEN 'Amarela'
        WHEN '5' THEN 'Indigena'
        WHEN '6' THEN 'Nao dispoe da informacao'
        ELSE 'Nao informado'
    END AS cor_raca,
    NULLIF(p.tp_nacionalidade, '')::INTEGER AS cod_nacionalidade,
    CASE p.tp_nacionalidade
        WHEN '0' THEN 'Nao informado'
        WHEN '1' THEN 'Brasileiro(a)'
        WHEN '2' THEN 'Brasileiro(a) naturalizado(a)'
        WHEN '3' THEN 'Estrangeiro(a)'
        WHEN '4' THEN 'Brasileiro(a) nato(a), nascido(a) no exterior'
        ELSE 'Nao informado'
    END AS nacionalidade,
    NULLIF(p.tp_st_conclusao, '')::INTEGER AS cod_status_conclusao_em,
    CASE p.tp_st_conclusao
        WHEN '1' THEN 'Ja concluiu o Ensino Medio'
        WHEN '2' THEN 'Concluira o Ensino Medio em 2024'
        WHEN '3' THEN 'Concluira o Ensino Medio apos 2024'
        WHEN '4' THEN 'Nao concluiu e nao esta cursando'
        ELSE 'Nao informado'
    END AS status_conclusao_em,
    NULLIF(p.tp_ensino, '')::INTEGER AS cod_tipo_ensino,
    CASE p.tp_ensino
        WHEN '1' THEN 'Ensino Regular'
        WHEN '2' THEN 'Educacao Especial - Modalidade Substitutiva'
        ELSE 'Nao informado'
    END AS tipo_ensino,
    NULLIF(p.in_treineiro, '')::INTEGER AS cod_treineiro,
    CASE p.in_treineiro WHEN '0' THEN 'Nao' WHEN '1' THEN 'Sim' ELSE 'Nao informado' END AS treineiro
FROM staging.stg_participantes_2024 p;

ALTER TABLE olap.dim_participante ADD CONSTRAINT pk_dim_participante PRIMARY KEY (id_participante);
CREATE UNIQUE INDEX ux_dim_participante_id_carga ON olap.dim_participante (id_carga);

CREATE TABLE olap.dim_localidade AS
WITH localidades AS (
    SELECT DISTINCT
        NULLIF(co_municipio_prova, '') AS co_municipio_prova,
        NULLIF(no_municipio_prova, '') AS no_municipio_prova,
        NULLIF(co_uf_prova, '') AS co_uf_prova,
        NULLIF(sg_uf_prova, '') AS sg_uf_prova
    FROM staging.stg_participantes_2024
    UNION
    SELECT DISTINCT
        NULLIF(co_municipio_prova, '') AS co_municipio_prova,
        NULLIF(no_municipio_prova, '') AS no_municipio_prova,
        NULLIF(co_uf_prova, '') AS co_uf_prova,
        NULLIF(sg_uf_prova, '') AS sg_uf_prova
    FROM staging.stg_resultados_2024
)
SELECT
    ROW_NUMBER() OVER (ORDER BY sg_uf_prova, no_municipio_prova, co_municipio_prova)::INTEGER AS id_localidade,
    md5(concat_ws('|', COALESCE(co_municipio_prova, ''), COALESCE(co_uf_prova, ''))) AS chave_localidade,
    co_municipio_prova,
    no_municipio_prova,
    co_uf_prova,
    sg_uf_prova,
    CASE sg_uf_prova
        WHEN 'AC' THEN 'Norte' WHEN 'AP' THEN 'Norte' WHEN 'AM' THEN 'Norte'
        WHEN 'PA' THEN 'Norte' WHEN 'RO' THEN 'Norte' WHEN 'RR' THEN 'Norte'
        WHEN 'TO' THEN 'Norte'
        WHEN 'AL' THEN 'Nordeste' WHEN 'BA' THEN 'Nordeste' WHEN 'CE' THEN 'Nordeste'
        WHEN 'MA' THEN 'Nordeste' WHEN 'PB' THEN 'Nordeste' WHEN 'PE' THEN 'Nordeste'
        WHEN 'PI' THEN 'Nordeste' WHEN 'RN' THEN 'Nordeste' WHEN 'SE' THEN 'Nordeste'
        WHEN 'DF' THEN 'Centro-Oeste' WHEN 'GO' THEN 'Centro-Oeste'
        WHEN 'MT' THEN 'Centro-Oeste' WHEN 'MS' THEN 'Centro-Oeste'
        WHEN 'ES' THEN 'Sudeste' WHEN 'MG' THEN 'Sudeste' WHEN 'RJ' THEN 'Sudeste'
        WHEN 'SP' THEN 'Sudeste'
        WHEN 'PR' THEN 'Sul' WHEN 'RS' THEN 'Sul' WHEN 'SC' THEN 'Sul'
        ELSE 'Nao informado'
    END AS regiao,
    CASE co_municipio_prova
        WHEN '1100205' THEN 'Capital' WHEN '1200401' THEN 'Capital' WHEN '1302603' THEN 'Capital'
        WHEN '1400100' THEN 'Capital' WHEN '1501402' THEN 'Capital' WHEN '1600303' THEN 'Capital'
        WHEN '1721000' THEN 'Capital' WHEN '2111300' THEN 'Capital' WHEN '2211001' THEN 'Capital'
        WHEN '2304400' THEN 'Capital' WHEN '2408102' THEN 'Capital' WHEN '2507507' THEN 'Capital'
        WHEN '2611606' THEN 'Capital' WHEN '2704302' THEN 'Capital' WHEN '2800308' THEN 'Capital'
        WHEN '2927408' THEN 'Capital' WHEN '3106200' THEN 'Capital' WHEN '3205309' THEN 'Capital'
        WHEN '3304557' THEN 'Capital' WHEN '3550308' THEN 'Capital' WHEN '4106902' THEN 'Capital'
        WHEN '4205407' THEN 'Capital' WHEN '4314902' THEN 'Capital' WHEN '5002704' THEN 'Capital'
        WHEN '5103403' THEN 'Capital' WHEN '5208707' THEN 'Capital' WHEN '5300108' THEN 'Capital'
        ELSE 'Interior'
    END AS capital_interior
FROM localidades;

ALTER TABLE olap.dim_localidade ADD CONSTRAINT pk_dim_localidade PRIMARY KEY (id_localidade);
CREATE INDEX ix_dim_localidade_natural ON olap.dim_localidade (co_municipio_prova, co_uf_prova);
CREATE UNIQUE INDEX ux_dim_localidade_chave ON olap.dim_localidade (chave_localidade);

CREATE TABLE olap.dim_socioeconomica AS
SELECT
    ROW_NUMBER() OVER (ORDER BY id_carga)::INTEGER AS id_socioeconomica,
    id_carga,
    q001 AS cod_escolaridade_pai,
    q002 AS cod_escolaridade_mae,
    q003 AS cod_ocupacao_pai,
    q004 AS cod_ocupacao_mae,
    NULLIF(q005, '')::INTEGER AS pessoas_residencia,
    q006 AS cod_possui_renda,
    q007 AS cod_renda_familiar,
    CASE q007
        WHEN 'A' THEN 'Nenhuma renda'
        WHEN 'B' THEN 'Ate R$ 1.412,00'
        WHEN 'C' THEN 'De R$ 1.412,01 ate R$ 2.118,00'
        WHEN 'D' THEN 'De R$ 2.118,01 ate R$ 2.824,00'
        WHEN 'E' THEN 'De R$ 2.824,01 ate R$ 3.530,00'
        WHEN 'F' THEN 'De R$ 3.530,01 ate R$ 4.236,00'
        WHEN 'G' THEN 'De R$ 4.236,01 ate R$ 5.648,00'
        WHEN 'H' THEN 'De R$ 5.648,01 ate R$ 7.060,00'
        WHEN 'I' THEN 'De R$ 7.060,01 ate R$ 8.472,00'
        WHEN 'J' THEN 'De R$ 8.472,01 ate R$ 9.884,00'
        WHEN 'K' THEN 'De R$ 9.884,01 ate R$ 11.296,00'
        WHEN 'L' THEN 'De R$ 11.296,01 ate R$ 12.708,00'
        WHEN 'M' THEN 'De R$ 12.708,01 ate R$ 14.120,00'
        WHEN 'N' THEN 'De R$ 14.120,01 ate R$ 16.944,00'
        WHEN 'O' THEN 'De R$ 16.944,01 ate R$ 21.180,00'
        WHEN 'P' THEN 'De R$ 21.180,01 ate R$ 28.240,00'
        WHEN 'Q' THEN 'Acima de R$ 28.240,00'
        ELSE 'Nao informado'
    END AS renda_familiar,
    CASE
        WHEN q007 IN ('A', 'B') THEN 'Muito baixa'
        WHEN q007 IN ('C', 'D', 'E', 'F', 'G') THEN 'Baixa'
        WHEN q007 IN ('H', 'I', 'J', 'K', 'L', 'M') THEN 'Media'
        WHEN q007 IN ('N', 'O', 'P', 'Q') THEN 'Alta'
        ELSE 'Nao informado'
    END AS faixa_socioeconomica,
    CASE q023
        WHEN 'A' THEN 'Somente escola publica'
        WHEN 'B' THEN 'Publica e privada sem bolsa integral'
        WHEN 'C' THEN 'Publica e privada com bolsa integral'
        WHEN 'D' THEN 'Somente escola privada sem bolsa integral'
        WHEN 'E' THEN 'Somente escola privada com bolsa integral'
        WHEN 'F' THEN 'Nao frequentou escola de Ensino Medio'
        ELSE 'Nao informado'
    END AS tipo_escola_em,
    q008, q009, q010, q011, q012, q013, q014, q015, q016, q017, q018, q019, q020, q021, q022
FROM staging.stg_participantes_2024;

ALTER TABLE olap.dim_socioeconomica ADD CONSTRAINT pk_dim_socioeconomica PRIMARY KEY (id_socioeconomica);
CREATE UNIQUE INDEX ux_dim_socioeconomica_id_carga ON olap.dim_socioeconomica (id_carga);

CREATE TABLE olap.dim_escola AS
WITH escolas AS (
    SELECT DISTINCT
        NULLIF(co_escola, '') AS co_escola,
        NULLIF(co_municipio_esc, '') AS co_municipio_esc,
        NULLIF(no_municipio_esc, '') AS no_municipio_esc,
        NULLIF(co_uf_esc, '') AS co_uf_esc,
        NULLIF(sg_uf_esc, '') AS sg_uf_esc,
        NULLIF(tp_dependencia_adm_esc, '') AS tp_dependencia_adm_esc,
        NULLIF(tp_localizacao_esc, '') AS tp_localizacao_esc,
        NULLIF(tp_sit_func_esc, '') AS tp_sit_func_esc
    FROM staging.stg_resultados_2024
)
SELECT
    ROW_NUMBER() OVER (ORDER BY co_escola, co_municipio_esc, tp_dependencia_adm_esc)::INTEGER AS id_escola,
    md5(concat_ws('|',
        COALESCE(co_escola, ''),
        COALESCE(co_municipio_esc, ''),
        COALESCE(tp_dependencia_adm_esc, ''),
        COALESCE(tp_localizacao_esc, ''),
        COALESCE(tp_sit_func_esc, '')
    )) AS chave_escola,
    co_escola,
    co_municipio_esc,
    no_municipio_esc,
    co_uf_esc,
    sg_uf_esc,
    NULLIF(tp_dependencia_adm_esc, '')::INTEGER AS cod_dependencia_adm,
    CASE tp_dependencia_adm_esc
        WHEN '1' THEN 'Federal'
        WHEN '2' THEN 'Estadual'
        WHEN '3' THEN 'Municipal'
        WHEN '4' THEN 'Privada'
        ELSE 'Nao informado'
    END AS dependencia_administrativa,
    CASE
        WHEN tp_dependencia_adm_esc IN ('1', '2', '3') THEN 'Publica'
        WHEN tp_dependencia_adm_esc = '4' THEN 'Privada'
        ELSE 'Nao informado'
    END AS rede_escola,
    NULLIF(tp_localizacao_esc, '')::INTEGER AS cod_localizacao_escola,
    CASE tp_localizacao_esc WHEN '1' THEN 'Urbana' WHEN '2' THEN 'Rural' ELSE 'Nao informado' END AS localizacao_escola,
    NULLIF(tp_sit_func_esc, '')::INTEGER AS cod_situacao_funcionamento,
    CASE tp_sit_func_esc
        WHEN '1' THEN 'Em atividade'
        WHEN '2' THEN 'Paralisada'
        WHEN '3' THEN 'Extinta'
        WHEN '4' THEN 'Escola extinta em anos anteriores'
        ELSE 'Nao informado'
    END AS situacao_funcionamento
FROM escolas;

ALTER TABLE olap.dim_escola ADD CONSTRAINT pk_dim_escola PRIMARY KEY (id_escola);
CREATE INDEX ix_dim_escola_natural ON olap.dim_escola (co_escola, co_municipio_esc);
CREATE UNIQUE INDEX ux_dim_escola_chave ON olap.dim_escola (chave_escola);

CREATE TABLE olap.dim_prova AS
WITH provas AS (
    SELECT DISTINCT
        tp_presenca_cn, tp_presenca_ch, tp_presenca_lc, tp_presenca_mt,
        co_prova_cn, co_prova_ch, co_prova_lc, co_prova_mt,
        tp_lingua, tp_status_redacao
    FROM staging.stg_resultados_2024
)
SELECT
    ROW_NUMBER() OVER (
        ORDER BY tp_presenca_cn, tp_presenca_ch, tp_presenca_lc, tp_presenca_mt,
                 co_prova_cn, co_prova_ch, co_prova_lc, co_prova_mt, tp_lingua, tp_status_redacao
    )::INTEGER AS id_prova,
    md5(concat_ws('|',
        COALESCE(tp_presenca_cn, ''),
        COALESCE(tp_presenca_ch, ''),
        COALESCE(tp_presenca_lc, ''),
        COALESCE(tp_presenca_mt, ''),
        COALESCE(co_prova_cn, ''),
        COALESCE(co_prova_ch, ''),
        COALESCE(co_prova_lc, ''),
        COALESCE(co_prova_mt, ''),
        COALESCE(tp_lingua, ''),
        COALESCE(tp_status_redacao, '')
    )) AS chave_prova,
    NULLIF(tp_presenca_cn, '')::INTEGER AS cod_presenca_cn,
    NULLIF(tp_presenca_ch, '')::INTEGER AS cod_presenca_ch,
    NULLIF(tp_presenca_lc, '')::INTEGER AS cod_presenca_lc,
    NULLIF(tp_presenca_mt, '')::INTEGER AS cod_presenca_mt,
    CASE tp_presenca_cn WHEN '0' THEN 'Faltou' WHEN '1' THEN 'Presente' WHEN '2' THEN 'Eliminado' ELSE 'Nao informado' END AS presenca_cn,
    CASE tp_presenca_ch WHEN '0' THEN 'Faltou' WHEN '1' THEN 'Presente' WHEN '2' THEN 'Eliminado' ELSE 'Nao informado' END AS presenca_ch,
    CASE tp_presenca_lc WHEN '0' THEN 'Faltou' WHEN '1' THEN 'Presente' WHEN '2' THEN 'Eliminado' ELSE 'Nao informado' END AS presenca_lc,
    CASE tp_presenca_mt WHEN '0' THEN 'Faltou' WHEN '1' THEN 'Presente' WHEN '2' THEN 'Eliminado' ELSE 'Nao informado' END AS presenca_mt,
    NULLIF(co_prova_cn, '')::INTEGER AS co_prova_cn,
    NULLIF(co_prova_ch, '')::INTEGER AS co_prova_ch,
    NULLIF(co_prova_lc, '')::INTEGER AS co_prova_lc,
    NULLIF(co_prova_mt, '')::INTEGER AS co_prova_mt,
    NULLIF(tp_lingua, '')::INTEGER AS cod_lingua,
    CASE tp_lingua WHEN '0' THEN 'Ingles' WHEN '1' THEN 'Espanhol' ELSE 'Nao informado' END AS lingua,
    NULLIF(tp_status_redacao, '')::INTEGER AS cod_status_redacao,
    CASE tp_status_redacao
        WHEN '1' THEN 'Sem problemas'
        WHEN '2' THEN 'Anulada'
        WHEN '3' THEN 'Copia texto motivador'
        WHEN '4' THEN 'Em branco'
        WHEN '6' THEN 'Fuga ao tema'
        WHEN '7' THEN 'Nao atendimento ao tipo textual'
        WHEN '8' THEN 'Texto insuficiente'
        WHEN '9' THEN 'Parte desconectada'
        ELSE 'Nao informado'
    END AS status_redacao
FROM provas;

ALTER TABLE olap.dim_prova ADD CONSTRAINT pk_dim_prova PRIMARY KEY (id_prova);
CREATE UNIQUE INDEX ux_dim_prova_chave ON olap.dim_prova (chave_prova);

CREATE TABLE olap.fato_desempenho_enem AS
WITH base AS (
    SELECT
        p.id_carga,
        p.nu_inscricao,
        r.nu_sequencial,
        olap.to_numeric_br(r.nu_nota_cn) AS nota_cn,
        olap.to_numeric_br(r.nu_nota_ch) AS nota_ch,
        olap.to_numeric_br(r.nu_nota_lc) AS nota_lc,
        olap.to_numeric_br(r.nu_nota_mt) AS nota_mt,
        olap.to_numeric_br(r.nu_nota_redacao) AS nota_redacao,
        olap.to_numeric_br(r.nu_nota_comp1) AS nota_comp1,
        olap.to_numeric_br(r.nu_nota_comp2) AS nota_comp2,
        olap.to_numeric_br(r.nu_nota_comp3) AS nota_comp3,
        olap.to_numeric_br(r.nu_nota_comp4) AS nota_comp4,
        olap.to_numeric_br(r.nu_nota_comp5) AS nota_comp5,
        p.co_municipio_prova AS p_co_municipio_prova,
        p.co_uf_prova AS p_co_uf_prova,
        md5(concat_ws('|', COALESCE(NULLIF(p.co_municipio_prova, ''), ''), COALESCE(NULLIF(p.co_uf_prova, ''), ''))) AS chave_localidade,
        md5(concat_ws('|',
            COALESCE(NULLIF(r.co_escola, ''), ''),
            COALESCE(NULLIF(r.co_municipio_esc, ''), ''),
            COALESCE(NULLIF(r.tp_dependencia_adm_esc, ''), ''),
            COALESCE(NULLIF(r.tp_localizacao_esc, ''), ''),
            COALESCE(NULLIF(r.tp_sit_func_esc, ''), '')
        )) AS chave_escola,
        md5(concat_ws('|',
            COALESCE(NULLIF(r.tp_presenca_cn, ''), ''),
            COALESCE(NULLIF(r.tp_presenca_ch, ''), ''),
            COALESCE(NULLIF(r.tp_presenca_lc, ''), ''),
            COALESCE(NULLIF(r.tp_presenca_mt, ''), ''),
            COALESCE(NULLIF(r.co_prova_cn, ''), ''),
            COALESCE(NULLIF(r.co_prova_ch, ''), ''),
            COALESCE(NULLIF(r.co_prova_lc, ''), ''),
            COALESCE(NULLIF(r.co_prova_mt, ''), ''),
            COALESCE(NULLIF(r.tp_lingua, ''), ''),
            COALESCE(NULLIF(r.tp_status_redacao, ''), '')
        )) AS chave_prova,
        p.q001, p.q002, p.q003, p.q004, p.q005, p.q006, p.q007, p.q008, p.q009, p.q010, p.q011, p.q012,
        p.q013, p.q014, p.q015, p.q016, p.q017, p.q018, p.q019, p.q020, p.q021, p.q022, p.q023,
        r.co_escola,
        r.co_municipio_esc,
        r.tp_dependencia_adm_esc,
        r.tp_localizacao_esc,
        r.tp_sit_func_esc,
        r.tp_presenca_cn,
        r.tp_presenca_ch,
        r.tp_presenca_lc,
        r.tp_presenca_mt,
        r.co_prova_cn,
        r.co_prova_ch,
        r.co_prova_lc,
        r.co_prova_mt,
        r.tp_lingua,
        r.tp_status_redacao
    FROM staging.stg_participantes_2024 p
    INNER JOIN staging.stg_resultados_2024 r
        ON NULLIF(r.nu_sequencial, '')::BIGINT = p.id_carga
),
base_media AS (
    SELECT
        b.*,
        (
            COALESCE(nota_cn, 0) + COALESCE(nota_ch, 0) + COALESCE(nota_lc, 0) +
            COALESCE(nota_mt, 0) + COALESCE(nota_redacao, 0)
        ) / NULLIF(
            (CASE WHEN nota_cn IS NULL THEN 0 ELSE 1 END) +
            (CASE WHEN nota_ch IS NULL THEN 0 ELSE 1 END) +
            (CASE WHEN nota_lc IS NULL THEN 0 ELSE 1 END) +
            (CASE WHEN nota_mt IS NULL THEN 0 ELSE 1 END) +
            (CASE WHEN nota_redacao IS NULL THEN 0 ELSE 1 END),
            0
        ) AS media_geral
    FROM base b
)
SELECT
    ROW_NUMBER() OVER (ORDER BY b.id_carga)::BIGINT AS id_fato,
    b.id_carga,
    b.nu_inscricao,
    dp.id_participante,
    dl.id_localidade,
    ds.id_socioeconomica,
    de.id_escola,
    dpr.id_prova,
    b.nota_cn,
    b.nota_ch,
    b.nota_lc,
    b.nota_mt,
    b.nota_redacao,
    b.nota_comp1,
    b.nota_comp2,
    b.nota_comp3,
    b.nota_comp4,
    b.nota_comp5,
    b.media_geral,
    GREATEST(
        COALESCE(b.nota_cn, -1),
        COALESCE(b.nota_ch, -1),
        COALESCE(b.nota_lc, -1),
        COALESCE(b.nota_mt, -1),
        COALESCE(b.nota_redacao, -1)
    ) AS maior_nota,
    CASE GREATEST(
        COALESCE(b.nota_cn, -1),
        COALESCE(b.nota_ch, -1),
        COALESCE(b.nota_lc, -1),
        COALESCE(b.nota_mt, -1),
        COALESCE(b.nota_redacao, -1)
    )
        WHEN COALESCE(b.nota_cn, -1) THEN 'Ciencias da Natureza'
        WHEN COALESCE(b.nota_ch, -1) THEN 'Ciencias Humanas'
        WHEN COALESCE(b.nota_lc, -1) THEN 'Linguagens e Codigos'
        WHEN COALESCE(b.nota_mt, -1) THEN 'Matematica'
        WHEN COALESCE(b.nota_redacao, -1) THEN 'Redacao'
        ELSE 'Nao informado'
    END AS area_maior_nota,
    CASE
        WHEN b.tp_presenca_cn = '1'
         AND b.tp_presenca_ch = '1'
         AND b.tp_presenca_lc = '1'
         AND b.tp_presenca_mt = '1'
        THEN 1 ELSE 0
    END AS indicador_presenca_completa,
    1 AS qtd_participantes
FROM base_media b
INNER JOIN olap.dim_participante dp
    ON dp.id_carga = b.id_carga
LEFT JOIN olap.dim_localidade dl
    ON dl.chave_localidade = b.chave_localidade
LEFT JOIN olap.dim_socioeconomica ds
    ON ds.id_carga = b.id_carga
LEFT JOIN olap.dim_escola de
    ON de.chave_escola = b.chave_escola
LEFT JOIN olap.dim_prova dpr
    ON dpr.chave_prova = b.chave_prova;

ALTER TABLE olap.fato_desempenho_enem ADD CONSTRAINT pk_fato_desempenho_enem PRIMARY KEY (id_fato);
ALTER TABLE olap.fato_desempenho_enem ADD CONSTRAINT fk_fato_participante FOREIGN KEY (id_participante) REFERENCES olap.dim_participante (id_participante);
ALTER TABLE olap.fato_desempenho_enem ADD CONSTRAINT fk_fato_localidade FOREIGN KEY (id_localidade) REFERENCES olap.dim_localidade (id_localidade);
ALTER TABLE olap.fato_desempenho_enem ADD CONSTRAINT fk_fato_socioeconomica FOREIGN KEY (id_socioeconomica) REFERENCES olap.dim_socioeconomica (id_socioeconomica);
ALTER TABLE olap.fato_desempenho_enem ADD CONSTRAINT fk_fato_escola FOREIGN KEY (id_escola) REFERENCES olap.dim_escola (id_escola);
ALTER TABLE olap.fato_desempenho_enem ADD CONSTRAINT fk_fato_prova FOREIGN KEY (id_prova) REFERENCES olap.dim_prova (id_prova);

CREATE INDEX ix_fato_dim_localidade ON olap.fato_desempenho_enem (id_localidade);
CREATE INDEX ix_fato_dim_socioeconomica ON olap.fato_desempenho_enem (id_socioeconomica);
CREATE INDEX ix_fato_dim_participante ON olap.fato_desempenho_enem (id_participante);
CREATE INDEX ix_fato_dim_escola ON olap.fato_desempenho_enem (id_escola);

ANALYZE olap.dim_participante;
ANALYZE olap.dim_localidade;
ANALYZE olap.dim_socioeconomica;
ANALYZE olap.dim_escola;
ANALYZE olap.dim_prova;
ANALYZE olap.fato_desempenho_enem;

SELECT
    (SELECT COUNT(*) FROM olap.dim_participante) AS qtd_dim_participante,
    (SELECT COUNT(*) FROM olap.dim_localidade) AS qtd_dim_localidade,
    (SELECT COUNT(*) FROM olap.dim_socioeconomica) AS qtd_dim_socioeconomica,
    (SELECT COUNT(*) FROM olap.dim_escola) AS qtd_dim_escola,
    (SELECT COUNT(*) FROM olap.dim_prova) AS qtd_dim_prova,
    (SELECT COUNT(*) FROM olap.fato_desempenho_enem) AS qtd_fato_desempenho;


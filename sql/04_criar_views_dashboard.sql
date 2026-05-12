-- Script: 04_criar_views_dashboard.sql
-- Objetivo: criar views analiticas para consumo direto no Power BI.

CREATE OR REPLACE VIEW olap.vw_notas_por_area AS
SELECT
    f.id_fato,
    f.nu_inscricao,
    f.id_participante,
    f.id_localidade,
    f.id_socioeconomica,
    f.id_escola,
    f.id_prova,
    area.area_conhecimento,
    area.nota,
    f.media_geral,
    f.qtd_participantes
FROM olap.fato_desempenho_enem f
CROSS JOIN LATERAL (
    VALUES
        ('Ciencias da Natureza', f.nota_cn),
        ('Ciencias Humanas', f.nota_ch),
        ('Linguagens e Codigos', f.nota_lc),
        ('Matematica', f.nota_mt),
        ('Redacao', f.nota_redacao)
) AS area(area_conhecimento, nota)
WHERE area.nota IS NOT NULL;

CREATE OR REPLACE VIEW olap.vw_01_desempenho_estado_regiao AS
SELECT
    l.regiao,
    l.sg_uf_prova AS uf,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(f.media_geral), 2) AS media_geral,
    ROUND(AVG(f.nota_cn), 2) AS media_cn,
    ROUND(AVG(f.nota_ch), 2) AS media_ch,
    ROUND(AVG(f.nota_lc), 2) AS media_lc,
    ROUND(AVG(f.nota_mt), 2) AS media_mt,
    ROUND(AVG(f.nota_redacao), 2) AS media_redacao
FROM olap.fato_desempenho_enem f
JOIN olap.dim_localidade l ON l.id_localidade = f.id_localidade
GROUP BY l.regiao, l.sg_uf_prova;

CREATE OR REPLACE VIEW olap.vw_02_desempenho_faixa_socioeconomica AS
SELECT
    s.faixa_socioeconomica,
    s.renda_familiar,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(f.media_geral), 2) AS media_geral,
    ROUND(AVG(f.nota_cn), 2) AS media_cn,
    ROUND(AVG(f.nota_ch), 2) AS media_ch,
    ROUND(AVG(f.nota_lc), 2) AS media_lc,
    ROUND(AVG(f.nota_mt), 2) AS media_mt,
    ROUND(AVG(f.nota_redacao), 2) AS media_redacao
FROM olap.fato_desempenho_enem f
JOIN olap.dim_socioeconomica s ON s.id_socioeconomica = f.id_socioeconomica
GROUP BY s.faixa_socioeconomica, s.renda_familiar;

CREATE OR REPLACE VIEW olap.vw_03_maiores_redacoes_localidade AS
SELECT
    l.regiao,
    l.sg_uf_prova AS uf,
    l.no_municipio_prova AS municipio,
    f.nu_inscricao,
    f.nota_redacao,
    RANK() OVER (
        PARTITION BY l.sg_uf_prova, l.no_municipio_prova
        ORDER BY f.nota_redacao DESC NULLS LAST
    ) AS ranking_no_municipio
FROM olap.fato_desempenho_enem f
JOIN olap.dim_localidade l ON l.id_localidade = f.id_localidade
WHERE f.nota_redacao IS NOT NULL;

CREATE OR REPLACE VIEW olap.vw_04_maiores_notas_area_geografica AS
SELECT
    n.area_conhecimento,
    l.regiao,
    l.sg_uf_prova AS uf,
    l.no_municipio_prova AS municipio,
    n.nu_inscricao,
    n.nota,
    RANK() OVER (
        PARTITION BY n.area_conhecimento
        ORDER BY n.nota DESC NULLS LAST
    ) AS ranking_area
FROM olap.vw_notas_por_area n
JOIN olap.dim_localidade l ON l.id_localidade = n.id_localidade;

CREATE OR REPLACE VIEW olap.vw_05_notas_genero_socioeconomica AS
SELECT
    p.sexo,
    s.faixa_socioeconomica,
    s.renda_familiar,
    n.area_conhecimento,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(n.nota), 2) AS media_nota
FROM olap.vw_notas_por_area n
JOIN olap.dim_participante p ON p.id_participante = n.id_participante
JOIN olap.dim_socioeconomica s ON s.id_socioeconomica = n.id_socioeconomica
GROUP BY p.sexo, s.faixa_socioeconomica, s.renda_familiar, n.area_conhecimento;

CREATE OR REPLACE VIEW olap.vw_06_notas_faixa_etaria AS
SELECT
    p.cod_faixa_etaria,
    p.faixa_etaria,
    n.area_conhecimento,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(n.nota), 2) AS media_nota
FROM olap.vw_notas_por_area n
JOIN olap.dim_participante p ON p.id_participante = n.id_participante
GROUP BY p.cod_faixa_etaria, p.faixa_etaria, n.area_conhecimento;

CREATE OR REPLACE VIEW olap.vw_07_notas_raca_cor AS
SELECT
    p.cod_cor_raca,
    p.cor_raca,
    n.area_conhecimento,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(n.nota), 2) AS media_nota
FROM olap.vw_notas_por_area n
JOIN olap.dim_participante p ON p.id_participante = n.id_participante
GROUP BY p.cod_cor_raca, p.cor_raca, n.area_conhecimento;

CREATE OR REPLACE VIEW olap.vw_08_capital_interior AS
SELECT
    l.regiao,
    l.sg_uf_prova AS uf,
    l.capital_interior,
    n.area_conhecimento,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(n.nota), 2) AS media_nota
FROM olap.vw_notas_por_area n
JOIN olap.dim_localidade l ON l.id_localidade = n.id_localidade
GROUP BY l.regiao, l.sg_uf_prova, l.capital_interior, n.area_conhecimento;

CREATE OR REPLACE VIEW olap.vw_09_genero_por_area AS
SELECT
    p.sexo,
    n.area_conhecimento,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(n.nota), 2) AS media_nota
FROM olap.vw_notas_por_area n
JOIN olap.dim_participante p ON p.id_participante = n.id_participante
GROUP BY p.sexo, n.area_conhecimento;

CREATE OR REPLACE VIEW olap.vw_10_rede_escola_por_area AS
SELECT
    e.rede_escola,
    e.dependencia_administrativa,
    n.area_conhecimento,
    COUNT(*) AS qtd_participantes,
    ROUND(AVG(n.nota), 2) AS media_nota
FROM olap.vw_notas_por_area n
JOIN olap.dim_escola e ON e.id_escola = n.id_escola
GROUP BY e.rede_escola, e.dependencia_administrativa, n.area_conhecimento;


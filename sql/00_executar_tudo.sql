-- Script: 00_executar_tudo.sql
-- Objetivo: executar toda a criacao do modelo OLAP no banco ENEM2024.
-- Uso:
--   psql -h localhost -d ENEM2024 -U postgres -f sql/00_executar_tudo.sql

\set ON_ERROR_STOP on

\echo '1/4 - Criando staging'
\i sql/01_criar_staging.sql

\echo '2/4 - Carregando CSVs no staging'
\i sql/02_carregar_staging.sql

\echo '3/4 - Criando modelo OLAP'
\i sql/03_criar_modelo_olap.sql

\echo '4/4 - Criando views do dashboard'
\i sql/04_criar_views_dashboard.sql

\echo 'Modelo OLAP ENEM 2024 concluido.'


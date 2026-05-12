# Dashboard ENEM 2024 - Modelo OLAP em PostgreSQL e Power BI

## Visao Geral

Este projeto foi desenvolvido para a disciplina **Sistemas de Apoio a Tomada de Decisao**, com o objetivo de construir um modelo OLAP para analise dos Microdados do ENEM 2024 e preparar uma base analitica para visualizacao no Power BI.

A situacao-problema considera a necessidade de analisar o desempenho dos participantes do ENEM 2024 para apoiar decisoes sobre o processo de aplicacao da prova e programas educacionais correlatos.

O trabalho transforma dados originalmente disponibilizados em formato operacional, com caracteristicas de modelo OLTP, em um modelo multidimensional orientado a analise. O banco utilizado foi o PostgreSQL local, na base `ENEM2024`.

## Objetivos do Projeto

O modelo foi construido para responder perguntas de negocio relacionadas ao desempenho dos alunos:

- Desempenho medio por Estado e Regiao.
- Desempenho medio por faixa socioeconomica.
- Distribuicao das maiores notas de redacao por Estado e municipio.
- Distribuicao geografica dos alunos com maiores notas por area de conhecimento.
- Distribuicao das notas por genero e situacao socioeconomica.
- Distribuicao das notas por faixa etaria.
- Distribuicao das notas por raca/cor.
- Diferencas entre alunos de capitais e do interior.
- Comparacao das notas por genero em cada area de conhecimento.
- Media de notas entre alunos de escolas publicas e privadas por area.

## Fontes de Dados

Foram utilizados os arquivos dos Microdados do ENEM 2024, localizados em `microdados_enem_2024`.

Arquivos principais:

- `microdados_enem_2024/DADOS/PARTICIPANTES_2024.csv`: dados demograficos, local de prova e questionario socioeconomico.
- `microdados_enem_2024/DADOS/RESULTADOS_2024.csv`: dados de escola, presenca, provas, notas objetivas e redacao.
- `microdados_enem_2024/DADOS/ITENS_PROVA_2024.csv`: metadados de itens da prova, mantidos como referencia.

Arquivos auxiliares usados para interpretacao dos campos:

- `microdados_enem_2024/INPUTS/INPUT_R_PARTICIPANTES_2024.R`
- `microdados_enem_2024/INPUTS/INPUT_R_RESULTADOS_2024.R`
- `microdados_enem_2024/INPUTS/INPUT_SPSS_PARTICIPANTES_2024.sps`
- `microdados_enem_2024/INPUTS/INPUT_SPSS_RESULTADOS_2024.sps`

Esses arquivos auxiliaram na identificacao de codigos, rotulos e tipos de variaveis, como sexo, faixa etaria, raca/cor, renda familiar, tipo de escola, presenca e status da redacao.

## Estrutura do Projeto

```text
AV2-TRABALHO-1-ENEM/
|-- AV2-TRABALHO-1-ENEM.md
|-- README.MD
|-- docs/
|   `-- MODELO_OLAP_ENEM_2024.md
|-- microdados_enem_2024/
|   |-- DADOS/
|   |-- INPUTS/
|   `-- PROVAS E GABARITOS/
|-- powerbi/
|   |-- README_POWERBI.md
|   `-- README_POWERBI_versao_anterior.md
`-- sql/
    |-- 00_executar_tudo.sql
    |-- 01_criar_staging.sql
    |-- 02_carregar_staging.sql
    |-- 03_criar_modelo_olap.sql
    |-- 04_criar_views_dashboard.sql
    `-- 05_criar_tabelas_powerbi.sql
```

## Processo de Desenvolvimento

O desenvolvimento seguiu o plano de execucao definido para o projeto:

1. Validacao da estrutura dos CSVs e das variaveis disponiveis.
2. Criacao da area de staging no PostgreSQL.
3. Carga dos arquivos `PARTICIPANTES_2024.csv` e `RESULTADOS_2024.csv`.
4. Criacao do modelo estrela no schema `olap`.
5. Criacao de views analiticas para responder as perguntas do dashboard.
6. Criacao de uma camada fisica agregada no schema `powerbi`, para importacao estavel no Power BI.
7. Documentacao do processo, das justificativas e dos insights obtidos.

## Arquitetura dos Dados

O projeto usa tres camadas logicas no PostgreSQL:

- `staging`: recebe os dados brutos dos CSVs, preservando os codigos originais do INEP.
- `olap`: contem o modelo multidimensional, com dimensoes, fato e views analiticas.
- `powerbi`: contem tabelas fisicas agregadas, criadas para reduzir o volume importado pelo Power BI.

### Fluxo Geral

```mermaid
flowchart LR
    CsvParticipantes["PARTICIPANTES_2024.csv"] --> StgParticipantes["staging.stg_participantes_2024"]
    CsvResultados["RESULTADOS_2024.csv"] --> StgResultados["staging.stg_resultados_2024"]
    StgParticipantes --> DimParticipante["olap.dim_participante"]
    StgParticipantes --> DimLocalidade["olap.dim_localidade"]
    StgParticipantes --> DimSocioeconomica["olap.dim_socioeconomica"]
    StgResultados --> DimEscola["olap.dim_escola"]
    StgResultados --> DimProva["olap.dim_prova"]
    DimParticipante --> Fato["olap.fato_desempenho_enem"]
    DimLocalidade --> Fato
    DimSocioeconomica --> Fato
    DimEscola --> Fato
    DimProva --> Fato
    Fato --> Views["olap.vw_01 a olap.vw_10"]
    Views --> PowerbiTables["powerbi.pb_01 a powerbi.pb_10"]
    PowerbiTables --> Dashboard["Power BI"]
```

### Modelo Estrela Proposto

```mermaid
flowchart LR
    DimParticipante["dim_participante<br/>sexo, faixa etaria, raca/cor, treineiro"] --> FatoDesempenho["fato_desempenho_enem<br/>notas, media geral, maior nota"]
    DimLocalidade["dim_localidade<br/>UF, regiao, municipio, capital/interior"] --> FatoDesempenho
    DimSocioeconomica["dim_socioeconomica<br/>renda, escolaridade dos pais, bens, tipo de escola EM"] --> FatoDesempenho
    DimEscola["dim_escola<br/>rede, dependencia, localizacao, situacao"] --> FatoDesempenho
    DimProva["dim_prova<br/>presenca, lingua, status da redacao"] --> FatoDesempenho
```

## Modelo OLAP

### Tabela Fato

`olap.fato_desempenho_enem`

Grao da tabela: uma linha por participante carregado e pareado com o arquivo de resultados.

Medidas principais:

- `nota_cn`: nota de Ciencias da Natureza.
- `nota_ch`: nota de Ciencias Humanas.
- `nota_lc`: nota de Linguagens e Codigos.
- `nota_mt`: nota de Matematica.
- `nota_redacao`: nota de redacao.
- `media_geral`: media das notas disponiveis.
- `maior_nota`: maior nota entre as areas.
- `area_maior_nota`: area correspondente a maior nota.
- `indicador_presenca_completa`: indica se o participante esteve presente em todas as provas objetivas.
- `qtd_participantes`: medida contadora para agregacoes.

### Dimensoes

`olap.dim_participante`

Contem atributos demograficos e escolares do participante:

- faixa etaria;
- sexo;
- estado civil;
- cor/raca;
- nacionalidade;
- situacao de conclusao do Ensino Medio;
- tipo de ensino;
- indicador de treineiro.

`olap.dim_localidade`

Contem informacoes geograficas da aplicacao da prova:

- codigo e nome do municipio;
- codigo e sigla da UF;
- regiao;
- classificacao entre capital e interior.

`olap.dim_socioeconomica`

Contem atributos do questionario socioeconomico:

- escolaridade do pai e da mae;
- ocupacao do pai e da mae;
- quantidade de pessoas na residencia;
- renda familiar;
- faixa socioeconomica derivada;
- tipo de escola frequentada no Ensino Medio;
- bens e servicos domiciliares.

`olap.dim_escola`

Contem caracteristicas da escola:

- codigo da escola;
- municipio e UF;
- dependencia administrativa;
- rede publica/privada;
- localizacao urbana/rural;
- situacao de funcionamento.

`olap.dim_prova`

Contem caracteristicas da realizacao da prova:

- presenca por area;
- codigo das provas;
- lingua estrangeira;
- status da redacao.

## Justificativas das Escolhas

O modelo estrela foi escolhido porque e o formato mais adequado para ferramentas de BI. Ele separa medidas numericas, armazenadas na tabela fato, dos atributos descritivos, armazenados nas dimensoes. Isso facilita consultas por UF, regiao, renda, genero, faixa etaria, raca/cor e tipo de escola.

A area de staging foi criada para preservar os dados originais do INEP. Essa escolha permite recarregar os dados, auditar transformacoes e comparar o dado bruto com o dado tratado.

Os campos foram carregados inicialmente como texto no staging. Essa abordagem evita falhas de importacao causadas por campos vazios, separadores decimais ou codigos categoricos. A conversao para tipos numericos ocorre apenas na etapa OLAP.

O arquivo `RESULTADOS_2024.csv` nao possui `NU_INSCRICAO`; ele possui `NU_SEQUENCIAL`. Por isso, o relacionamento entre participantes e resultados foi feito usando uma chave tecnica `id_carga`, gerada pela ordem de carga dos participantes, pareada com `NU_SEQUENCIAL`. Essa solucao preserva o pareamento quando os CSVs originais sao carregados sem reordenacao.

A dimensao socioeconomica foi inicialmente planejada como uma dimensao com combinacoes distintas de respostas. Durante a execucao, verificou-se alta cardinalidade, o que tornava a criacao da fato muito lenta. A solucao adotada foi usar `id_carga` como chave tecnica para essa dimensao, mantendo os atributos analiticos e reduzindo o custo de processamento.

Tambem foram criadas chaves hash para dimensoes de localidade, escola e prova. Essa decisao reduziu joins por multiplas colunas e acelerou a criacao da tabela fato.

Por fim, foi criada uma camada adicional no schema `powerbi`. Essa camada materializa consultas agregadas em tabelas fisicas, evitando que o Power BI tente executar views pesadas durante a importacao.

## Scripts SQL

`sql/00_executar_tudo.sql`

Executa o fluxo completo de criacao do staging, carga, modelo OLAP e views.

`sql/01_criar_staging.sql`

Cria as tabelas brutas:

- `staging.stg_participantes_2024`
- `staging.stg_resultados_2024`

`sql/02_carregar_staging.sql`

Carrega os CSVs originais usando `\copy` do `psql`.

`sql/03_criar_modelo_olap.sql`

Cria as dimensoes e a tabela fato no schema `olap`.

`sql/04_criar_views_dashboard.sql`

Cria as views analiticas para responder as perguntas do trabalho.

`sql/05_criar_tabelas_powerbi.sql`

Cria tabelas fisicas agregadas no schema `powerbi`, recomendadas para importacao no Power BI.

## Views Analiticas

As views do schema `olap` foram criadas para mapear diretamente as perguntas do enunciado:

- `olap.vw_01_desempenho_estado_regiao`: desempenho medio por Estado e Regiao.
- `olap.vw_02_desempenho_faixa_socioeconomica`: desempenho por faixa socioeconomica.
- `olap.vw_03_maiores_redacoes_localidade`: maiores notas de redacao por Estado e municipio.
- `olap.vw_04_maiores_notas_area_geografica`: maiores notas por area de conhecimento e localidade.
- `olap.vw_05_notas_genero_socioeconomica`: notas por genero e situacao socioeconomica.
- `olap.vw_06_notas_faixa_etaria`: notas por faixa etaria.
- `olap.vw_07_notas_raca_cor`: notas por raca/cor.
- `olap.vw_08_capital_interior`: comparacao entre capital e interior.
- `olap.vw_09_genero_por_area`: notas por genero em cada area.
- `olap.vw_10_rede_escola_por_area`: medias por escola publica e privada.

## Camada Power BI

Durante a importacao no Power BI, foi identificado erro de ODBC/OLE DB ao carregar muitas views e tabelas grandes simultaneamente. Para resolver isso, foram criadas tabelas agregadas no schema `powerbi`.

Tabelas recomendadas para importar no Power BI:

- `powerbi.pb_01_desempenho_estado_regiao`
- `powerbi.pb_02_desempenho_faixa_socioeconomica`
- `powerbi.pb_03_top_redacoes_localidade`
- `powerbi.pb_04_top_notas_area_geografica`
- `powerbi.pb_05_notas_genero_socioeconomica`
- `powerbi.pb_06_notas_faixa_etaria`
- `powerbi.pb_07_notas_raca_cor`
- `powerbi.pb_08_capital_interior`
- `powerbi.pb_09_genero_por_area`
- `powerbi.pb_10_rede_escola_por_area`

Essas tabelas ja consolidam as agregacoes necessarias para o dashboard e reduzem significativamente o volume importado.

## Conexao no Power BI

Configuracao usada:

- Servidor: `localhost`
- Banco de dados: `ENEM2024`
- Modo de conectividade: `Importar`

Para um dashboard mais leve, recomenda-se importar somente as tabelas do schema `powerbi`.

A versao anterior da orientacao, baseada no schema `olap`, esta em `powerbi/README_POWERBI_versao_anterior.md`. Ela foi preservada porque descreve o modelo estrela completo e os relacionamentos entre fato e dimensoes.

## Paginas Sugeridas para o Dashboard

### 1. Visao Geral Geografica

Fonte recomendada: `powerbi.pb_01_desempenho_estado_regiao`

Visuais:

- Cartao com total de participantes.
- Cartao com media geral.
- Cartao com media de redacao.
- Grafico de barras por regiao.
- Mapa ou visual geografico por UF.

### 2. Perfil Socioeconomico

Fonte recomendada: `powerbi.pb_02_desempenho_faixa_socioeconomica`

Visuais:

- Barras por faixa socioeconomica.
- Matriz por renda familiar.
- Segmentadores por faixa socioeconomica e renda.

### 3. Redacao e Maiores Notas

Fontes recomendadas:

- `powerbi.pb_03_top_redacoes_localidade`
- `powerbi.pb_04_top_notas_area_geografica`

Visuais:

- Tabela de maiores notas de redacao por UF e municipio.
- Ranking por area de conhecimento.
- Grafico por UF, municipio e area.

### 4. Demografia e Desempenho

Fontes recomendadas:

- `powerbi.pb_05_notas_genero_socioeconomica`
- `powerbi.pb_06_notas_faixa_etaria`
- `powerbi.pb_07_notas_raca_cor`
- `powerbi.pb_09_genero_por_area`

Visuais:

- Barras por genero e area de conhecimento.
- Barras por faixa etaria.
- Barras por raca/cor.
- Matriz cruzando genero, situacao socioeconomica e media.

### 5. Escola e Capital versus Interior

Fontes recomendadas:

- `powerbi.pb_08_capital_interior`
- `powerbi.pb_10_rede_escola_por_area`

Visuais:

- Comparacao entre capital e interior.
- Comparacao entre rede publica e privada.
- Segmentadores por area de conhecimento.

## Resultados da Execucao

A carga e transformacao foram executadas com sucesso no PostgreSQL.

Contagens principais:

- `staging.stg_participantes_2024`: 4.332.944 registros.
- `staging.stg_resultados_2024`: 4.332.944 registros.
- `olap.dim_participante`: 4.332.944 registros.
- `olap.dim_localidade`: 1.753 registros.
- `olap.dim_socioeconomica`: 4.332.944 registros.
- `olap.dim_escola`: 29.401 registros.
- `olap.dim_prova`: 382 registros.
- `olap.fato_desempenho_enem`: 4.332.944 registros.

Tabelas agregadas criadas para Power BI:

- `powerbi.pb_01_desempenho_estado_regiao`: 27 registros.
- `powerbi.pb_02_desempenho_faixa_socioeconomica`: 17 registros.
- `powerbi.pb_03_top_redacoes_localidade`: 37.575 registros.
- `powerbi.pb_04_top_notas_area_geografica`: 6.423 registros.
- `powerbi.pb_05_notas_genero_socioeconomica`: 170 registros.
- `powerbi.pb_06_notas_faixa_etaria`: 100 registros.
- `powerbi.pb_07_notas_raca_cor`: 30 registros.
- `powerbi.pb_08_capital_interior`: 265 registros.
- `powerbi.pb_09_genero_por_area`: 10 registros.
- `powerbi.pb_10_rede_escola_por_area`: 25 registros.

## Insights Obtidos

As analises agregadas indicam alguns pontos relevantes para exploracao no dashboard.

Por regiao, as medias gerais ficaram muito proximas, com pequena vantagem para Nordeste, Sudeste e Centro-Oeste nas agregacoes estaduais analisadas. Isso sugere que a diferenca regional existe, mas deve ser analisada com filtros por UF, municipio e perfil do participante para evitar conclusoes simplificadas.

As maiores medias gerais por UF, entre os destaques observados, apareceram em:

- Amapa (`AP`): media geral de 536,25.
- Paraiba (`PB`): media geral de 536,24.
- Mato Grosso do Sul (`MS`): media geral de 535,69.
- Piaui (`PI`): media geral de 535,62.
- Alagoas (`AL`): media geral de 535,59.

Na analise por area de conhecimento, Redacao apresentou a maior media agregada entre as areas, seguida por Matematica, Linguagens e Codigos, Ciencias Humanas e Ciencias da Natureza. Esse resultado indica que as areas objetivas devem ser analisadas separadamente, pois possuem escalas e distribuicoes diferentes.

Foram identificadas notas maximas de redacao (`1000`) em diferentes municipios, como Salvador, Itabuna, Vitoria, Paraopeba, Arcoverde, Jaboatao dos Guararapes, Pinhao, Tramandai e Paulinia. Isso permite construir um ranking geografico de alto desempenho em redacao.

Na comparacao capital versus interior, as medias ficaram muito proximas, com pequena vantagem para capitais. Esse insight deve ser explorado por area de conhecimento, pois a diferenca pode ser mais visivel em algumas disciplinas do que na media geral.

Na comparacao por rede escolar, a rede privada apresentou media agregada superior a rede publica. Esse resultado reforca a importancia de cruzar desempenho com variaveis socioeconomicas, renda familiar e tipo de escola frequentada no Ensino Medio.

As faixas socioeconomicas apresentaram medias proximas nas agregacoes gerais. Ainda assim, o dashboard permite analisar a renda familiar em mais detalhe, principalmente quando combinada com genero, raca/cor, UF e tipo de escola.

## Como Executar

No terminal PowerShell, a partir da raiz do projeto:

```powershell
$env:PGPASSWORD="SUA_SENHA_DO_POSTGRES"
& "I:\PostgreSQL\17\pgAdmin 4\runtime\psql.exe" -h localhost -d ENEM2024 -U postgres -f "sql/00_executar_tudo.sql"
& "I:\PostgreSQL\17\pgAdmin 4\runtime\psql.exe" -h localhost -d ENEM2024 -U postgres -f "sql/05_criar_tabelas_powerbi.sql"
Remove-Item Env:PGPASSWORD
```

Se o `psql.exe` estiver no PATH do Windows, tambem e possivel executar:

```powershell
psql -h localhost -d ENEM2024 -U postgres -f sql/00_executar_tudo.sql
psql -h localhost -d ENEM2024 -U postgres -f sql/05_criar_tabelas_powerbi.sql
```

## Observacoes Finais

O modelo OLAP completo fica disponivel no schema `olap`, enquanto a camada recomendada para importacao no Power BI fica no schema `powerbi`.

Para desenvolvimento e auditoria, o schema `olap` e mais completo. Para construcao do dashboard, o schema `powerbi` e mais eficiente, pois evita timeout e erros de importacao ao trabalhar com milhoes de registros.

O projeto esta pronto para ser versionado no GitHub, mantendo os scripts SQL, documentacao e orientacoes de uso. Os arquivos de microdados devem ser avaliados antes do versionamento por causa do tamanho e da origem publica dos dados.


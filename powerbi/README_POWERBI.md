# Guia do Dashboard no Power BI

Este guia orienta a conexão do Power BI ao modelo OLAP criado no PostgreSQL local, banco `ENEM2024`.

## Conexão

1. Abra o Power BI Desktop.
2. Acesse **Obter dados > Banco de dados PostgreSQL**.
3. Informe:
   - Servidor: `localhost`
   - Banco de dados: `ENEM2024`
   - Modo de conectividade: `Importar`
4. Para evitar erro de timeout/stream no Power BI, selecione preferencialmente as tabelas fisicas do schema `powerbi`.
5. Importe estas tabelas:
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

Evite importar, ao mesmo tempo, a tabela fato completa, as dimensoes completas e todas as views do schema `olap`. Essa combinacao aumenta muito o volume lido pelo Power BI e pode causar erro de ODBC/OLE DB durante a importacao.

## Relacionamentos

Caso importe as tabelas do modelo estrela, configure estes relacionamentos:

- `fato_desempenho_enem.id_participante` -> `dim_participante.id_participante`
- `fato_desempenho_enem.id_localidade` -> `dim_localidade.id_localidade`
- `fato_desempenho_enem.id_socioeconomica` -> `dim_socioeconomica.id_socioeconomica`
- `fato_desempenho_enem.id_escola` -> `dim_escola.id_escola`
- `fato_desempenho_enem.id_prova` -> `dim_prova.id_prova`

Use relacionamento muitos-para-um, com filtro da dimensão para a fato.

## Medidas DAX Sugeridas

```DAX
Media Geral = AVERAGE('fato_desempenho_enem'[media_geral])

Media CN = AVERAGE('fato_desempenho_enem'[nota_cn])

Media CH = AVERAGE('fato_desempenho_enem'[nota_ch])

Media LC = AVERAGE('fato_desempenho_enem'[nota_lc])

Media MT = AVERAGE('fato_desempenho_enem'[nota_mt])

Media Redacao = AVERAGE('fato_desempenho_enem'[nota_redacao])

Qtd Participantes = SUM('fato_desempenho_enem'[qtd_participantes])
```

> Observaçãoo: o Power BI pode renomear tabelas importadas substituindo `.` por espaço. Ajuste os nomes das medidas conforme aparecerem no painel de campos.

## Páginas do Dashboard

### 1. Visão Geral Geográfica

Fonte recomendada: `olap.vw_01_desempenho_estado_regiao`

Visuais:

- Mapa preenchido por `uf`, usando `media_geral`.
- Barras por `regiao`, usando `media_geral`.
- Cartões para `qtd_participantes`, `media_geral`, `media_redacao`.

Pergunta atendida:

- Desempenho médio dos alunos por Estado e Região.

### 2. Perfil Socioeconômico

Fonte recomendada: `olap.vw_02_desempenho_faixa_socioeconomica`

Visuais:

- Colunas por `faixa_socioeconomica`, usando `media_geral`.
- Matriz com `renda_familiar` nas linhas e médias por área nas colunas.
- Segmentadores para `faixa_socioeconomica` e `renda_familiar`.

Pergunta atendida:

- Desempenho médio dos alunos por faixa socioeconômica.

### 3. Redação e Maiores Notas

Fontes recomendadas:

- `olap.vw_03_maiores_redacoes_localidade`
- `olap.vw_04_maiores_notas_area_geografica`

Visuais:

- Tabela com `uf`, `municipio`, `nu_inscricao`, `nota_redacao` e `ranking_no_municipio`.
- Mapa ou barras por `area_conhecimento`, `uf` e `municipio`, usando `nota`.
- Filtro de ranking para visualizar top 10, top 50 ou top 100.

Perguntas atendidas:

- Distribuição das maiores notas de redação por estado e município.
- Distribuição geográfica dos alunos com as maiores notas por área de conhecimento.

### 4. Demografia e Desempenho

Fontes recomendadas:

- `olap.vw_05_notas_genero_socioeconomica`
- `olap.vw_06_notas_faixa_etaria`
- `olap.vw_07_notas_raca_cor`
- `olap.vw_09_genero_por_area`

Visuais:

- Barras por `sexo` e `area_conhecimento`.
- Barras por `faixa_etaria` e `area_conhecimento`.
- Barras por `cor_raca` e `area_conhecimento`.
- Matriz cruzando `sexo`, `faixa_socioeconomica` e `media_nota`.

Perguntas atendidas:

- Distribuição das notas por gênero e situação socioeconômica.
- Distribuição das notas por faixa etária.
- Distribuição das notas por raça/cor.
- Comparação das notas por gênero em cada área de conhecimento.

### 5. Escola e Capital versus Interior

Fontes recomendadas:

- `olap.vw_08_capital_interior`
- `olap.vw_10_rede_escola_por_area`

Visuais:

- Colunas comparando `capital_interior` por `area_conhecimento`.
- Barras comparando `rede_escola` e `dependencia_administrativa` por área.
- Segmentadores por `uf`, `regiao`, `area_conhecimento`.

Perguntas atendidas:

- Diferenças nas médias de notas entre alunos de capitais e do interior.
- Média de notas entre alunos de escolas públicas e privadas por área de conhecimento.


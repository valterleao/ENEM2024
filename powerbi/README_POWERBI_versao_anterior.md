# Guia do Dashboard no Power BI

Este guia orienta a conexao do Power BI ao modelo OLAP criado no PostgreSQL local, banco `ENEM2024`.

## Conexao

1. Abra o Power BI Desktop.
2. Acesse **Obter dados > Banco de dados PostgreSQL**.
3. Informe:
   - Servidor: `localhost`
   - Banco de dados: `ENEM2024`
   - Modo de conectividade: `Importar`
4. Selecione as tabelas e views do schema `olap`.
5. Priorize a importacao destas tabelas:
   - `olap.fato_desempenho_enem`
   - `olap.dim_participante`
   - `olap.dim_localidade`
   - `olap.dim_socioeconomica`
   - `olap.dim_escola`
   - `olap.dim_prova`
   - views `olap.vw_01_*` a `olap.vw_10_*`

## Relacionamentos

Caso importe as tabelas do modelo estrela, configure estes relacionamentos:

- `fato_desempenho_enem.id_participante` -> `dim_participante.id_participante`
- `fato_desempenho_enem.id_localidade` -> `dim_localidade.id_localidade`
- `fato_desempenho_enem.id_socioeconomica` -> `dim_socioeconomica.id_socioeconomica`
- `fato_desempenho_enem.id_escola` -> `dim_escola.id_escola`
- `fato_desempenho_enem.id_prova` -> `dim_prova.id_prova`

Use relacionamento muitos-para-um, com filtro da dimensao para a fato.

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

> Observacao: o Power BI pode renomear tabelas importadas substituindo `.` por espaco. Ajuste os nomes das medidas conforme aparecerem no painel de campos.

## Paginas do Dashboard

### 1. Visao Geral Geografica

Fonte recomendada: `olap.vw_01_desempenho_estado_regiao`

Visuais:

- Mapa preenchido por `uf`, usando `media_geral`.
- Barras por `regiao`, usando `media_geral`.
- Cartoes para `qtd_participantes`, `media_geral`, `media_redacao`.

Pergunta atendida:

- Desempenho medio dos alunos por Estado e Regiao.

### 2. Perfil Socioeconomico

Fonte recomendada: `olap.vw_02_desempenho_faixa_socioeconomica`

Visuais:

- Colunas por `faixa_socioeconomica`, usando `media_geral`.
- Matriz com `renda_familiar` nas linhas e medias por area nas colunas.
- Segmentadores para `faixa_socioeconomica` e `renda_familiar`.

Pergunta atendida:

- Desempenho medio dos alunos por faixa socioeconomica.

### 3. Redacao e Maiores Notas

Fontes recomendadas:

- `olap.vw_03_maiores_redacoes_localidade`
- `olap.vw_04_maiores_notas_area_geografica`

Visuais:

- Tabela com `uf`, `municipio`, `nu_inscricao`, `nota_redacao` e `ranking_no_municipio`.
- Mapa ou barras por `area_conhecimento`, `uf` e `municipio`, usando `nota`.
- Filtro de ranking para visualizar top 10, top 50 ou top 100.

Perguntas atendidas:

- Distribuicao das maiores notas de redacao por estado e municipio.
- Distribuicao geografica dos alunos com as maiores notas por area de conhecimento.

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

- Distribuicao das notas por genero e situacao socioeconomica.
- Distribuicao das notas por faixa etaria.
- Distribuicao das notas por raca/cor.
- Comparacao das notas por genero em cada area de conhecimento.

### 5. Escola e Capital versus Interior

Fontes recomendadas:

- `olap.vw_08_capital_interior`
- `olap.vw_10_rede_escola_por_area`

Visuais:

- Colunas comparando `capital_interior` por `area_conhecimento`.
- Barras comparando `rede_escola` e `dependencia_administrativa` por area.
- Segmentadores por `uf`, `regiao`, `area_conhecimento`.

Perguntas atendidas:

- Diferencas nas medias de notas entre alunos de capitais e do interior.
- Media de notas entre alunos de escolas publicas e privadas por area de conhecimento.


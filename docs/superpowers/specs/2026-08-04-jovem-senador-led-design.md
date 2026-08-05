# Design — Painéis de LED Jovem Senador 2026

**Data:** 04/08/2026
**Status:** aprovado em brainstorming (seções 1 e 2 validadas pelo usuário)
**Contexto completo:** ver [CONTEXTO-JOVEM-SENADOR.md](../../../CONTEXTO-JOVEM-SENADOR.md)

## Objetivo

Dois entregáveis para a solenidade do Jovem Senador 2026 no Salão Negro:

1. **Simulador do palco** — visualização interativa de como ficará a
   estrutura de painéis de LED rodando os 4 vídeos já produzidos pela CODIV.
2. **Pipeline do vídeo manifesto** — produção do vídeo novo (~4min15s) do
   roteiro técnico da projeção, via Higgsfield, bloco a bloco.

## Fatos que ancoram o design

### Estrutura física (confirmada no croqui do PPTX)

| Superfície | Medida | Pixel map | Vídeo CODIV |
| --- | --- | --- | --- |
| Painel principal | 6,0 × 3,5 m | 1534×768 @60fps | `Telão - Identidade Visual.mp4` (2:00) |
| Testeira superior | 8,0 × 1,0 m | 2046×178 @30fps | `Testeira 1.mp4` (1:00) |
| 6 painéis verticais | 0,80 × 2,50 m cada | 256×384 @30fps | `Vídeo Tela Alunos.mp4` (4:04) |
| Rodapé frontal | 6,0 × 0,50 m | 2046×180 @30fps | `tela_bandeiras.mp4` (1:06) |

- Local: Salão Negro do Congresso; treliça box truss; 44 m² de LED; sem
  intervenção permanente.
- Identidade: azul Senado + laranja vibrante; árvore de letras; Helvetica
  (atual) / Baskerville (histórica); somente elementos gráficos oficiais.

### Restrições

- Conta Higgsfield atual: plano free, 10 créditos → **produção do manifesto
  só começa após upgrade da conta pelo usuário** (decisão do usuário:
  "vou fazer upgrade antes").
- Os 10 créditos atuais não serão gastos.
- A pasta não é repositório git.

## Entregável 1 — Simulador do palco (`simulador-palco.html`)

Arquivo HTML único, sem dependências externas, aberto direto no navegador.
Referencia os 4 MP4s por caminho relativo (mesma pasta).

**Cena** — palco em escala física real conforme o croqui:

- Painel principal ao fundo; testeira no topo da treliça; 3 painéis
  verticais de cada lado, em leque; rodapé na face frontal do praticável.
- Ambiente Salão Negro estilizado (fundo escuro, sugestão de mármore e
  treliças, tapete vermelho) — contexto cênico discreto que não compete com
  os painéis.

**Vistas** — toggle entre:

1. **Frontal**: elevação técnica com réguas/medidas físicas por superfície.
2. **Perspectiva**: palco em ângulo (CSS 3D transforms), como no croqui.

Os vídeos continuam tocando ao alternar de vista (mesmos elementos `<video>`,
apenas re-estilizados).

**Mapeamento vídeo → superfície:**

| Superfície | Fonte | Observação |
| --- | --- | --- |
| Painel principal | `Telão - Identidade Visual.mp4` | — |
| Testeira | `Testeira 1.mp4` | — |
| 6 verticais | `Vídeo Tela Alunos.mp4` | mesma fonte nas 6 telas (1 elemento de vídeo, 6 superfícies via canvas/clonagem visual, para não decodificar 6 streams) |
| Rodapé | `tela_bandeiras.mp4` | — |

**Controles:** play/pause geral · reiniciar (todos a 00:00) · mute/volume.
Durações diferem → **loop individual por vídeo** (comportamento de LED real
em evento).

**Preenchimento das superfícies:** a geometria de cada superfície segue as
medidas físicas; o vídeo **estica para preencher a superfície inteira**
(`object-fit: fill`), replicando o comportamento do processador de LED, que
mapeia o pixel map no painel independentemente da proporção física (ex.:
testeira física 8:1 recebendo conteúdo 11,5:1).

**Tratamento de erros:** se um MP4 não carregar, a superfície exibe
placeholder com o nome do arquivo esperado; a página continua funcional.

**Critério de sucesso:** abrir o HTML, ver o palco nas duas vistas com os 4
vídeos rodando nas superfícies corretas, proporções fiéis às medidas físicas.

## Entregável 2 — Pipeline do vídeo manifesto

**Pré-condição:** upgrade da conta Higgsfield (ação do usuário). Até lá, os
prompts ficam escritos e aprovados, prontos para disparar.

**Escopo:** vídeo do manifesto (~4min15s, 4 blocos do roteiro), priorizando a
**tela central (1534×768)**. Grafismos de testeira/rodapé/verticais
reaproveitam os vídeos CODIV e técnicas programáticas (bandeiras/letreiros
são mais fiéis e baratos feitos localmente).

**Pipeline por bloco (×4):**

1. **Imagens-chave** — 2–3 keyframes por bloco (`generate_image`), seguindo o
   roteiro: árvore de letras Baskerville sobre azul profundo (B1); onda
   laranja + mosaico de rostos (B2); Congresso/plenário imersivo (B3);
   logomarca + árvore dourada (B4). **Gate: aprovação do usuário antes de
   animar.**
2. **Animação** — image-to-video (`generate_video`) dos keyframes aprovados;
   clipes de 5–10s por cena.
3. **Adequação ao LED** — `reframe`/`upscale_video` no conector + ajuste
   local para 1534×768.
4. **Montagem** — concatenação na linha do tempo dos 4 blocos
   (00:00–04:15) com ffmpeg local (skill
   `digitalsamba/claude-code-video-toolkit@ffmpeg`).

**Fora do escopo desta fase:** trilha sonora e locução (o roteiro prevê
locução profissional; uma guia por `generate_audio` pode ser gerada depois,
sob demanda).

**Critério de sucesso:** 1 MP4 1534×768 por bloco + 1 MP4 concatenado de
~4min15s fiel ao roteiro, capaz de rodar no simulador no lugar do vídeo de
identidade visual.

## Ordem de implementação

1. Simulador do palco (não depende de créditos nem de upgrade).
2. Prompts dos 4 blocos do manifesto (documento de produção).
3. Produção Higgsfield (bloqueada até o upgrade da conta).

## Decisões registradas

| Decisão | Escolha | Alternativas descartadas |
| --- | --- | --- |
| Estrutura dos painéis | Croqui real do PPTX (confirmado) | Inferência por resoluções |
| Créditos Higgsfield | Upgrade antes da produção | Teste mínimo com 10 créditos; construção 100% programática; híbrido |
| Formato da visualização | Simulador HTML interativo | MP4 renderizado; ambos |
| Vistas do simulador | Frontal + perspectiva (toggle) | Só frontal; só perspectiva |

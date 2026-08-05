# Simulador do Palco LED + Prompts do Manifesto — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Entregar `simulador-palco.html` (palco do Salão Negro com os 4 vídeos CODIV rodando nas superfícies de LED, vistas frontal e perspectiva) e o documento de prompts de produção do vídeo manifesto (4 blocos, Higgsfield).

**Architecture:** Página HTML única, sem dependências externas. Geometria das superfícies derivada das medidas físicas reais (croqui) via constante CSS `--m` (pixels por metro). Um elemento `<video>` por arquivo; as 6 telas verticais compartilham 1 vídeo desenhado em 6 `<canvas>` por `requestAnimationFrame`. Toggle de vista = troca de classe CSS (mesmo DOM; vídeos não param). Entregável 2 é documento markdown (nenhum crédito Higgsfield é gasto nesta fase).

**Tech Stack:** HTML/CSS/JS puro · Python `http.server` para preview local (vídeo exige range requests) · git.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-04-jovem-senador-led-design.md` — não contrariar decisões registradas.
- `simulador-palco.html` fica na **raiz da pasta** (mesmo diretório dos MP4s), referencia vídeos por **caminho relativo** e **não usa nenhum recurso externo** (CDN, fontes remotas, fetch).
- Nomes de arquivo com acento/espaço: definir `src` sempre via JS `encodeURI(nome)` — nunca hardcoded percent-encoded no HTML.
- Medidas físicas (verbatim do spec): painel principal **6,0 × 3,5 m**; testeira **8,0 × 1,0 m**; 6 verticais **0,80 × 2,50 m** cada; rodapé **6,0 × 0,50 m**.
- Mapeamento vídeo→superfície (verbatim): principal=`Telão - Identidade Visual.mp4`, testeira=`Testeira 1.mp4`, verticais=`Vídeo Tela Alunos.mp4`, rodapé=`tela_bandeiras.mp4`.
- Vídeo preenche a superfície inteira: `object-fit: fill` (canvas: `drawImage` no retângulo todo).
- Loop individual por vídeo; iniciar **mudo** (política de autoplay dos navegadores).
- Paleta (constantes do projeto): `--azul-profundo:#071B36`, `--azul-senado:#0A2E5C`, `--laranja:#F07D00`, `--dourado:#E3A82B`. UI em pt-BR.
- Commits: formato convencional (`feat:`, `docs:`), identidade `-c user.name="Clovis Sabino" -c user.email="limajrsab@gmail.com"` (git local sem identidade global).
- Produção Higgsfield **bloqueada** até upgrade da conta — nenhuma chamada `generate_*` neste plano.

---

### Task 1: Esqueleto da página + servidor de preview

**Files:**
- Create: `simulador-palco.html`
- Create: `.claude/launch.json`

**Interfaces:**
- Produces: estrutura DOM que as Tasks 2–4 preenchem — `<div class="scene">` contendo `<div class="stage">`, barra `<header class="topbar">` e `<footer class="controls">`; variáveis CSS `--m`, paleta e classe `view-frontal` no `<body>`.

- [ ] **Step 1: Criar `.claude/launch.json`** (servidor estático para os MP4s com range requests)

```json
{
  "version": "0.0.1",
  "configurations": [
    {
      "name": "simulador",
      "runtimeExecutable": "python",
      "runtimeArgs": ["-m", "http.server", "8123"],
      "port": 8123
    }
  ]
}
```

- [ ] **Step 2: Criar `simulador-palco.html` com esqueleto**

```html
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Simulador — Painéis de LED · Jovem Senador 2026</title>
<style>
  :root {
    --m: 96px;                 /* pixels por metro (escala física) */
    --azul-profundo: #071B36;
    --azul-senado:  #0A2E5C;
    --laranja:      #F07D00;
    --dourado:      #E3A82B;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: radial-gradient(ellipse at 50% 30%, #10233f 0%, var(--azul-profundo) 55%, #04101f 100%);
    color: #dce6f2;
    font-family: "Segoe UI", Helvetica, Arial, sans-serif;
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    overflow-x: hidden;
  }
  .topbar {
    display: flex; align-items: center; justify-content: space-between;
    padding: 10px 18px;
    background: rgba(4, 12, 24, .65);
    border-bottom: 2px solid var(--laranja);
  }
  .topbar h1 { font-size: 15px; font-weight: 600; letter-spacing: .04em; }
  .topbar h1 span { color: var(--laranja); }
  .viewport { flex: 1; display: grid; place-items: center; padding: 24px 12px; }
  .scene { position: relative; }
  .stage { position: relative; }
  .controls {
    display: flex; gap: 10px; align-items: center; justify-content: center;
    padding: 10px; background: rgba(4, 12, 24, .65);
    border-top: 1px solid #1d3a5f;
  }
  .controls button {
    background: var(--azul-senado); color: #fff; border: 1px solid #2c5f96;
    padding: 8px 14px; border-radius: 6px; cursor: pointer; font-size: 13px;
  }
  .controls button:hover { background: #12467e; }
  .controls button.ativo { background: var(--laranja); border-color: var(--dourado); }
</style>
</head>
<body class="view-frontal">
  <header class="topbar">
    <h1>JOVEM <span>SENADOR</span> 2026 · Simulador dos Painéis de LED — Salão Negro</h1>
  </header>
  <main class="viewport">
    <div class="scene">
      <div class="stage"><!-- superfícies entram na Task 2 --></div>
    </div>
  </main>
  <footer class="controls"><!-- controles entram na Task 3 --></footer>
  <script>
    // preenchido nas Tasks 2-4
  </script>
</body>
</html>
```

- [ ] **Step 3: Verificar no navegador**

Iniciar preview (`preview_start` name `simulador`), navegar para `http://localhost:8123/simulador-palco.html`, tirar screenshot.
Esperado: página escura com topbar "JOVEM SENADOR 2026…" e rodapé vazio; sem erros no console.

- [ ] **Step 4: Commit**

```bash
git add simulador-palco.html .claude/launch.json
git -c user.name="Clovis Sabino" -c user.email="limajrsab@gmail.com" commit -m "feat: esqueleto do simulador de painéis de LED"
```

---

### Task 2: Vista frontal — superfícies em escala + vídeos

**Files:**
- Modify: `simulador-palco.html` (bloco `<style>`, `<div class="stage">` e `<script>`)

**Interfaces:**
- Consumes: DOM da Task 1 (`.scene`, `.stage`, `--m`).
- Produces: função JS `iniciarVideos()` (chamada no load; retorna void); elementos `video#vPrincipal, video#vTesteira, video#vRodape, video#vAlunos` (este último `hidden`); 6 `canvas.vertical` (256×384 internos); atributo `data-arquivo` em cada superfície (usado pela Task 3 no placeholder de erro).

- [ ] **Step 1: CSS das superfícies em escala física** (adicionar ao `<style>`)

```css
  /* dimensões físicas -> px via --m */
  .stage {
    width: calc(var(--m) * 12);         /* cena ~12 m de largura */
    height: calc(var(--m) * 6.2);
  }
  .surf {
    position: absolute; overflow: hidden;
    background: #000; border: 2px solid #16273f;
    box-shadow: 0 0 24px rgba(240, 125, 0, .12), inset 0 0 8px #000;
  }
  .surf video, .surf canvas { width: 100%; height: 100%; object-fit: fill; display: block; }
  /* testeira 8,0 x 1,0 m — topo, centrada */
  .testeira { width: calc(var(--m) * 8); height: calc(var(--m) * 1);
              left: calc(var(--m) * 2); top: 0; }
  /* painel principal 6,0 x 3,5 m — abaixo da testeira, centrado */
  .principal { width: calc(var(--m) * 6); height: calc(var(--m) * 3.5);
               left: calc(var(--m) * 3); top: calc(var(--m) * 1.3); }
  /* verticais 0,8 x 2,5 m — 3 por lado */
  .vertical { width: calc(var(--m) * .8); height: calc(var(--m) * 2.5);
              top: calc(var(--m) * 1.7); }
  .v1 { left: calc(var(--m) * 0.0); }
  .v2 { left: calc(var(--m) * 0.95); }
  .v3 { left: calc(var(--m) * 1.9); }
  .v4 { right: calc(var(--m) * 1.9); }
  .v5 { right: calc(var(--m) * 0.95); }
  .v6 { right: calc(var(--m) * 0.0); }
  /* praticável + rodapé 6,0 x 0,5 m na face frontal */
  .praticavel { position: absolute; left: calc(var(--m) * 2.2); right: calc(var(--m) * 2.2);
                top: calc(var(--m) * 4.9); height: calc(var(--m) * .3);
                background: linear-gradient(#233a58, #101f35); border-radius: 2px; }
  .rodape { width: calc(var(--m) * 6); height: calc(var(--m) * .5);
            left: calc(var(--m) * 3); top: calc(var(--m) * 5.2); }
  /* réguas de medida (só na vista frontal) */
  .medida { position: absolute; font-size: 11px; color: var(--dourado);
            letter-spacing: .05em; white-space: nowrap; }
  .medida::before { content: "⟵ "; } .medida::after { content: " ⟶"; }
  body:not(.view-frontal) .medida { display: none; }
```

- [ ] **Step 2: Marcação das superfícies** (substituir conteúdo de `.stage`)

```html
<div class="stage">
  <div class="surf testeira" data-arquivo="Testeira 1.mp4">
    <video id="vTesteira" muted loop playsinline></video>
    <span class="medida" style="top:-20px; left:35%">8,0 m × 1,0 m</span>
  </div>
  <div class="surf principal" data-arquivo="Telão - Identidade Visual.mp4">
    <video id="vPrincipal" muted loop playsinline></video>
    <span class="medida" style="bottom:-22px; left:32%">6,0 m × 3,5 m</span>
  </div>
  <div class="surf vertical v1" data-arquivo="Vídeo Tela Alunos.mp4"><canvas width="256" height="384"></canvas></div>
  <div class="surf vertical v2" data-arquivo="Vídeo Tela Alunos.mp4"><canvas width="256" height="384"></canvas></div>
  <div class="surf vertical v3" data-arquivo="Vídeo Tela Alunos.mp4"><canvas width="256" height="384"></canvas>
    <span class="medida" style="bottom:-22px; left:-60%">0,80 × 2,50 m (×6)</span></div>
  <div class="surf vertical v4" data-arquivo="Vídeo Tela Alunos.mp4"><canvas width="256" height="384"></canvas></div>
  <div class="surf vertical v5" data-arquivo="Vídeo Tela Alunos.mp4"><canvas width="256" height="384"></canvas></div>
  <div class="surf vertical v6" data-arquivo="Vídeo Tela Alunos.mp4"><canvas width="256" height="384"></canvas></div>
  <div class="praticavel"></div>
  <div class="surf rodape" data-arquivo="tela_bandeiras.mp4">
    <video id="vRodape" muted loop playsinline></video>
    <span class="medida" style="bottom:-22px; left:35%">6,0 m × 0,50 m</span>
  </div>
  <video id="vAlunos" muted loop playsinline hidden></video>
</div>
```

- [ ] **Step 3: JS `iniciarVideos()`** (no `<script>`)

```js
const FONTES = {
  vPrincipal: "Telão - Identidade Visual.mp4",
  vTesteira:  "Testeira 1.mp4",
  vRodape:    "tela_bandeiras.mp4",
  vAlunos:    "Vídeo Tela Alunos.mp4",
};
const videos = Object.keys(FONTES).map(id => document.getElementById(id));

function iniciarVideos() {
  for (const v of videos) {
    v.src = encodeURI(FONTES[v.id]);
    v.play().catch(() => {/* autoplay mudo raramente falha; controles cobrem */});
  }
  pintarVerticais();
}

function pintarVerticais() {
  const alvo = document.getElementById("vAlunos");
  const telas = [...document.querySelectorAll(".vertical canvas")]
    .map(c => c.getContext("2d"));
  (function quadro() {
    if (alvo.readyState >= 2) {
      for (const ctx of telas)
        ctx.drawImage(alvo, 0, 0, ctx.canvas.width, ctx.canvas.height);
    }
    requestAnimationFrame(quadro);
  })();
}

window.addEventListener("load", iniciarVideos);
```

- [ ] **Step 4: Verificar no navegador**

Recarregar `http://localhost:8123/simulador-palco.html`, aguardar 3s, screenshot.
Esperado: testeira, painel principal, 6 verticais e rodapé **todos com vídeo em movimento**, proporções batendo com as réguas de medida; console sem erros.

- [ ] **Step 5: Commit**

```bash
git add simulador-palco.html
git -c user.name="Clovis Sabino" -c user.email="limajrsab@gmail.com" commit -m "feat: vista frontal com as 4 fontes de vídeo em escala física"
```

---

### Task 3: Controles + placeholders de erro

**Files:**
- Modify: `simulador-palco.html` (`<footer class="controls">`, `<style>`, `<script>`)

**Interfaces:**
- Consumes: `videos` (array da Task 2), atributo `data-arquivo` das superfícies.
- Produces: funções `alternarPlay()`, `reiniciar()`, `alternarMudo()` ligadas aos botões `#btnPlay, #btnReiniciar, #btnMudo`; tratamento de `error` por vídeo → classe `.falha` na(s) superfície(s) correspondente(s).

- [ ] **Step 1: Marcação dos controles** (substituir conteúdo do `<footer>`)

```html
<footer class="controls">
  <button id="btnPlay">⏸ Pausar</button>
  <button id="btnReiniciar">↺ Reiniciar</button>
  <button id="btnMudo">🔇 Com som</button>
  <span style="width:24px"></span>
  <button id="btnVista">Ver em perspectiva</button>
</footer>
```

- [ ] **Step 2: CSS do placeholder de falha** (adicionar ao `<style>`)

```css
  .surf.falha video, .surf.falha canvas { display: none; }
  .surf.falha::after {
    content: "vídeo não encontrado:\A" attr(data-arquivo);
    white-space: pre; display: grid; place-items: center; text-align: center;
    position: absolute; inset: 0; font-size: 11px; line-height: 1.5;
    color: var(--laranja); background: repeating-linear-gradient(
      45deg, #0a1526, #0a1526 8px, #0e1c31 8px, #0e1c31 16px);
  }
```

- [ ] **Step 3: JS dos controles e erros** (adicionar ao `<script>`)

```js
function alternarPlay() {
  const btn = document.getElementById("btnPlay");
  const pausado = videos[0].paused;
  videos.forEach(v => pausado ? v.play() : v.pause());
  btn.textContent = pausado ? "⏸ Pausar" : "▶ Continuar";
}
function reiniciar() {
  videos.forEach(v => { v.currentTime = 0; v.play(); });
  document.getElementById("btnPlay").textContent = "⏸ Pausar";
}
function alternarMudo() {
  const btn = document.getElementById("btnMudo");
  const mudo = videos[0].muted;
  videos.forEach(v => v.muted = !mudo);
  btn.textContent = mudo ? "🔊 Sem som" : "🔇 Com som";
}
document.getElementById("btnPlay").onclick = alternarPlay;
document.getElementById("btnReiniciar").onclick = reiniciar;
document.getElementById("btnMudo").onclick = alternarMudo;

// erro em qualquer vídeo -> placeholder nas superfícies daquele arquivo
for (const v of videos) {
  v.addEventListener("error", () => {
    document.querySelectorAll(`[data-arquivo="${FONTES[v.id]}"]`)
      .forEach(s => s.classList.add("falha"));
  });
}
```

- [ ] **Step 4: Verificar controles e erro no navegador**

1. Clicar "⏸ Pausar" → todos os vídeos congelam; clicar de novo → retomam.
2. Clicar "↺ Reiniciar" → todos voltam a 00:00.
3. No console: `FONTES.vTesteira = "arquivo-inexistente.mp4"; document.getElementById("vTesteira").src = "arquivo-inexistente.mp4";` → superfície da testeira mostra "vídeo não encontrado: Testeira 1.mp4" e a página segue funcional. Recarregar a página depois do teste.

- [ ] **Step 5: Commit**

```bash
git add simulador-palco.html
git -c user.name="Clovis Sabino" -c user.email="limajrsab@gmail.com" commit -m "feat: controles de reprodução e placeholder de erro por superfície"
```

---

### Task 4: Vista em perspectiva + ambientação Salão Negro

**Files:**
- Modify: `simulador-palco.html` (`<style>`, `<script>`, decoração da `.scene`)

**Interfaces:**
- Consumes: `.scene`/`.stage` (Task 1), botão `#btnVista` (Task 3).
- Produces: classes `view-frontal` / `view-perspectiva` no `<body>`; função `alternarVista()`.

- [ ] **Step 1: CSS da perspectiva e ambientação** (adicionar ao `<style>`)

```css
  .viewport { perspective: 1700px; perspective-origin: 50% 42%; }
  .scene { transition: transform .8s ease; transform-style: preserve-3d; }
  body.view-perspectiva .scene {
    transform: rotateX(6deg) rotateY(-16deg) translateZ(-40px);
  }
  body.view-perspectiva .surf { box-shadow: 0 0 34px rgba(240,125,0,.2), inset 0 0 8px #000; }
  /* leque das verticais na perspectiva */
  body.view-perspectiva .v1 { transform: rotateY(32deg); }
  body.view-perspectiva .v2 { transform: rotateY(22deg); }
  body.view-perspectiva .v3 { transform: rotateY(12deg); }
  body.view-perspectiva .v4 { transform: rotateY(-12deg); }
  body.view-perspectiva .v5 { transform: rotateY(-22deg); }
  body.view-perspectiva .v6 { transform: rotateY(-32deg); }
  /* ambientação: piso refletido + tapete + treliça sugerida */
  .piso { position: absolute; left: -8%; right: -8%; top: calc(var(--m) * 5.7);
          height: calc(var(--m) * 1.6);
          background: linear-gradient(#0c1a2e 0%, #04101f 90%); opacity: .9; }
  .tapete { position: absolute; left: 46%; width: 8%; top: calc(var(--m) * 5.7);
            height: calc(var(--m) * 1.6);
            background: linear-gradient(#5e1414, #340808); }
  .trelica { position: absolute; width: calc(var(--m) * .18);
             top: 0; height: calc(var(--m) * 5.2);
             background: repeating-linear-gradient(0deg, #202b3a 0 10px, #0d1520 10px 20px);
             border: 1px solid #2a3950; }
  .trelica.esq { left: calc(var(--m) * 2.6); }
  .trelica.dir { right: calc(var(--m) * 2.6); }
```

- [ ] **Step 2: Marcação da ambientação** (dentro de `.scene`, antes de `.stage`)

```html
<div class="piso"></div>
<div class="tapete"></div>
<div class="trelica esq"></div>
<div class="trelica dir"></div>
```

- [ ] **Step 3: JS do toggle** (adicionar ao `<script>`)

```js
function alternarVista() {
  const b = document.body, btn = document.getElementById("btnVista");
  const paraPerspectiva = b.classList.contains("view-frontal");
  b.classList.toggle("view-frontal", !paraPerspectiva);
  b.classList.toggle("view-perspectiva", paraPerspectiva);
  btn.textContent = paraPerspectiva ? "Ver vista frontal" : "Ver em perspectiva";
  btn.classList.toggle("ativo", paraPerspectiva);
}
document.getElementById("btnVista").onclick = alternarVista;
```

- [ ] **Step 4: Verificar no navegador**

1. Clicar "Ver em perspectiva" → cena gira suavemente, verticais abrem em leque, vídeos **continuam tocando** durante e após a transição.
2. Voltar para frontal → réguas de medida reaparecem (só existem na frontal).
3. Screenshot das duas vistas para registro.

- [ ] **Step 5: Commit**

```bash
git add simulador-palco.html
git -c user.name="Clovis Sabino" -c user.email="limajrsab@gmail.com" commit -m "feat: vista em perspectiva com ambientação do Salão Negro"
```

---

### Task 5: QA final do simulador

**Files:**
- Modify: `simulador-palco.html` (apenas correções achadas no QA)

**Interfaces:**
- Consumes: página completa (Tasks 1–4).
- Produces: simulador validado; screenshots de evidência enviadas ao usuário.

- [ ] **Step 1: Checklist de QA no navegador**

1. Recarregar com cache limpo (`Ctrl+F5`). Console: zero erros.
2. Vista frontal: 9 superfícies com vídeo (1 testeira + 1 principal + 6 verticais + 1 rodapé); proporções conferidas contra as réguas.
3. Deixar rodando 90s: vídeos de 1:00/1:06 reiniciam sozinhos (loop individual) sem travar os demais.
4. Alternar vistas 3× seguidas: sem flicker, vídeos sem pausa.
5. Redimensionar a janela (~1000px de largura): cena permanece visível sem scroll horizontal (se estourar, reduzir `--m` via media query: `@media (max-width: 1280px) { :root { --m: 72px; } }`).

- [ ] **Step 2: Corrigir problemas achados e re-verificar** (repetir Step 1 até limpo)

- [ ] **Step 3: Enviar evidência ao usuário** (SendUserFile com screenshots frontal + perspectiva)

- [ ] **Step 4: Commit final**

```bash
git add simulador-palco.html
git -c user.name="Clovis Sabino" -c user.email="limajrsab@gmail.com" commit -m "fix: ajustes de QA do simulador"
```

---

### Task 6: Documento de produção do manifesto (prompts dos 4 blocos)

**Files:**
- Create: `docs/producao-manifesto-prompts.md`

**Interfaces:**
- Consumes: roteiro (`ROTEIRO TÉCNICO PROJEÇÃO MANIFESTO JOVEM SENADOR.docx`, resumido em `CONTEXTO-JOVEM-SENADOR.md` §4).
- Produces: documento pronto-para-disparar quando a conta Higgsfield for atualizada; nenhuma chamada de geração é feita nesta task.

- [ ] **Step 1: Criar `docs/producao-manifesto-prompts.md`** com o conteúdo abaixo (íntegra):

```markdown
# Produção do Vídeo Manifesto — Prompts e Pipeline (Higgsfield)

**Alvo:** tela central 1534×768 (painel 6,0×3,5 m) · ~4min15s · 4 blocos.
**Pré-condição:** conta Higgsfield com créditos (upgrade feito). Verificar
com `balance` antes de qualquer geração; se < 100 créditos, parar e avisar.
**Regra de ouro:** gerar imagens-chave primeiro → aprovação do usuário →
só então animar (image-to-video). Nunca gerar vídeo direto de texto.

## Parâmetros globais

- Estilo: motion design institucional, azul profundo #071B36 / #0A2E5C,
  laranja #F07D00, dourado #E3A82B; linguagem contemporânea, sem fotorealismo
  de pessoas (rostos reais entram só nos vídeos CODIV já existentes).
- Aspect: gerar em 16:9 e depois `reframe` para 2:1 (1534×768); revisar corte.
- Duração-alvo dos clipes: 5–10 s; ~8–10 clipes no total.

## Bloco 1 — A Semente e o Conhecimento (00:00–01:00)

Keyframes (`generate_image`):
1. "Deep dark blue background (#071B36). Classic Baskerville serif letters
   floating fluidly, gathering to form the trunk and first branches of an
   elegant tree made of typography. Subtle paper texture rising from below.
   Institutional motion-design style, cinematic lighting, orange (#F07D00)
   accent line pulsing at the bottom."
2. "The typographic tree half-formed, letters ascending like seeds of
   knowledge, deep blue gradient, delicate golden glow on branch tips."
Motion (image-to-video): "letters drift upward and assemble slowly, gentle
cinematic push-in, particles of type floating."

## Bloco 2 — As Raízes do Brasil (01:00–02:00)

Keyframes:
1. "A vibrant orange energy wave crossing a deep blue stage screen from left
   to right, dynamic diagonal composition, motion-design style."
2. "Grid mosaic of empty portrait frames in blue and orange with Brazilian
   state flags streaming horizontally along top and bottom edges, modern
   broadcast look." (rostos reais: usar recortes do `Vídeo Tela Alunos.mp4`
   na montagem, não IA)
Motion: "wave sweeps across, frames light up sequentially, flags run
horizontally at constant speed."

## Bloco 3 — O Crescimento e a Vivência (02:00–03:15)

Keyframes:
1. "Brazilian National Congress building at dusk, imponent low-angle view,
   deep blue sky, warm golden highlights, cinematic."
2. "Abstract energetic graphics in orange and blue pulsing to a beat, bold
   keywords CIDADANIA, AUTONOMIA, DIÁLOGO, FUTURO, TRANSFORMAÇÃO in modern
   Helvetica-style type, motion-design."
Motion: "slow imposing dolly toward the Congress towers; keywords punch in
rhythmically."
(Cenas de plenário/comissões com pessoas: reaproveitar imagens em vídeo da
CODIV/TV Senado — não gerar pessoas por IA.)

## Bloco 4 — O Manifesto e o Chamado (03:15–04:15)

Keyframes:
1. "Complete Jovem Senador logo centered and imponent on deep blue
   background, stylized golden tree glowing softly below, elegant
   institutional finale, subtle orange light rays."
2. "Six vertical golden stylized trees as glowing columns on deep blue,
   solemn and epic, static composition."
Motion: "logo breathes with soft glow, light rays rotate very slowly,
final settle to static frame" + texto final "senado.leg.br/jovemsenador".

## Montagem (ffmpeg local)

1. Instalar toolkit: `npx skills add digitalsamba/claude-code-video-toolkit@ffmpeg -g -y`
   (traz padrões de concat/scale; requer ffmpeg no PATH — `winget install Gyan.FFmpeg`).
2. Normalizar clipes: `ffmpeg -i clip.mp4 -vf "scale=1534:768:flags=lanczos,fps=30" -an clipN_led.mp4`
3. Concat por lista (`concat demuxer`) seguindo a linha do tempo:
   B1 00:00–01:00 · B2 01:00–02:00 · B3 02:00–03:15 · B4 03:15–04:15.
4. Saída: `manifesto_tela_central_1534x768.mp4` (+ 1 MP4 por bloco).
5. Validar no simulador: trocar `FONTES.vPrincipal` para o novo arquivo.

## Fora do escopo (fase atual)

Trilha sonora e locução profissional (guia por `generate_audio` sob demanda).
```

- [ ] **Step 2: Revisar o documento contra o roteiro** (CONTEXTO §4): cada bloco tem keyframes + motion + janela de tempo correta; nenhuma chamada de geração executada.

- [ ] **Step 3: Commit**

```bash
git add docs/producao-manifesto-prompts.md
git -c user.name="Clovis Sabino" -c user.email="limajrsab@gmail.com" commit -m "docs: prompts e pipeline de produção do vídeo manifesto"
```

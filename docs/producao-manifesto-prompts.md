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

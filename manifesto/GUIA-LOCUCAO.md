# Guia de Regravação das Locuções — Manifesto Jovem Senador 2026

Os arquivos de referência estão nesta pasta e na raiz do projeto:

| Arquivo | O que é |
|---|---|
| `..\manifesto_tela_central_1534x768_locucao.mp4` | Vídeo final ATUAL (com a voz IA a substituir) |
| `..\manifesto_tela_central_1534x768.mp4` | Vídeo MUDO (base limpa para a nova voz) |
| `locucao\b1.wav` … `locucao\b4.wav` | As 4 locuções atuais, separadas (referência de tempo) |

## Textos e janelas (do Roteiro Técnico da CODIV)

Direção de voz: **forte, pausada e inspiradora**. Cada locução deve caber na
janela do seu bloco (há folga generosa em todos).

### Bloco 1 — entra em 0:02 (janela até 1:00 · atual: 10s)
> "Tudo começa com uma ideia. Uma linha escrita em uma folha de papel. Uma
> semente plantada no solo do conhecimento."

### Bloco 2 — entra em 1:02 (janela até 2:00 · atual: 17s)
> "De norte a sul, milhares de vozes se levantam. Estudantes de escolas
> públicas de todos os cantos do país aceitam o desafio de pensar, criticar e
> transformar a realidade. Raízes fortes que sustentam o futuro da nossa
> democracia."

### Bloco 3 — entra em 2:02 (janela até 3:15 · atual: 20s)
> "Em Brasília, a simulação se torna vida. O debate ganha força. A árvore
> cresce, abre seus galhos e floresce. Aqui, as ideias viram propostas, as
> propostas viram debates e o aprendizado gera frutos reais para o ordenamento
> jurídico do nosso país."

### Bloco 4 — entra em 3:17 (janela até 4:15 · atual: 31s)
> "Se há algo que possamos fazer por uma sociedade mais humana e justa, é
> cultivar árvores e cuidar dos nossos jovens! O Jovem Senador é, antes de
> tudo, um Encontro pela Educação Política dos jovens, pela sua formação
> cidadã, pelo seu crescimento enquanto ser pensante e político. Faça parte
> dessa história e participe da construção do Brasil de amanhã!"

## Como trocar a voz (depois de gravar)

1. Salve as novas gravações POR CIMA de `locucao\b1.wav`, `b2.wav`, `b3.wav`
   e `b4.wav` (mesmos nomes; WAV ou renomeie para .wav — MP3 também funciona
   se ajustar os nomes no script).
2. Execute na raiz do projeto:
   ```powershell
   powershell -ExecutionPolicy Bypass -File manifesto\mixar-locucao.ps1
   ```
3. O script regenera `manifesto_tela_central_1534x768_locucao.mp4` com as
   novas vozes nos mesmos pontos da timeline (0:02 / 1:02 / 2:02 / 3:17).
4. O simulador (`simulador-palco.html`) já aponta para esse arquivo — basta
   recarregar a página.

Alternativa sem gravação humana: pedir ao Claude para regerar as locuções com
outro motor de TTS (ex.: variante ElevenLabs, mais natural) e/ou outra voz do
catálogo Higgsfield — custo aproximado de 2 créditos por locução.

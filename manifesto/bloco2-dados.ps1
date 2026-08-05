# Bloco 2 do roteiro v2 — "O coro dos 27": sequencia de dados do programa
# Saida: manifesto\v2\b2_dados.mp4 (1534x768, 30fps, 60s, sem audio)
#
# Todos os numeros sao verificaveis no release oficial js26_release_a4_aa.pdf.
# Uso:  powershell -ExecutionPolicy Bypass -File manifesto\bloco2-dados.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$ffmpeg = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $ffmpeg) { throw "ffmpeg nao encontrado. Instale com: winget install -e --id Gyan.FFmpeg" }

$saida = "manifesto\v2"
New-Item -ItemType Directory -Force -Path $saida | Out-Null

# --- identidade ----------------------------------------------------------
$AZUL    = "0x071B36"
$LARANJA = "0xF07D00"
$DOURADO = "0xE3A82B"
$SANS    = "C\:/Windows/Fonts/arialbd.ttf"
$W = 1534; $H = 768; $FPS = 30; $DUR = 60
$CX = $W / 2

# acentos pelo code point: PowerShell 5.1 le .ps1 sem BOM como ANSI
$cedilha = [char]0x00C7   # C-cedilha
$tilA    = [char]0x00C3   # A-til
$tilO    = [char]0x00D5   # O-til
$agudoU  = [char]0x00DA   # U-agudo
$craseA  = [char]0x00C0   # A-crase

$REDACAO   = "REDA$cedilha${tilA}O"
$PREMIACAO = "PREMIA$cedilha${tilA}O"
$REDACOES  = "REDA$cedilha${tilO}ES"
$ULTIMA    = "${agudoU}LTIMA"
$EDICAO    = "EDI$cedilha${tilA}O"

function Escrever-Utf8SemBom($caminho, $conteudo) {
  [System.IO.File]::WriteAllText($caminho, $conteudo, (New-Object System.Text.UTF8Encoding($false)))
}

# --- helpers de composicao ------------------------------------------------
# texto que entra e sai com fade suave dentro da janela [t0, t1]
function Texto($texto, $tamanho, $cor, $y, $t0, $t1) {
  $fade = 0.7
  $alpha = "if(lt(t,$($t0+$fade)),(t-$t0)/$fade,if(gt(t,$($t1-$fade)),($t1-t)/$fade,1))"
  return "drawtext=fontfile='$SANS':text='$texto':fontcolor=${cor}:fontsize=${tamanho}" +
         ":x=(w-text_w)/2:y=${y}:alpha='$alpha':enable='between(t,$t0,$t1)'"
}

# filete laranja que se desenha do centro para as bordas
function Filete($y, $t0, $t1, $largura) {
  $meio = $largura / 2
  $w = "min($meio,(t-$t0)*420)"
  return "drawbox=x='$CX-$w':y=${y}:w='2*$w':h=5:color=${LARANJA}:t=fill:enable='between(t,$t0,$t1)'"
}

# --- roteiro do bloco (janelas em segundos) -------------------------------
# O funil, do maior para o menor: 2 milhoes -> 170 mil -> 4.202 -> 81 -> 27.
# Numeros de participacao sao da ultima edicao fechada (2025) e vem rotulados
# como tal; 81 e o dado de 2026 (redacoes que chegaram a etapa final).
$cartelas = @(
  @{ num = "4.202";     rot = "ESCOLAS EM TODO O BRASIL NA $ULTIMA $EDICAO"; t0 =  3; t1 = 11 },
  @{ num = "170.000";   rot = "ESTUDANTES SENTARAM PARA ESCREVER";           t0 = 11; t1 = 19 },
  @{ num = "2.000.000"; rot = "ALUNOS MOBILIZADOS DESDE 2008";               t0 = 19; t1 = 27 }
)

$partes = New-Object System.Collections.Generic.List[string]

foreach ($c in $cartelas) {
  $partes.Add((Texto $c.num 190 "white" 210 $c.t0 $c.t1))
  $partes.Add((Filete 470 $c.t0 $c.t1 300))
  $partes.Add((Texto $c.rot 38 $DOURADO 520 $c.t0 $c.t1))
}

# selo: a frase que qualifica o programa (sem numero)
$partes.Add((Texto "O MAIOR CONCURSO DE $REDACAO" 68 "white" 300 27 34))
$partes.Add((Texto "COM $PREMIACAO DO BRASIL" 68 "white" 390 27 34))
$partes.Add((Filete 500 27 34 420))

# 2026: o funil se fecha
$partes.Add((Texto "81" 260 "white" 180 34 42))
$partes.Add((Filete 490 34 42 300))
$partes.Add((Texto "$REDACOES CHEGARAM $craseA ETAPA FINAL EM 2026" 38 $DOURADO 540 34 42))

# as 27 vozes que estao nesta sala
$partes.Add((Texto "27" 300 $LARANJA 150 42 52))
$partes.Add((Filete 500 42 52 260))
$partes.Add((Texto "UMA DE CADA ESTADO. UMA DO DISTRITO FEDERAL." 40 $DOURADO 550 42 52))

# o retrato de quem chega
$partes.Add((Texto "OITO EM CADA DEZ VIERAM DO INTERIOR" 60 "white" 300 52 60))
$partes.Add((Texto "21 DAS 27, NA $ULTIMA $EDICAO, FORAM MENINAS" 44 $DOURADO 400 52 60))

# --- montagem do filtro ---------------------------------------------------
$mapa = "$saida\mapa-brasil.png"
$temMapa = Test-Path $mapa

if ($temMapa) {
  # mapa ao fundo, discreto, respirando devagar
  $cabeca = "[1:v]scale=${W}:-1,format=rgba,colorchannelmixer=aa=0.30[mapa];" +
            "[0:v][mapa]overlay=x=(W-w)/2:y=(H-h)/2[base];[base]"
} else {
  $cabeca = "[0:v]"
}

$filtro = $cabeca + ($partes -join ",") + ",fade=t=in:st=0:d=1.5,fade=t=out:st=57:d=3[out]"
Escrever-Utf8SemBom "$saida\b2.filter" $filtro

$entradas = @("-f", "lavfi", "-i", "color=c=${AZUL}:s=${W}x${H}:d=${DUR}:r=${FPS}")
if ($temMapa) { $entradas += @("-i", $mapa) }

Write-Host "Gerando o bloco 2 (mapa: $(if ($temMapa) { 'sim' } else { 'ausente - fundo liso' }))..."
& $ffmpeg -y -v error @entradas -/filter_complex "$saida\b2.filter" -map "[out]" `
  -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$saida\b2_dados.mp4"

Write-Host "Pronto: $saida\b2_dados.mp4"

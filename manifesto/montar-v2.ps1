# Versao de TRABALHO do manifesto v2 - "A ideia que virou lei"
# Encadeia o que ja existe e marca explicitamente cada lacuna, para que o
# filme possa ser visto de pe no simulador antes do material definitivo.
#
# Saida: manifesto_v2_trabalho_1534x768.mp4 (1534x768, 30fps, 255s, sem audio)
# Uso:   powershell -ExecutionPolicy Bypass -File manifesto\montar-v2.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$ffmpeg = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $ffmpeg) { throw "ffmpeg nao encontrado. Instale com: winget install -e --id Gyan.FFmpeg" }

$v2 = "manifesto\v2"; $trab = "$v2\trabalho"
New-Item -ItemType Directory -Force -Path $trab | Out-Null

$AZUL = "0x071B36"; $LARANJA = "0xF07D00"; $DOURADO = "0xE3A82B"
$SANS = "C\:/Windows/Fonts/arialbd.ttf"
$W = 1534; $H = 768; $FPS = 30

function Escrever-Utf8SemBom($caminho, $conteudo) {
  [System.IO.File]::WriteAllText($caminho, $conteudo, (New-Object System.Text.UTF8Encoding($false)))
}

# --- cartela de lacuna ----------------------------------------------------
# deixa visivel o que ainda falta, com a fonte do material definitivo
function Lacuna($titulo, $fonte, $segundos, $arquivo) {
  $f = "[0:v]drawbox=x=60:y=60:w=iw-120:h=ih-120:color=${LARANJA}@0.5:t=3," +
       "drawtext=fontfile='$SANS':text='A PRODUZIR':fontcolor=${LARANJA}:fontsize=34" +
       ":x=(w-text_w)/2:y=210," +
       "drawtext=fontfile='$SANS':text='$titulo':fontcolor=white:fontsize=62" +
       ":x=(w-text_w)/2:y=300," +
       "drawtext=fontfile='$SANS':text='$fonte':fontcolor=${DOURADO}:fontsize=34" +
       ":x=(w-text_w)/2:y=430," +
       "drawtext=fontfile='$SANS':text='${segundos}s':fontcolor=${LARANJA}:fontsize=44" +
       ":x=(w-text_w)/2:y=520[out]"
  Escrever-Utf8SemBom "$trab\lac.filter" $f
  & $ffmpeg -y -v error -f lavfi -i "color=c=${AZUL}:s=${W}x${H}:d=${segundos}:r=${FPS}" `
    -/filter_complex "$trab\lac.filter" -map "[out]" `
    -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\$arquivo"
}

# --- concatena uma lista de arquivos e corta na duracao exata -------------
function Bloco($arquivos, $duracao, $arquivo) {
  $linhas = $arquivos | ForEach-Object { "file '$((Resolve-Path $_).Path -replace '\\','/')'" }
  Escrever-Utf8SemBom "$trab\lista.txt" (($linhas -join "`n") + "`n")
  & $ffmpeg -y -v error -f concat -safe 0 -i "$trab\lista.txt" -t $duracao `
    -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\$arquivo"
  Write-Host "  $arquivo ($duracao s)"
}

Write-Host "Montando a versao de trabalho do v2..."

# BLOCO 1 (50s) - a folha em branco ainda nao existe; entram os clipes de
# letras formando a arvore, que sao o material mais proximo.
Lacuna "A FOLHA EM BRANCO" "CARTEIRA DE ESCOLA - GERAR OU FILMAR" 6 "lac_b1.mp4"
$b1 = @("$trab\lac_b1.mp4") + (1..3 | ForEach-Object { @("manifesto\norm\b1a.mp4", "manifesto\norm\b1b.mp4") })
Bloco $b1 50 "b1.mp4"

# BLOCO 2 (60s) - completo
Bloco @("$v2\b2_dados.mp4") 60 "b2.mp4"

# BLOCO 3 (75s) - cartelas prontas; faltam as imagens da Semana de Vivencia
Lacuna "SEMANA DE VIVENCIA" "COMISSOES, PLENARIO, SALAO NEGRO - ACERVO CODIV" 6 "lac_b3.mp4"
$b3 = @("$v2\b3_cartelas.mp4", "$trab\lac_b3.mp4") + (1..3 | ForEach-Object { @("manifesto\norm\b3a.mp4", "manifesto\norm\b3b.mp4") })
Bloco $b3 75 "b3.mp4"

# BLOCO 4 (70s) - provas prontas; fecho com a arvore dourada
$b4 = @("$v2\b4_provas.mp4") + (1..3 | ForEach-Object { @("manifesto\norm\b4a.mp4", "manifesto\norm\b4b.mp4") })
Bloco $b4 70 "b4.mp4"

# --- filme completo -------------------------------------------------------
Write-Host "Concatenando os 4 blocos..."
$blocos = @("b1","b2","b3","b4") | ForEach-Object { "file '$((Resolve-Path "$trab\$_.mp4").Path -replace '\\','/')'" }
Escrever-Utf8SemBom "$trab\blocos.txt" (($blocos -join "`n") + "`n")

& $ffmpeg -y -v error -f concat -safe 0 -i "$trab\blocos.txt" -t 255 `
  -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "manifesto_v2_trabalho_1534x768.mp4"

Write-Host ""
Write-Host "Pronto: manifesto_v2_trabalho_1534x768.mp4"

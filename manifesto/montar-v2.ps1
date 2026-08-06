# Versao de TRABALHO do manifesto v2 - "A ideia que virou lei"
#
# Estrutura: a arvore e a espinha do filme e cresce atraves dele (raiz ->
# tronco -> galhos -> copa cheia), com os blocos de texto conduzindo a
# narrativa entre os estagios. As lacunas de material aparecem marcadas.
#
# Saida: manifesto_v2_trabalho_1534x768.mp4 (1534x768, 30fps, 255s, sem audio)
# Uso:   powershell -ExecutionPolicy Bypass -File manifesto\montar-v2.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$ffmpeg = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $ffmpeg) { throw "ffmpeg nao encontrado. Instale com: winget install -e --id Gyan.FFmpeg" }

$v2 = "manifesto\v2"; $trab = "$v2\trabalho"; $arv = "$v2\arvore"
New-Item -ItemType Directory -Force -Path $trab | Out-Null

$AZUL = "0x071B36"; $LARANJA = "0xF07D00"; $DOURADO = "0xE3A82B"
$SANS = "C\:/Windows/Fonts/arialbd.ttf"
$W = 1534; $H = 768; $FPS = 30

function Escrever-Utf8SemBom($caminho, $conteudo) {
  [System.IO.File]::WriteAllText($caminho, $conteudo, (New-Object System.Text.UTF8Encoding($false)))
}

# --- cartela de lacuna: deixa visivel o que ainda falta -------------------
function Lacuna($titulo, $fonte, $segundos, $arquivo) {
  $f = "[0:v]drawbox=x=60:y=60:w=iw-120:h=ih-120:color=${LARANJA}@0.5:t=3," +
       "drawtext=fontfile='$SANS':text='A PRODUZIR':fontcolor=${LARANJA}:fontsize=34:x=(w-text_w)/2:y=210," +
       "drawtext=fontfile='$SANS':text='$titulo':fontcolor=white:fontsize=58:x=(w-text_w)/2:y=300," +
       "drawtext=fontfile='$SANS':text='$fonte':fontcolor=${DOURADO}:fontsize=32:x=(w-text_w)/2:y=430," +
       "drawtext=fontfile='$SANS':text='${segundos}s':fontcolor=${LARANJA}:fontsize=44:x=(w-text_w)/2:y=520[out]"
  Escrever-Utf8SemBom "$trab\lac.filter" $f
  & $ffmpeg -y -v error -f lavfi -i "color=c=${AZUL}:s=${W}x${H}:d=${segundos}:r=${FPS}" `
    -/filter_complex "$trab\lac.filter" -map "[out]" `
    -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\$arquivo"
}

# --- concatena uma lista e corta na duracao exata --------------------------
function Bloco($arquivos, $duracao, $arquivo) {
  $linhas = $arquivos | ForEach-Object { "file '$((Resolve-Path $_).Path -replace '\\','/')'" }
  Escrever-Utf8SemBom "$trab\lista.txt" (($linhas -join "`n") + "`n")
  & $ffmpeg -y -v error -f concat -safe 0 -i "$trab\lista.txt" -t $duracao `
    -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\$arquivo"
  Write-Host "  $arquivo ($duracao s)"
}

# repete um clipe ate cobrir a janela desejada
function Repetir($clipe, $vezes) { return (1..$vezes | ForEach-Object { $clipe }) }

Write-Host "Montando a versao de trabalho do v2..."

# --- BLOCO 1 (50s) - A ABERTURA: A ARVORE CRESCENDO ------------------------
# a folha em branco (a produzir) e, na sequencia, o crescimento progressivo:
# raiz -> tronco -> galhos. E a unica parte do manifesto original que fica.
Lacuna "A FOLHA EM BRANCO" "CARTEIRA DE ESCOLA - GERAR OU FILMAR" 26 "lac_b1.mp4"
$b1 = @("$trab\lac_b1.mp4", "$arv\n_1_raiz.mp4", "$arv\n_2_tronco.mp4", "$arv\n_3_galhos.mp4")
Bloco $b1 50 "b1.mp4"

# --- BLOCO 2 (60s) - OS DADOS ---------------------------------------------
$b2 = @("$v2\b2_dados.mp4")
Bloco $b2 60 "b2.mp4"

# --- BLOCO 3 (75s) - A CASA, OS NOMES E AS PALAVRAS -----------------------
# os blocos de texto dando sequencia a narrativa
$b3 = @("$v2\b3_cartelas.mp4", "$v2\b3_palavras.mp4") + (Repetir "$arv\n_3_galhos.mp4" 2)
Bloco $b3 75 "b3.mp4"

# --- BLOCO 4 (70s) - A VIVENCIA E A COPA CHEIA ----------------------------
# a prova, os registros da vivencia e o fecho com a arvore plena
Lacuna "REGISTROS DA VIVENCIA" "COMISSOES, PLENARIO, SALAO NEGRO - ACERVO CODIV" 20 "lac_b4.mp4"
$b4 = @("$v2\b4_provas.mp4", "$trab\lac_b4.mp4") + (Repetir "$arv\n_4_copa.mp4" 4)
Bloco $b4 70 "b4.mp4"

# --- filme completo -------------------------------------------------------
Write-Host "Concatenando os 4 blocos..."
$blocos = @("b1","b2","b3","b4") | ForEach-Object { "file '$((Resolve-Path "$trab\$_.mp4").Path -replace '\\','/')'" }
Escrever-Utf8SemBom "$trab\blocos.txt" (($blocos -join "`n") + "`n")

& $ffmpeg -y -v error -f concat -safe 0 -i "$trab\blocos.txt" -t 255 `
  -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "manifesto_v2_trabalho_1534x768.mp4"

Write-Host ""
Write-Host "Pronto: manifesto_v2_trabalho_1534x768.mp4"

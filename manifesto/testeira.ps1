# Gera a testeira animada do manifesto (2046x178, 30fps, 255s, sem audio)
# sincronizada com os 4 blocos do Roteiro Tecnico:
#   B1 00:00-01:00  conceito central em "maquina de escrever"
#   B2 01:00-02:00  bandeiras dos estados correndo (video da CODIV)
#   B3 02:00-03:15  logo Jovem Senador em motion design (marquee)
#   B4 03:15-04:15  marca institucional SENADO FEDERAL
#
# Uso:  powershell -ExecutionPolicy Bypass -File manifesto\testeira.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

# --- ffmpeg (instalado via winget) ---------------------------------------
$ffmpeg = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $ffmpeg) { throw "ffmpeg nao encontrado. Instale com: winget install -e --id Gyan.FFmpeg" }

$trab = "manifesto\testeira"
New-Item -ItemType Directory -Force -Path $trab | Out-Null

# --- constantes de identidade --------------------------------------------
$AZUL     = "0x071B36"   # azul escuro profundo (fundo)
$LARANJA  = "0xF07D00"   # laranja vibrante
$DOURADO  = "0xE3A82B"
$SERIF    = "C\:/Windows/Fonts/georgia.ttf"
$SANS     = "C\:/Windows/Fonts/arialbd.ttf"
$W = 2046; $H = 178; $FPS = 30

function Escrever-Utf8SemBom($caminho, $conteudo) {
  [System.IO.File]::WriteAllText($caminho, $conteudo, (New-Object System.Text.UTF8Encoding($false)))
}

# --- marcas oficiais recortadas do video da CODIV -------------------------
Write-Host "[1/6] Extraindo marcas oficiais de 'Testeira 1.mp4'..."
& $ffmpeg -y -v error -ss 2 -i "Testeira 1.mp4" -frames:v 1 -vf "crop=542:84:239:48" "$trab\logo.png"
# a marca do Senado e branca sobre roxo: remove o roxo para compor sobre o azul
& $ffmpeg -y -v error -ss 2 -i "Testeira 1.mp4" -frames:v 1 `
  -vf "crop=580:70:1231:54,colorkey=0x8B4BEE:0.34:0.05" "$trab\senado.png"

# --- BLOCO 1: maquina de escrever ----------------------------------------
Write-Host "[2/6] Bloco 1 - conceito central em maquina de escrever..."
# o "I" acentuado vem pelo code point: PowerShell 5.1 le .ps1 sem BOM como ANSI
# e corromperia o caractere antes de chegar ao ffmpeg
$frase = "O CONHECIMENTO E O EXERC" + [char]0x00CD + "CIO DA CIDADANIA"
$xTexto = 700; $fonte = 46
$inicioDigitacao = 2.0; $porChar = 0.28
$posicao = "x=${xTexto}:y=(h-text_h)/2"

$f = New-Object System.Text.StringBuilder
[void]$f.AppendLine("[0:v][1:v]overlay=x=70:y=(H-h)/2[base];")
$cadeia = "[base]"
# digitacao: cada trecho aparece com o cursor logo apos a ultima letra
for ($i = 1; $i -le $frase.Length; $i++) {
  $t0 = $inicioDigitacao + ($i - 1) * $porChar
  $t1 = $inicioDigitacao + $i * $porChar
  $trecho = $frase.Substring(0, $i) + "_"
  $rotulo = "d$i"
  [void]$f.AppendLine("$cadeia" + "drawtext=fontfile='$SERIF':text='$trecho':fontcolor=white:fontsize=$fonte" +
    ":${posicao}:enable='between(t,$t0,$t1)'[$rotulo];")
  $cadeia = "[$rotulo]"
}
# apos digitar: frase completa, com cursor piscando a cada meio segundo
$fimDigitacao = $inicioDigitacao + $frase.Length * $porChar
[void]$f.AppendLine("$cadeia" + "drawtext=fontfile='$SERIF':text='${frase}_':fontcolor=white:fontsize=$fonte" +
  ":${posicao}:enable='gt(t,$fimDigitacao)*gt(sin(2*PI*t),0)'[pisca1];")
[void]$f.AppendLine("[pisca1]drawtext=fontfile='$SERIF':text='$frase':fontcolor=white:fontsize=$fonte" +
  ":${posicao}:enable='gt(t,$fimDigitacao)*lte(sin(2*PI*t),0)'[pisca2];")
[void]$f.AppendLine("[pisca2]fade=t=in:st=0:d=1,fade=t=out:st=57:d=3[out]")
Escrever-Utf8SemBom "$trab\b1.filter" $f.ToString()

& $ffmpeg -y -v error -f lavfi -i "color=c=$AZUL`:s=$W`x$H`:d=60:r=$FPS" -i "$trab\logo.png" `
  -/filter_complex "$trab\b1.filter" -map "[out]" -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\b1.mp4"

# --- BLOCO 2: bandeiras dos estados (asset da CODIV) ---------------------
Write-Host "[3/6] Bloco 2 - bandeiras dos estados..."
& $ffmpeg -y -v error -stream_loop -1 -i "tela_bandeiras.mp4" -t 60 `
  -vf "crop=$W`:$H`:0:1,fps=$FPS,setsar=1" -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\b2.mp4"

# --- BLOCO 3: logo em motion design (marquee) ----------------------------
Write-Host "[4/6] Bloco 3 - logo Jovem Senador em motion..."
$unidade = "JOVEM SENADOR 2026        "
$repetido = $unidade * 8
$f3 = "[0:v]drawtext=fontfile='$SANS':text='$repetido':fontcolor=$LARANJA" + ":fontsize=56" +
      ":x='-mod(t*160\,text_w/8)':y=(h-text_h)/2[m];" +
      "[m]drawbox=x=0:y=0:w=iw:h=4:color=$DOURADO" + "@0.75:t=fill," +
      "drawbox=x=0:y=ih-4:w=iw:h=4:color=$DOURADO" + "@0.75:t=fill," +
      "fade=t=in:st=0:d=1,fade=t=out:st=72:d=3[out]"
Escrever-Utf8SemBom "$trab\b3.filter" $f3

& $ffmpeg -y -v error -f lavfi -i "color=c=$AZUL`:s=$W`x$H`:d=75:r=$FPS" `
  -/filter_complex "$trab\b3.filter" -map "[out]" -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\b3.mp4"

# --- BLOCO 4: marca institucional SENADO FEDERAL -------------------------
Write-Host "[5/6] Bloco 4 - marca SENADO FEDERAL..."
$f4 = "[0:v][1:v]overlay=x=(W-w)/2:y=(H-h)/2[m];" +
      "[m]drawbox=x=0:y=ih-3:w=iw:h=3:color=$DOURADO" + "@0.9:t=fill," +
      "fade=t=in:st=0:d=2[out]"
Escrever-Utf8SemBom "$trab\b4.filter" $f4

& $ffmpeg -y -v error -f lavfi -i "color=c=$AZUL`:s=$W`x$H`:d=60:r=$FPS" -i "$trab\senado.png" `
  -/filter_complex "$trab\b4.filter" -map "[out]" -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$trab\b4.mp4"

# --- concatenacao final ---------------------------------------------------
Write-Host "[6/6] Concatenando os 4 blocos..."
$lista = @("b1","b2","b3","b4") | ForEach-Object { "file '$((Resolve-Path "$trab\$_.mp4").Path -replace '\\','/')'" }
Escrever-Utf8SemBom "$trab\concat.txt" (($lista -join "`n") + "`n")

& $ffmpeg -y -v error -f concat -safe 0 -i "$trab\concat.txt" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -an -t 255 "testeira_manifesto_2046x178.mp4"

Write-Host ""
Write-Host "Pronto: testeira_manifesto_2046x178.mp4"

# Cartelas tipograficas do roteiro v2:
#   manifesto\v2\b3_cartelas.mp4  (24s) - os tres nomes das comissoes
#   manifesto\v2\b4_provas.mp4    (22s) - a prova documental do bloco 4
#
# Sao inserts para serem editados dentro dos blocos 3 e 4, junto com as
# imagens reais da Semana de Vivencia (acervo CODIV).
#
# Uso:  powershell -ExecutionPolicy Bypass -File manifesto\cartelas.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
Set-Location $raiz

$ffmpeg = (Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
if (-not $ffmpeg) { throw "ffmpeg nao encontrado. Instale com: winget install -e --id Gyan.FFmpeg" }

$saida = "manifesto\v2"
New-Item -ItemType Directory -Force -Path $saida | Out-Null

$AZUL    = "0x071B36"
$LARANJA = "0xF07D00"
$DOURADO = "0xE3A82B"
$SANS    = "C\:/Windows/Fonts/arialbd.ttf"
$SERIF   = "C\:/Windows/Fonts/georgia.ttf"
$W = 1534; $H = 768; $FPS = 30
$CX = $W / 2

# --- acentos ---------------------------------------------------------------
# PowerShell 5.1 le .ps1 sem BOM como ANSI e corromperia acentos escritos
# diretamente. Marcadores {x} sao trocados pelo caractere Unicode correto.
# o dicionario precisa ser ordinal: hashtable do PowerShell ignora
# maiusculas/minusculas e "{A~}" colidiria com "{a~}".
$pares = @(
  @("{A~}", 0x00C3), @("{a~}", 0x00E3), @("{O~}", 0x00D5), @("{o~}", 0x00F5),
  @("{C,}", 0x00C7), @("{c,}", 0x00E7), @("{I'}", 0x00CD), @("{i'}", 0x00ED),
  @("{U'}", 0x00DA), @("{u'}", 0x00FA), @("{A'}", 0x00C1), @("{a'}", 0x00E1),
  @("{E'}", 0x00C9), @("{e'}", 0x00E9), @("{O'}", 0x00D3), @("{o'}", 0x00F3),
  @("{A^}", 0x00C2), @("{a^}", 0x00E2), @("{E^}", 0x00CA), @("{e^}", 0x00EA),
  @("{O^}", 0x00D4), @("{o^}", 0x00F4), @("{A``}", 0x00C0), @("{a``}", 0x00E0)
)
$ACENTOS = New-Object 'System.Collections.Generic.Dictionary[string,int]' ([System.StringComparer]::Ordinal)
foreach ($p in $pares) { $ACENTOS.Add($p[0], $p[1]) }

function Acentuar([string]$s) {
  foreach ($k in $ACENTOS.Keys) { $s = $s.Replace($k, [string][char]$ACENTOS[$k]) }
  return $s
}

function Escrever-Utf8SemBom($caminho, $conteudo) {
  [System.IO.File]::WriteAllText($caminho, $conteudo, (New-Object System.Text.UTF8Encoding($false)))
}

# --- primitivas de composicao ---------------------------------------------
function Texto($texto, $fonte, $tamanho, $cor, $y, $t0, $t1) {
  $fade = 0.6
  $alpha = "if(lt(t,$($t0+$fade)),(t-$t0)/$fade,if(gt(t,$($t1-$fade)),($t1-t)/$fade,1))"
  $txt = (Acentuar $texto)
  return "drawtext=fontfile='$fonte':text='$txt':fontcolor=${cor}:fontsize=${tamanho}" +
         ":x=(w-text_w)/2:y=${y}:alpha='$alpha':enable='between(t,$t0,$t1)'"
}

function Filete($y, $t0, $t1, $largura, $cor) {
  $meio = $largura / 2
  $w = "min($meio,(t-$t0)*420)"
  return "drawbox=x='$CX-$w':y=${y}:w='2*$w':h=5:color=${cor}:t=fill:enable='between(t,$t0,$t1)'"
}

function Renderizar($partes, $duracao, $arquivo) {
  $filtro = "[0:v]" + ($partes -join ",") + ",fade=t=in:st=0:d=1,fade=t=out:st=$($duracao-1.5):d=1.5[out]"
  Escrever-Utf8SemBom "$saida\tmp.filter" $filtro
  & $ffmpeg -y -v error -f lavfi -i "color=c=${AZUL}:s=${W}x${H}:d=${duracao}:r=${FPS}" `
    -/filter_complex "$saida\tmp.filter" -map "[out]" `
    -an -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$saida\$arquivo"
  Remove-Item "$saida\tmp.filter" -Force
  Write-Host "  -> $saida\$arquivo"
}

# =========================================================================
# BLOCO 3 - os tres nomes das comissoes
# Cada cartela: nome, o feito (uma linha) e a area da comissao.
# Datas foram omitidas de proposito: a fonte oficial so confirma parte delas.
# =========================================================================
Write-Host "Gerando as cartelas do bloco 3..."

$nomes = @(
  @{ nome = "N{I'}SIA FLORESTA"
     feito = "Escreveu sobre os direitos das mulheres aos 22 anos,"
     feito2 = "num pa{i'}s que ainda n{a~}o os reconhecia."
     area = "COMISS{A~}O DE MEIO AMBIENTE E SA{U'}DE" },
  @{ nome = "SOBRAL PINTO"
     feito = "Defendeu presos pol{i'}ticos quando defender"
     feito2 = "era perigoso. Ganhou o apelido de Senhor Justi{c,}a."
     area = "COMISS{A~}O DE DIREITOS FUNDAMENTAIS E CIDADANIA" },
  @{ nome = "CEC{I'}LIA MEIRELES"
     feito = "Fundou, em 1934, a primeira"
     feito2 = "biblioteca infantil do Brasil."
     area = "COMISS{A~}O DE EDUCA{C,}{A~}O" }
)

$partes3 = New-Object System.Collections.Generic.List[string]
$t = 0.0
foreach ($n in $nomes) {
  $t1 = $t + 8
  $partes3.Add((Texto $n.nome   $SANS  104 "white"   200 $t $t1))
  $partes3.Add((Filete 350 $t $t1 260 $LARANJA))
  $partes3.Add((Texto $n.feito  $SERIF  44 "white"   410 $t $t1))
  $partes3.Add((Texto $n.feito2 $SERIF  44 "white"   475 $t $t1))
  $partes3.Add((Texto $n.area   $SANS   32 $DOURADO  600 $t $t1))
  $t = $t1
}
Renderizar $partes3 24 "b3_cartelas.mp4"

# =========================================================================
# BLOCO 4 - a prova documental
# =========================================================================
Write-Host "Gerando as cartelas de prova do bloco 4..."

$partes4 = New-Object System.Collections.Generic.List[string]

# a data em que a simulacao deixou de ser simulacao
$partes4.Add((Texto "TRANSFORMADA EM PROJETO DE LEI DO SENADO" $SANS 58 "white" 190 0 9))
$partes4.Add((Filete 300 0 9 340 $LARANJA))
$partes4.Add((Texto "16.04.2024" $SANS 170 $LARANJA 360 0 9))

# seguiu adiante
$partes4.Add((Texto "E SEGUIU PARA A" $SANS 62 "white" 250 9 15))
$partes4.Add((Texto "C{A^}MARA DOS DEPUTADOS" $SANS 96 $DOURADO 350 9 15))

# a porta da universidade
$partes4.Add((Texto "33" $SANS 240 $LARANJA 160 15 22))
$partes4.Add((Filete 450 15 22 300 $DOURADO))
$partes4.Add((Texto "CURSOS DA UNESP ACEITAM O JOVEM SENADOR" $SANS 46 "white" 510 15 22))
$partes4.Add((Texto "COMO VIA DE INGRESSO NA GRADUA{C,}{A~}O" $SANS 38 $DOURADO 580 15 22))

Renderizar $partes4 22 "b4_provas.mp4"

# =========================================================================
# AS PALAVRAS QUE VIRARAM PROPOSTA
# Releitura do trecho de palavras-chave do roteiro original: em vez de
# adjetivos flutuando, cada palavra carrega uma proposta real dos jovens
# senadores. O adjetivo vira prova.
# =========================================================================
Write-Host "Gerando o bloco das palavras..."

$palavras = @(
  @{ p = "CIDADANIA"
     proposta = "Minuto da Cidadania"
     nota = "ACATADO PELA CDH" },
  @{ p = "EDUCA{C,}{A~}O"
     proposta = "Vale-Livro para a rede p{u'}blica"
     nota = "PROPOSTA DOS JOVENS SENADORES" },
  @{ p = "MEIO AMBIENTE"
     proposta = "Selo Eco Brasil de responsabilidade socioambiental"
     nota = "PROPOSTA DOS JOVENS SENADORES" },
  @{ p = "SA{U'}DE"
     proposta = "Rotulagem dos alimentos ultraprocessados"
     nota = "PROPOSTA DOS JOVENS SENADORES" },
  @{ p = "DEMOCRACIA"
     proposta = "Veda{c,}{a~}o do anonimato nas redes"
     nota = "PROPOSTA DOS JOVENS SENADORES" },
  @{ p = "CULTURA"
     proposta = "M{e^}s Nacional de Valoriza{c,}{a~}o da Cultura Brasileira"
     nota = "VIROU PROJETO DE LEI E SEGUIU PARA A C{A^}MARA" }
)

$partesP = New-Object System.Collections.Generic.List[string]
$t = 0.0
# cuidado: nao usar $w como variavel de laco - PowerShell ignora
# maiusculas e ela sobrescreveria $W, a largura do quadro.
foreach ($item in $palavras) {
  $t1 = $t + 6
  $partesP.Add((Texto $item.p        $SANS  118 $LARANJA 190 $t $t1))
  $partesP.Add((Filete 350 $t $t1 240 $DOURADO))
  $partesP.Add((Texto $item.proposta $SERIF  50 "white"  420 $t $t1))
  $partesP.Add((Texto $item.nota     $SANS   30 $DOURADO 545 $t $t1))
  $t = $t1
}
Renderizar $partesP 36 "b3_palavras.mp4"

Write-Host ""
Write-Host "Pronto."

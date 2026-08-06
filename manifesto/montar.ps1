<#
.SYNOPSIS
    Monta manifesto_tela_central_1534x768.mp4 a partir dos 8 clipes Higgsfield
    baixados em manifesto/clips/, seguindo a timeline do roteiro (Task 8).

.DESCRIPTION
    Passo A: normaliza cada clipe para 1534x768, 30fps, sem áudio (crop central
             sem distorção).
    Passo B: monta os 4 blocos (B1..B4) alternando os dois clipes de cada bloco
             (a,b,a,b,...) até cobrir a janela, concatena e corta no tempo exato.
    Passo C: concatena os 4 blocos no vídeo final, na raiz do projeto.

.NOTES
    Idempotente: pode ser reexecutado; sobrescreve as saídas existentes.
    Requer ffmpeg/ffprobe (instalar com:
    winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements).
#>

$ErrorActionPreference = "Stop"

# --- Resolver ffmpeg/ffprobe (PATH ou pasta do WinGet, caso a sessão não tenha sido reiniciada) ---
function Resolve-Tool([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $found = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "$Name.exe" -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($found) { return $found.FullName }

    throw "Não foi possível localizar $Name.exe. Instale com: winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements"
}

$ffmpeg  = Resolve-Tool "ffmpeg"
$ffprobe = Resolve-Tool "ffprobe"

# --- Diretórios ---
$manifestoDir = $PSScriptRoot
$projectRoot  = Split-Path $manifestoDir -Parent
$clipsDir     = Join-Path $manifestoDir "clips"
$normDir      = Join-Path $manifestoDir "norm"
$blocosDir    = Join-Path $manifestoDir "blocos"
$saidaFinal   = Join-Path $projectRoot "manifesto_tela_central_1534x768.mp4"

New-Item -ItemType Directory -Force -Path $normDir, $blocosDir | Out-Null

# Converte para caminho absoluto com barras normais (evita problemas do concat demuxer no Windows)
function ToConcatPath([string]$Path) {
    return ($Path -replace '\\', '/')
}

# Set-Content -Encoding utf8 grava BOM, e o demuxer concat do ffmpeg rejeita o
# BOM na primeira linha ("unknown keyword"). Grava UTF-8 sem BOM.
function Write-ConcatList([string]$Path, [string[]]$Lines) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllLines($Path, $Lines, $utf8NoBom)
}

# --- Passo A: normalizar os 8 clipes (crop central 1534x768, 30fps, sem áudio) ---
$clipes = @("b1a", "b1b", "b2a", "b2b", "b3a", "b3b", "b4a", "b4b")

foreach ($c in $clipes) {
    $inFile  = Join-Path $clipsDir "$c.mp4"
    $outFile = Join-Path $normDir "$c.mp4"
    if (-not (Test-Path $inFile)) {
        throw "Clipe não encontrado: $inFile (rode o download dos 8 clipes antes de montar.ps1)"
    }
    Write-Host "[A] Normalizando $c..." -ForegroundColor Cyan
    & $ffmpeg -y -i $inFile -vf "scale=1534:-2,crop=1534:768,setsar=1,fps=30" -an -c:v libx264 -preset medium -crf 18 $outFile
    if ($LASTEXITCODE -ne 0) { throw "Falha ao normalizar $c (ffmpeg exit $LASTEXITCODE)" }
}

# --- Passo B: montar cada bloco (concat alternado a,b,a,b,... + corte exato) ---
function Build-Bloco {
    param(
        [string]$NomeBloco,
        [string]$ClipeA,
        [string]$ClipeB,
        [int]$NumPares,
        [int]$DuracaoSeg
    )

    Write-Host "[B] Montando bloco $NomeBloco ($NumPares pares, corte em ${DuracaoSeg}s)..." -ForegroundColor Cyan

    $listPath = Join-Path $blocosDir "$NomeBloco.txt"
    $aPath = ToConcatPath (Join-Path $normDir "$ClipeA.mp4")
    $bPath = ToConcatPath (Join-Path $normDir "$ClipeB.mp4")

    $lines = @()
    for ($i = 0; $i -lt $NumPares; $i++) {
        $lines += "file '$aPath'"
        $lines += "file '$bPath'"
    }
    Write-ConcatList -Path $listPath -Lines $lines

    $concatTmp = Join-Path $blocosDir "${NomeBloco}_concat.mp4"
    & $ffmpeg -y -f concat -safe 0 -i $listPath -c copy $concatTmp
    if ($LASTEXITCODE -ne 0) { throw "Falha ao concatenar bloco $NomeBloco (ffmpeg exit $LASTEXITCODE)" }

    $outFile = Join-Path $blocosDir "$NomeBloco.mp4"
    & $ffmpeg -y -i $concatTmp -t $DuracaoSeg -c:v libx264 -crf 18 -an $outFile
    if ($LASTEXITCODE -ne 0) { throw "Falha ao cortar bloco $NomeBloco (ffmpeg exit $LASTEXITCODE)" }

    Remove-Item $concatTmp -Force
}

# 16s por par (8s+8s) -> B1/B2/B4: 4 pares = 64s cobrindo os 60s; B3: 5 pares = 80s cobrindo os 75s
Build-Bloco -NomeBloco "b1" -ClipeA "b1a" -ClipeB "b1b" -NumPares 4 -DuracaoSeg 60
Build-Bloco -NomeBloco "b2" -ClipeA "b2a" -ClipeB "b2b" -NumPares 4 -DuracaoSeg 60
Build-Bloco -NomeBloco "b3" -ClipeA "b3a" -ClipeB "b3b" -NumPares 5 -DuracaoSeg 75
Build-Bloco -NomeBloco "b4" -ClipeA "b4a" -ClipeB "b4b" -NumPares 4 -DuracaoSeg 60

# --- Passo C: concatenar os 4 blocos no vídeo final (raiz do projeto) ---
Write-Host "[C] Concatenando blocos b1+b2+b3+b4 -> $saidaFinal" -ForegroundColor Cyan

$finalListPath = Join-Path $blocosDir "final.txt"
$finalLines = @("b1", "b2", "b3", "b4") | ForEach-Object {
    "file '" + (ToConcatPath (Join-Path $blocosDir "$_.mp4")) + "'"
}
Write-ConcatList -Path $finalListPath -Lines $finalLines

& $ffmpeg -y -f concat -safe 0 -i $finalListPath -c copy $saidaFinal
if ($LASTEXITCODE -ne 0) { throw "Falha ao concatenar vídeo final (ffmpeg exit $LASTEXITCODE)" }

Write-Host "Concluído: $saidaFinal" -ForegroundColor Green

# --- Validação ---
Write-Host "`n--- ffprobe ---" -ForegroundColor Yellow
& $ffprobe -v error -show_entries format=duration -show_entries stream=width,height,r_frame_rate -of default=noprint_wrappers=1 $saidaFinal

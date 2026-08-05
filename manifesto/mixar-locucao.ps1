<#
.SYNOPSIS
    Mixa as 4 locuções (voz Marcus, aprovadas pelo usuário) no vídeo
    manifesto_tela_central_1534x768.mp4 (255s, mudo), gerando
    manifesto_tela_central_1534x768_locucao.mp4 na raiz do projeto.

.DESCRIPTION
    Passo único: adiciona os 4 WAVs de manifesto/locucao/ (b1..b4) como faixas
    de áudio defasadas (adelay) nos offsets de cada bloco da timeline,
    mixa (amix) e aplica ao vídeo original preservando o stream de vídeo
    intacto (-c:v copy).

.NOTES
    Idempotente: pode ser reexecutado; sobrescreve a saída existente.
    Requer manifesto_tela_central_1534x768.mp4 na raiz (gerado por montar.ps1)
    e os 4 WAVs em manifesto/locucao/ (b1.wav..b4.wav).
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
$locucaoDir   = Join-Path $manifestoDir "locucao"
$videoMudo    = Join-Path $projectRoot "manifesto_tela_central_1534x768.mp4"
$saidaFinal   = Join-Path $projectRoot "manifesto_tela_central_1534x768_locucao.mp4"

if (-not (Test-Path $videoMudo)) {
    throw "Vídeo mudo não encontrado: $videoMudo (rode manifesto/montar.ps1 antes)"
}

$b1 = Join-Path $locucaoDir "b1.wav"
$b2 = Join-Path $locucaoDir "b2.wav"
$b3 = Join-Path $locucaoDir "b3.wav"
$b4 = Join-Path $locucaoDir "b4.wav"

foreach ($f in @($b1, $b2, $b3, $b4)) {
    if (-not (Test-Path $f)) {
        throw "Locução não encontrada: $f (baixe os 4 WAVs para manifesto/locucao/ antes)"
    }
}

# --- Mixagem: 4 locuções defasadas (adelay, ms) + amix, sobre o vídeo intacto ---
Write-Host "[mix] Mixando locuções B1(2000ms) B2(62000ms) B3(122000ms) B4(197000ms) -> $saidaFinal" -ForegroundColor Cyan

& $ffmpeg -y `
    -i $videoMudo `
    -i $b1 -i $b2 -i $b3 -i $b4 `
    -filter_complex "[1:a]adelay=2000:all=1[a1];[2:a]adelay=62000:all=1[a2];[3:a]adelay=122000:all=1[a3];[4:a]adelay=197000:all=1[a4];[a1][a2][a3][a4]amix=inputs=4:normalize=0,apad=whole_dur=255[aout]" `
    -map 0:v -map "[aout]" `
    -c:v copy -c:a aac -b:a 192k `
    -t 255 `
    $saidaFinal

if ($LASTEXITCODE -ne 0) { throw "Falha ao mixar locuções (ffmpeg exit $LASTEXITCODE)" }

Write-Host "Concluído: $saidaFinal" -ForegroundColor Green

# --- Validação ---
Write-Host "`n--- ffprobe ---" -ForegroundColor Yellow
& $ffprobe -v error -show_entries format=duration -show_entries stream=codec_type,codec_name,width,height -of default=noprint_wrappers=1 $saidaFinal

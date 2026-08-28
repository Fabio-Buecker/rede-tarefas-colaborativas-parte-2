$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ReportPath = Join-Path $ProjectRoot "ENVIRONMENT_REPORT.md"

Set-Location $ProjectRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter nao foi encontrado no PATH. Configure o Flutter e execute novamente."
}

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    throw "Dart nao foi encontrado no PATH. Inclua o diretorio bin do Flutter no PATH."
}

$GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$FlutterDoctor = (& flutter doctor -v 2>&1 | Out-String).TrimEnd()
$FlutterVersion = (& flutter --version 2>&1 | Out-String).TrimEnd()
$DartVersion = (& dart --version 2>&1 | Out-String).TrimEnd()
$GitVersion = (& git --version 2>&1 | Out-String).TrimEnd()

$Content = @"
# Relatorio do Ambiente de Desenvolvimento

- **Projeto:** Rede de Tarefas Colaborativas
- **Grupo:** 03
- **Tema:** 07
- **Gerado em:** $GeneratedAt
- **Sistema:** $([System.Environment]::OSVersion.VersionString)

## Saida integral - flutter doctor -v

``````text
$FlutterDoctor
``````

## Flutter

``````text
$FlutterVersion
``````

## Dart

``````text
$DartVersion
``````

## Git

``````text
$GitVersion
``````

## Estrutura do repositorio

O repositorio utiliza `.gitignore` apropriado para Dart/Flutter, ignorando `.dart_tool/`, `.packages`, `build/`, arquivos de IDE, logs e temporarios de compilacao.
"@

Set-Content -Path $ReportPath -Value $Content -Encoding UTF8
Write-Host "Relatorio atualizado em: $ReportPath" -ForegroundColor Green


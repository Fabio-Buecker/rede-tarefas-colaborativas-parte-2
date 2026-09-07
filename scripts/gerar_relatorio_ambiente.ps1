# Faz qualquer erro interromper o script, evitando gerar um relatório parcial.
$ErrorActionPreference = "Stop"

# Flutter escreve símbolos Unicode no terminal. Forçar UTF-8 antes de executar
# os comandos impede que ✓ e • sejam interpretados com a página de código OEM.
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::InputEncoding = $Utf8NoBom
[Console]::OutputEncoding = $Utf8NoBom
$OutputEncoding = $Utf8NoBom

# `$PSScriptRoot` é a pasta deste script. Seu diretório pai é a raiz do projeto.
$ProjectRoot = Split-Path -Parent $PSScriptRoot
# `Join-Path` monta o caminho de modo compatível com o separador do Windows.
$ReportPath = Join-Path $ProjectRoot "ENVIRONMENT_REPORT.md"

# Garante que os comandos seguintes sejam executados a partir da raiz do pacote.
Set-Location $ProjectRoot

# `Get-Command` verifica se cada ferramenta está disponível no PATH. O parâmetro
# `SilentlyContinue` evita uma mensagem automática porque o script fornece uma
# explicação mais clara com `throw`.
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter nao foi encontrado no PATH. Configure o Flutter e execute novamente."
}

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
    throw "Dart nao foi encontrado no PATH. Inclua o diretorio bin do Flutter no PATH."
}

# Coleta data, diagnóstico e versões. `2>&1` une erro e saída padrão; o pipeline
# converte todas as linhas em texto, e `TrimEnd` remove quebras excedentes.
$GeneratedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss K"
$FlutterDoctor = (& flutter doctor -v 2>&1 | Out-String).TrimEnd()
$FlutterVersion = (& flutter --version 2>&1 | Out-String).TrimEnd()
$DartVersion = (& dart --version 2>&1 | Out-String).TrimEnd()
$GitVersion = (& git --version 2>&1 | Out-String).TrimEnd()

# Em algumas instalações em português, o `cmd.exe` devolve a palavra "versao"
# na página OEM e o Flutter a interpreta como Windows-1252, produzindo `versÆo`.
# A troca abaixo corrige somente esse artefato de codificação, sem omitir linhas.
$MojibakeVersao = "vers$([char]0x00C6)o"
$FlutterDoctor = $FlutterDoctor.Replace($MojibakeVersao, "versao")

# A here-string `@" ... "@` permite montar um Markdown com várias linhas.
# Expressões iniciadas por `$` são interpoladas com os valores coletados acima.
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

O repositorio utiliza ``.gitignore`` apropriado para Dart/Flutter, ignorando ``.dart_tool/``, ``.packages``, ``build/``, arquivos de IDE, logs e temporarios de compilacao.
"@

# WriteAllText mantém UTF-8 sem BOM tanto no Windows PowerShell 5.1 quanto no
# PowerShell moderno e substitui integralmente o relatório anterior.
[System.IO.File]::WriteAllText(
    $ReportPath,
    $Content + [System.Environment]::NewLine,
    $Utf8NoBom
)
# Confirma no terminal onde o arquivo foi salvo.
Write-Host "Relatorio atualizado em: $ReportPath" -ForegroundColor Green

#!/usr/bin/env bash
# Executa com Bash localizado pelo ambiente do usuário.

# `-e` encerra após erro, `-u` rejeita variável inexistente e `pipefail`
# propaga falhas ocorridas em qualquer comando de um pipeline.
set -euo pipefail

# `BASH_SOURCE[0]` localiza este arquivo; subir `..` encontra a raiz do projeto.
# `pwd` resolve o caminho absoluto, que depois é usado para o relatório.
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
report_path="$project_dir/ENVIRONMENT_REPORT.md"

# `command -v` consulta o PATH. A saída é descartada e o bloco após `||` só
# executa quando a ferramenta não foi encontrada.
command -v flutter >/dev/null 2>&1 || {
  echo "Flutter nao foi encontrado no PATH." >&2
  exit 1
}

command -v dart >/dev/null 2>&1 || {
  echo "Dart nao foi encontrado no PATH." >&2
  exit 1
}

# Captura, por substituição de comando `$(...)`, a data e as saídas integrais.
# `2>&1` também preserva mensagens que a ferramenta escrever no canal de erro.
generated_at="$(date --iso-8601=seconds)"
flutter_doctor="$(flutter doctor -v 2>&1)"
flutter_version="$(flutter --version 2>&1)"
dart_version="$(dart --version 2>&1)"
git_version="$(git --version 2>&1)"

# As chaves agrupam todos os `echo`; o redirecionamento final grava o conjunto
# no arquivo de uma vez. Aspas simples protegem as crases dos blocos Markdown.
{
  echo "# Relatorio do Ambiente de Desenvolvimento"
  echo
  echo "- **Projeto:** Rede de Tarefas Colaborativas"
  echo "- **Grupo:** 03"
  echo "- **Tema:** 07"
  echo "- **Gerado em:** $generated_at"
  echo
  echo "## Saida integral - flutter doctor -v"
  echo
  echo '```text'
  echo "$flutter_doctor"
  echo '```'
  echo
  echo "## Flutter"
  echo
  echo '```text'
  echo "$flutter_version"
  echo '```'
  echo
  echo "## Dart"
  echo
  echo '```text'
  echo "$dart_version"
  echo '```'
  echo
  echo "## Git"
  echo
  echo '```text'
  echo "$git_version"
  echo '```'
  echo
  echo "## Estrutura do repositorio"
  echo
  echo 'O repositorio utiliza `.gitignore` apropriado para Dart/Flutter, ignorando `.dart_tool/`, `.packages`, `build/`, arquivos de IDE, logs e temporarios de compilacao.'
} > "$report_path"

# Mostra ao usuário o caminho do artefato atualizado.
echo "Relatorio atualizado em: $report_path"

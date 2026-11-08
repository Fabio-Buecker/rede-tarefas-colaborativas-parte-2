# Validação da AP2B

Data: 08/11/2026. Flutter 3.47.9, Dart 3.13.7, Windows.

| Verificação executada | Resultado |
|---|---|
| `flutter analyze --no-pub` | Nenhum problema encontrado |
| `flutter test --no-pub` | **61 testes aprovados: 52 de unidade/dados e 9 de widgets** |
| SQLite real em memória | CRUD, FK, transações, cascata, tombstones e confirmação por revisão aprovados |
| HTTP MockClient | GET/POST/PUT/DELETE, erros, timeout, socket, JSON inválido, retry e concorrência aprovados |
| `python -m unittest discover -s scripts -p test_demo_api.py` | **3 testes HTTP reais aprovados**, incluindo CRUD e POST idempotente |
| Interface em 320 px | Ausência de overflow verificada; captura revisada visualmente |
| `git diff --check` | Sem erros de whitespace |

Evidências: [análise](analise.txt), [testes Flutter](testes.txt), [testes da API](api-testes.txt) e [diagnóstico atual](ambiente-ap2b.txt). Captura: `test/goldens/dashboard_320.png`. O teste visual carrega Roboto e os ícones do SDK. A comparação golden roda somente no Windows; a CI Linux também verifica ausência de overflow e executa todos os outros testes.

## Limites do ambiente

- Android SDK ausente: não foi gerado APK nem executado o app em aparelho/emulador Android.
- O build Windows encontrou a exigência de links simbólicos do Flutter. O Modo de Desenvolvedor está desativado; essa configuração não foi alterada e não foi gerado executável Windows.
- iOS exige macOS/Xcode e não foi compilado neste Windows.
- Os testes de widget executam a interface no Flutter Tester e não substituem validação em dispositivo físico.
- JSONPlaceholder simula gravações. A API didática foi testada por HTTP real em localhost e SQLite persistente em arquivo temporário.
- `ENVIRONMENT_REPORT.md` é uma evidência histórica da AP1B. O diagnóstico atual está em `docs/ambiente-ap2b.txt`.

Antes da defesa, a equipe deve configurar uma plataforma, executar os comandos do README e demonstrar modo avião, fechamento/reabertura e sincronização posterior em dispositivo/emulador. O roteiro de estudo está em `DEFESA_TECNICA.md`.

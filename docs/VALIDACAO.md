# Validação da AP2B

Validação inicial: 08/11/2026. Atualização: 10/11/2026. Flutter 3.47.9, Dart 3.13.7, Windows.

## Atualização de 10/11/2026

- Após recuperar as dependências com `flutter pub get`, a execução de `flutter test --reporter expanded` terminou com **61 testes aprovados**, exibindo `00:21 +61: All tests passed!`.
- O código testado corresponde ao commit `de9a5ae`. A recuperação das dependências corrigiu arquivos ausentes no cache local, sem alterar regras do aplicativo.
- O APK Android de depuração foi gerado em 08/11/2026, após instalar/configurar o ambiente Android. Fábio informou que o aplicativo funcionou no celular. Esse relato não representa uma nova bateria automatizada de testes em dispositivo.
- A tabela abaixo preserva os resultados da validação inicial. A análise estática e a suíte Python não foram executadas novamente nesta atualização documental.

| Verificação executada | Resultado |
|---|---|
| `flutter analyze --no-pub` | Nenhum problema encontrado |
| `flutter test --no-pub` | **61 testes aprovados: 52 de unidade/dados e 9 de widgets** |
| SQLite real em memória | CRUD, FK, transações, cascata, tombstones e confirmação por revisão aprovados |
| HTTP MockClient | GET/POST/PUT/DELETE, erros, timeout, socket, JSON inválido, retry e concorrência aprovados |
| `python -m unittest discover -s scripts -p test_demo_api.py` | **3 testes HTTP reais aprovados**, incluindo CRUD e POST idempotente |
| Interface em 320 px | Ausência de overflow verificada; captura revisada visualmente |
| `git diff --check` | Sem erros de whitespace |

Evidências da validação inicial: [análise](analise.txt), [testes Flutter](testes.txt), [testes da API](api-testes.txt) e [diagnóstico do ambiente em 08/11/2026](ambiente-ap2b.txt). Captura: `test/goldens/dashboard_320.png`. O teste visual carrega Roboto e os ícones do SDK. A comparação golden roda somente no Windows; a CI Linux também verifica ausência de overflow e executa todos os outros testes.

## Limites do ambiente

- Android: o APK de depuração foi gerado e seu funcionamento no celular foi informado pela equipe. A ausência de SDK descrita no diagnóstico inicial foi superada posteriormente.
- Windows: não foi gerado executável desktop. Os problemas anteriores de links, permissões e carregamento de dependências não impediram a execução completa dos testes em 10/11/2026; isso não comprova um build Windows.
- iOS exige macOS/Xcode e não foi compilado neste Windows.
- Os testes de widget executam a interface no Flutter Tester e não substituem validação em dispositivo físico.
- JSONPlaceholder simula gravações. A API didática foi testada por HTTP real em localhost e SQLite persistente em arquivo temporário.
- `ENVIRONMENT_REPORT.md` é uma evidência histórica da AP1B. `docs/ambiente-ap2b.txt` preserva o diagnóstico inicial da AP2B e deve ser lido junto desta atualização.

Na Modalidade A escolhida pela equipe, a demonstração de até seis minutos deve mostrar o app online e offline, simular queda real de rede e executar `flutter test`, seguida das perguntas técnicas individuais previstas no enunciado. A execução dos testes não substitui essa demonstração em dispositivo/emulador.

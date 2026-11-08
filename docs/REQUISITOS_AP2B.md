# Mapeamento da avaliação AP2B

Base: PDF Avaliação Processual 2B, 03/11/2026. Grupo 03, Tema 07.

| Exigência | Evidência no projeto |
|---|---|
| Evoluir a AP1B e manter o tema | Histórico original, `lib/models`, `lib/core`, `lib/services` e testes anteriores preservados |
| Duas entidades relacionadas | `quadros`, `tarefas` e `subtarefas`, FKs e transações em `lib/datasources/local_dao.dart` |
| 10+ rotas integradas | 15 nomes de rota em `lib/app.dart`; lista no README |
| Material 3, Scaffold, AppBar | `lib/app.dart` e `lib/widgets/common.dart` |
| Lista dinâmica e ação por gesto | `ListView.builder` em tarefas/quadros e `InkWell` em `TaskCard` |
| Form, GlobalKey, controllers, validação | Formulários de quadro, tarefa e subtarefa em `lib/screens` |
| Passagem segura de argumentos | `IdArgs`, validação em `onGenerateRoute` e telas de entidade não encontrada |
| Feedback de sincronização | `SyncBadge`, faixa de estado, SnackBars, fila e histórico |
| CRUD real com sqflite | `LocalDao`, `salvar`, `listar`, `confirmar`, `salvarQuadro`, `excluirQuadro` |
| toMap/fromMap | Modelos originais e `lib/models/registro_local.dart` |
| Preferências | `AppController`, tema, modo offline e última sincronização sem falhas |
| HTTP assíncrono e JSON | `ApiService`, `package:http`, `dart:convert`, Future/async/await |
| Status HTTP e timeout | `_request`, status 2xx e timeout de 8 segundos |
| Repository offline-first | `OfflineRepository`, gravação local antes de HTTP, exclusões pendentes e revisão condicional |
| Exceções de rede e fallback | `RedeException`, try/on/catch/rethrow no serviço e manutenção da fila no repositório |
| 20+ testes de unidade | Domínio original, serialização, repository, mocks de falha e SQLite real em `test` |
| 5+ testes de widgets | `test/widget_test.dart` e `test/responsive_test.dart` |
| Estrutura de pastas e .gitignore | `lib/models`, `datasources`, `repositories`, `screens`, `widgets`, `test`; bancos e caches ignorados |
| README com equipe, API, arquitetura, execução, IA e referências | `README.md` |
| Defesa individual | `docs/DEFESA_TECNICA.md` |

## Decisões e limites

- A AP1B possuía simulação em memória; o novo fluxo usa SQLite e HTTP reais. O executável CLI continua disponível como referência histórica e não alimenta o aplicativo Flutter.
- Dados da interface são exclusivamente locais. GET importa modelos explicitamente e não sobrescreve o trabalho local.
- Quadros são locais; cada tarefa transmite o identificador do quadro e o domínio completo, incluindo subtarefas.
- A API pública simula gravações. O servidor Python incluído oferece persistência real para a demonstração de POST/PUT/DELETE.
- Não existe detector de conectividade ou temporizador permanente. O app tenta enviar depois de salvar, quando o modo offline é desativado e pelo botão manual.
- A confirmação compara a revisão enviada. Se houver uma edição durante o envio, outra sincronização manual pode ser necessária para a revisão nova.
- Repetir POST no servidor incluído é seguro por `localId`. A API pública não oferece essa garantia.
- Defesa, execução em aparelho e envio do link ao professor devem ser feitos pelos integrantes.

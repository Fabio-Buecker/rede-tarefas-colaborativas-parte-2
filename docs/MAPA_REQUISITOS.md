# Mapa de Requisitos da AP1B

Este documento serve como trilha de verificacao para o professor e como roteiro de estudo para o grupo.

## Requisito 1 - Setup e diagnostico do ambiente

| Item solicitado | Implementacao |
|---|---|
| Saida integral de `flutter doctor -v` | `ENVIRONMENT_REPORT.md`, preenchido pelos scripts em `scripts/` |
| `.gitignore` Dart/Flutter | `.gitignore` ignora `.dart_tool/`, `.packages`, `build/`, IDEs, logs e temporarios |
| Repositorio Git organizado | Branch `main`, commits semanticos e workflow de CI |
| Codigo formatado | Comando `dart format --set-exit-if-changed .` no README e na CI |

## Requisito 2 - Modelagem orientada a objetos

| Conceito | Onde demonstrar | Explicacao curta |
|---|---|---|
| Classe abstrata | `lib/models/item_trabalho.dart` | Define estado comum e contratos `executarPasso()` e `toMap()` |
| Interface implicita/contrato | `lib/repositories/tarefa_repository.dart` | Separa o dominio do armazenamento concreto |
| Heranca | `Subtarefa` e `TarefaColaborativa` | Ambas especializam `ItemTrabalho` com `extends` |
| `super` | Construtores das subclasses | Inicializa os campos definidos na superclasse |
| `@override` | `executarPasso`, `toMap` e `toString` | Implementa comportamento polimorfico especifico |
| Mixin | `AuditoriaMixin` | Acrescenta logs com timestamp por meio de `with` |
| Construtor gerativo | `Membro(...)`, `Subtarefa(...)`, `TarefaColaborativa(...)` | Inicializa objetos completos |
| Construtor nomeado | `Membro.convidado`, `Subtarefa.rapida`, `TarefaColaborativa.planejamento` | Representa cenarios de criacao especificos |
| Factory | `Membro.fromMap`, `Subtarefa.fromMap`, `TarefaColaborativa.fromMap` | Faz parsing, aplica valores padrao e valida dados |
| Encapsulamento | Campos iniciados por `_` | Protege estado e expoe getters/setters validados |
| Imutabilidade | Campos `final` | IDs, datas, criador e referencias estruturais nao mudam apos a construcao |
| Composicao | Lista de subtarefas em `TarefaColaborativa` | A tarefa e composta por objetos `Subtarefa` |

## Requisito 3 - Null safety, colecoes e excecoes

| Recurso | Evidencia |
|---|---|
| Tipos anulaveis `T?` | E-mail, descricao, prazo, ultima sincronizacao e buscas opcionais |
| Coalescencia `??` | Factories, mensagens padrao e acesso seguro na CLI |
| Atribuicao `??=` | Primeira mensagem de sincronizacao |
| Acesso seguro `?.` | Conversao de prazo, parsing numerico, busca de membro e ultimo log |
| Spread `...` | Membros, tarefas e etiquetas |
| Spread anulavel `...?` | Etiquetas, subtarefas e lista opcional de tarefas extras |
| `List`, `Map`, `Set` | Repositorio, cadastro, subtarefas, tags e metricas |
| `.map()` | Transformacao das tarefas em resumos e mapas serializados |
| `.where()` | Filtro por status e construcao segura por tipos |
| `.fold()` | Media do progresso de tarefas e subtarefas |
| `.every()` | Verificacao se todas as tarefas estao concluidas |
| `.any()` | Duplicidade, tarefas bloqueadas e busca de condicoes |
| Collection-If | Campos opcionais em `toMap()` e filtro por membro |
| Collection-For | Quadro por status, listas serializadas e etiquetas consolidadas |
| Excecoes customizadas | `lib/core/exceptions.dart` |
| `try-on-catch-finally` | Sincronizacao e fluxos invalidos da CLI |
| `rethrow` | Preserva a excecao apos registrar auditoria no servico |

## Requisito 4 - CLI

O arquivo `bin/main.dart` demonstra, na seguinte ordem:

1. Cadastro de cinco membros.
2. Criacao de tarefas com construtores gerativo, nomeado e factory.
3. Insercao de subtarefas.
4. Conclusao e delegacao.
5. Filtro por status e por membro.
6. Tratamento de membro inexistente.
7. Queda de conectividade e falha controlada de sincronizacao.
8. Restauracao da rede e sincronizacao.
9. Relatorio consolidado e transformacao funcional dos dados.

## Requisito 5 - Arguicao

Cada integrante deve conseguir localizar e explicar no codigo os conceitos de orientacao a objetos, null safety, colecoes e tratamento de excecoes aplicados no projeto.


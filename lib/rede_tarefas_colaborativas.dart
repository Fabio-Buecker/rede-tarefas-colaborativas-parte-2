/// Biblioteca pública do pacote `rede_tarefas_colaborativas`.
///
/// Cada diretiva `export` torna as classes daquele arquivo acessíveis com um
/// único import do pacote, como o utilizado pela demonstração e pelos testes.
library;

export 'core/auditoria_mixin.dart';
export 'core/enums.dart';
export 'core/exceptions.dart';
// Modelos e regras das entidades do domínio.
export 'models/item_trabalho.dart';
export 'models/membro.dart';
export 'models/subtarefa.dart';
export 'models/tarefa_colaborativa.dart';
// Contrato de persistência e sua implementação local.
export 'repositories/tarefa_repository.dart';
export 'repositories/tarefa_repository_memoria.dart';
// Casos de uso e geração de saída para o usuário.
export 'services/gerenciador_rede_tarefas.dart';
export 'services/relatorio_service.dart';

import '../core/auditoria_mixin.dart';
import '../core/enums.dart';
import '../core/exceptions.dart';
import '../models/membro.dart';
import '../models/subtarefa.dart';
import '../models/tarefa_colaborativa.dart';
import '../repositories/tarefa_repository.dart';

/// Fachada que coordena membros, tarefas e regras da rede colaborativa.
///
/// A classe concentra os casos de uso para que a interface de usuário não
/// manipule diretamente o repositório nem precise repetir validações. O mixin
/// adiciona um histórico das operações relevantes.
class GerenciadorRedeTarefas with AuditoriaMixin {
  /// Fonte de dados recebida por injeção de dependência no construtor.
  final TarefaRepository _repository;

  /// Cadastro local de membros indexado pelo identificador.
  final Map<String, Membro> _membros = <String, Membro>{};

  /// Estado usado para simular disponibilidade da conexão no aplicativo móvel.
  bool _online = true;

  /// Instante da sincronização bem-sucedida mais recente.
  DateTime? _ultimaSincronizacao;

  /// Mensagem persistida após a primeira sincronização.
  String? _mensagemSincronizacao;

  /// Cria o serviço com qualquer implementação de [TarefaRepository].
  GerenciadorRedeTarefas(this._repository);

  /// Informa se a rede está disponível no momento.
  bool get online => _online;

  /// Retorna a última sincronização ou `null` quando ela nunca ocorreu.
  DateTime? get ultimaSincronizacao => _ultimaSincronizacao;

  /// Expõe a mensagem registrada ou um texto padrão enquanto não há sincronização.
  String get mensagemSincronizacao =>
      _mensagemSincronizacao ?? 'Nenhuma sincronizacao executada.';

  /// Lista os membros sem permitir mudanças na coleção interna.
  List<Membro> get membros => List<Membro>.unmodifiable(_membros.values);

  /// Cadastra um membro e impede a reutilização de identificadores.
  void cadastrarMembro(Membro membro) {
    if (_membros.containsKey(membro.id)) {
      throw EntidadeDuplicadaException('Membro', membro.id);
    }
    _membros[membro.id] = membro;
    registrarAuditoria('Membro ${membro.id} cadastrado.');
  }

  /// Procura um membro; a ausência é representada por `null`.
  Membro? buscarMembro(String id) => _membros[id];

  /// Valida todos os participantes antes de persistir uma nova tarefa.
  void criarTarefa(TarefaColaborativa tarefa) {
    _obterMembroObrigatorio(tarefa.criadorId);
    // O `for-in` garante que nenhum id desconhecido entre no repositório.
    for (final String membroId in tarefa.membrosIds) {
      _obterMembroObrigatorio(membroId);
    }
    _repository.salvar(tarefa);
    registrarAuditoria('Tarefa ${tarefa.id} cadastrada na rede.');
  }

  /// Inclui um membro cadastrado em uma tarefa existente.
  void adicionarMembroNaTarefa(String tarefaId, String membroId) {
    _obterMembroObrigatorio(membroId);
    _obterTarefaObrigatoria(tarefaId).adicionarMembro(membroId);
  }

  /// Adiciona uma subtarefa após validar seu responsável e sua tarefa principal.
  void adicionarSubtarefa(String tarefaId, Subtarefa subtarefa) {
    _obterMembroObrigatorio(subtarefa.responsavelId);
    _obterTarefaObrigatoria(tarefaId).adicionarSubtarefa(subtarefa);
  }

  /// Delega uma subtarefa e registra sucesso, falha e encerramento da operação.
  void delegarSubtarefa(
    String tarefaId,
    String subtarefaId,
    String novoResponsavelId,
  ) {
    // `<void>` define explicitamente o tipo genérico da operação sem retorno.
    executarComAuditoria<void>('delegacao de subtarefa', () {
      _obterMembroObrigatorio(novoResponsavelId);
      _obterTarefaObrigatoria(tarefaId)
          .delegarSubtarefa(subtarefaId, novoResponsavelId);
    });
  }

  /// Solicita a conclusão de uma subtarefa pertencente à tarefa informada.
  void concluirSubtarefa(String tarefaId, String subtarefaId) {
    _obterTarefaObrigatoria(tarefaId).concluirSubtarefa(subtarefaId);
  }

  /// Consulta diretamente uma tarefa opcional no repositório.
  TarefaColaborativa? buscarTarefa(String id) => _repository.buscarPorId(id);

  /// Lista todas as tarefas sem expor detalhes da implementação de persistência.
  List<TarefaColaborativa> listarTarefas() => _repository.listar();

  /// Filtra tarefas pelo estado; a lista resultante tem tamanho fixo.
  List<TarefaColaborativa> filtrarPorStatus(StatusTarefa status) => _repository
      .listar()
      .where((tarefa) => tarefa.status == status)
      .toList(growable: false);

  /// Seleciona as tarefas das quais o membro participa.
  ///
  /// Trata-se de uma `collection for`: o `if` inclui somente itens compatíveis.
  List<TarefaColaborativa> tarefasDoMembro(String membroId) =>
      <TarefaColaborativa>[
        for (final TarefaColaborativa tarefa in _repository.listar())
          if (tarefa.membrosIds.contains(membroId)) tarefa,
      ];

  /// Monta um quadro com uma entrada para cada status, inclusive listas vazias.
  Map<StatusTarefa, List<TarefaColaborativa>> quadroPorStatus() =>
      <StatusTarefa, List<TarefaColaborativa>>{
        for (final StatusTarefa status in StatusTarefa.values)
          status: filtrarPorStatus(status),
      };

  /// Transforma objetos completos em mapas menores próprios para listagens.
  ///
  /// `map` aplica a função a cada tarefa e produz um novo iterável de resumos.
  List<Map<String, Object>> transformarEmResumos() => _repository
      .listar()
      .map(
        (tarefa) => <String, Object>{
          'id': tarefa.id,
          'titulo': tarefa.titulo,
          'status': tarefa.status.rotulo,
          'progresso': '${tarefa.progresso.toStringAsFixed(0)}%',
          'participantes': tarefa.membrosIds.length,
        },
      )
      .toList(growable: false);

  /// Calcula indicadores agregados das tarefas armazenadas e das opcionais.
  ///
  /// [tarefasExtras] demonstra parâmetro nomeado opcional. `...?` adiciona seus
  /// itens apenas quando a lista foi fornecida.
  Map<String, Object> calcularMetricas({
    List<TarefaColaborativa>? tarefasExtras,
  }) {
    final List<TarefaColaborativa> tarefas = <TarefaColaborativa>[
      ..._repository.listar(),
      ...?tarefasExtras,
    ];
    // `fold` reduz a lista a um único valor: a soma dos percentuais.
    final double somaProgresso = tarefas.fold<double>(
      0,
      (soma, tarefa) => soma + tarefa.progresso,
    );
    // Os dois `for` percorrem tarefas e, dentro delas, suas etiquetas.
    final Set<String> etiquetas = <String>{
      for (final TarefaColaborativa tarefa in tarefas)
        for (final String etiqueta in tarefa.etiquetas) etiqueta,
    };

    return <String, Object>{
      'total': tarefas.length,
      // A condição evita divisão por zero quando não existem tarefas.
      'mediaProgresso': tarefas.isEmpty ? 0.0 : somaProgresso / tarefas.length,
      // `every` exige que todas satisfaçam a condição; `any`, pelo menos uma.
      'todasConcluidas': tarefas.isNotEmpty &&
          tarefas.every((tarefa) => tarefa.status == StatusTarefa.concluida),
      'possuiBloqueada':
          tarefas.any((tarefa) => tarefa.status == StatusTarefa.bloqueada),
      'etiquetas': etiquetas,
    };
  }

  /// Altera a conectividade simulada e registra o novo estado.
  void alterarConectividade({required bool online}) {
    _online = online;
    registrarAuditoria(
      'Conectividade alterada: ${online ? 'online' : 'offline'}.',
    );
  }

  /// Simula a sincronização dos dados usando tratamento estruturado de erros.
  ///
  /// `try` contém a tentativa; `on` captura apenas [ConectividadeException];
  /// `rethrow` preserva a exceção para o chamador; `finally` sempre é executado.
  void sincronizar() {
    try {
      if (!_online) {
        throw const ConectividadeException(
          'Sem conexao. As alteracoes continuam armazenadas localmente.',
        );
      }
      _ultimaSincronizacao = DateTime.now();
      // `??=` atribui somente se ainda não houver mensagem.
      _mensagemSincronizacao ??= 'Primeira sincronizacao concluida.';
      registrarAuditoria('Sincronizacao concluida com sucesso.');
    } on ConectividadeException {
      registrarAuditoria('Falha de sincronizacao por ausencia de rede.');
      rethrow;
    } finally {
      registrarAuditoria('Tentativa de sincronizacao finalizada.');
    }
  }

  /// Executa qualquer [acao] e padroniza sua auditoria.
  ///
  /// O tipo genérico `T` permite devolver o mesmo tipo retornado pela função,
  /// seja `void`, um objeto ou um valor primitivo.
  T executarComAuditoria<T>(String operacao, T Function() acao) {
    try {
      final T resultado = acao();
      registrarAuditoria('Operacao "$operacao" concluida.');
      return resultado;
    } on DominioException catch (erro) {
      registrarAuditoria('Erro em "$operacao": ${erro.mensagem}');
      rethrow;
    } finally {
      registrarAuditoria('Operacao "$operacao" finalizada.');
    }
  }

  /// Busca uma tarefa ou lança erro quando o caso de uso exige sua existência.
  TarefaColaborativa _obterTarefaObrigatoria(String id) {
    final TarefaColaborativa? tarefa = _repository.buscarPorId(id);
    if (tarefa == null) {
      throw EntidadeNaoEncontradaException('Tarefa', id);
    }
    return tarefa;
  }

  /// Busca um membro ou lança erro quando o caso de uso exige sua existência.
  Membro _obterMembroObrigatorio(String id) {
    final Membro? membro = _membros[id];
    if (membro == null) {
      throw EntidadeNaoEncontradaException('Membro', id);
    }
    return membro;
  }
}

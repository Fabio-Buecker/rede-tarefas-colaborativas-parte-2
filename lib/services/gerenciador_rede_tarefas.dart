import '../core/auditoria_mixin.dart';
import '../core/enums.dart';
import '../core/exceptions.dart';
import '../models/membro.dart';
import '../models/subtarefa.dart';
import '../models/tarefa_colaborativa.dart';
import '../repositories/tarefa_repository.dart';

class GerenciadorRedeTarefas with AuditoriaMixin {
  final TarefaRepository _repository;
  final Map<String, Membro> _membros = <String, Membro>{};

  bool _online = true;
  DateTime? _ultimaSincronizacao;
  String? _mensagemSincronizacao;

  GerenciadorRedeTarefas(this._repository);

  bool get online => _online;

  DateTime? get ultimaSincronizacao => _ultimaSincronizacao;

  String get mensagemSincronizacao =>
      _mensagemSincronizacao ?? 'Nenhuma sincronizacao executada.';

  List<Membro> get membros => List<Membro>.unmodifiable(_membros.values);

  void cadastrarMembro(Membro membro) {
    if (_membros.containsKey(membro.id)) {
      throw EntidadeDuplicadaException('Membro', membro.id);
    }
    _membros[membro.id] = membro;
    registrarAuditoria('Membro ${membro.id} cadastrado.');
  }

  Membro? buscarMembro(String id) => _membros[id];

  void criarTarefa(TarefaColaborativa tarefa) {
    _obterMembroObrigatorio(tarefa.criadorId);
    for (final String membroId in tarefa.membrosIds) {
      _obterMembroObrigatorio(membroId);
    }
    _repository.salvar(tarefa);
    registrarAuditoria('Tarefa ${tarefa.id} cadastrada na rede.');
  }

  void adicionarMembroNaTarefa(String tarefaId, String membroId) {
    _obterMembroObrigatorio(membroId);
    _obterTarefaObrigatoria(tarefaId).adicionarMembro(membroId);
  }

  void adicionarSubtarefa(String tarefaId, Subtarefa subtarefa) {
    _obterMembroObrigatorio(subtarefa.responsavelId);
    _obterTarefaObrigatoria(tarefaId).adicionarSubtarefa(subtarefa);
  }

  void delegarSubtarefa(
    String tarefaId,
    String subtarefaId,
    String novoResponsavelId,
  ) {
    executarComAuditoria<void>('delegacao de subtarefa', () {
      _obterMembroObrigatorio(novoResponsavelId);
      _obterTarefaObrigatoria(tarefaId)
          .delegarSubtarefa(subtarefaId, novoResponsavelId);
    });
  }

  void concluirSubtarefa(String tarefaId, String subtarefaId) {
    _obterTarefaObrigatoria(tarefaId).concluirSubtarefa(subtarefaId);
  }

  TarefaColaborativa? buscarTarefa(String id) => _repository.buscarPorId(id);

  List<TarefaColaborativa> listarTarefas() => _repository.listar();

  List<TarefaColaborativa> filtrarPorStatus(StatusTarefa status) => _repository
      .listar()
      .where((tarefa) => tarefa.status == status)
      .toList(growable: false);

  List<TarefaColaborativa> tarefasDoMembro(String membroId) => <TarefaColaborativa>[
        for (final TarefaColaborativa tarefa in _repository.listar())
          if (tarefa.membrosIds.contains(membroId)) tarefa,
      ];

  Map<StatusTarefa, List<TarefaColaborativa>> quadroPorStatus() =>
      <StatusTarefa, List<TarefaColaborativa>>{
        for (final StatusTarefa status in StatusTarefa.values)
          status: filtrarPorStatus(status),
      };

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

  Map<String, Object> calcularMetricas({
    List<TarefaColaborativa>? tarefasExtras,
  }) {
    final List<TarefaColaborativa> tarefas = <TarefaColaborativa>[
      ..._repository.listar(),
      ...?tarefasExtras,
    ];
    final double somaProgresso = tarefas.fold<double>(
      0,
      (soma, tarefa) => soma + tarefa.progresso,
    );
    final Set<String> etiquetas = <String>{
      for (final TarefaColaborativa tarefa in tarefas)
        for (final String etiqueta in tarefa.etiquetas) etiqueta,
    };

    return <String, Object>{
      'total': tarefas.length,
      'mediaProgresso':
          tarefas.isEmpty ? 0.0 : somaProgresso / tarefas.length,
      'todasConcluidas': tarefas.isNotEmpty &&
          tarefas.every((tarefa) => tarefa.status == StatusTarefa.concluida),
      'possuiBloqueada':
          tarefas.any((tarefa) => tarefa.status == StatusTarefa.bloqueada),
      'etiquetas': etiquetas,
    };
  }

  void alterarConectividade({required bool online}) {
    _online = online;
    registrarAuditoria('Conectividade alterada: ${online ? 'online' : 'offline'}.');
  }

  void sincronizar() {
    try {
      if (!_online) {
        throw const ConectividadeException(
          'Sem conexao. As alteracoes continuam armazenadas localmente.',
        );
      }
      _ultimaSincronizacao = DateTime.now();
      _mensagemSincronizacao ??= 'Primeira sincronizacao concluida.';
      registrarAuditoria('Sincronizacao concluida com sucesso.');
    } on ConectividadeException {
      registrarAuditoria('Falha de sincronizacao por ausencia de rede.');
      rethrow;
    } finally {
      registrarAuditoria('Tentativa de sincronizacao finalizada.');
    }
  }

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

  TarefaColaborativa _obterTarefaObrigatoria(String id) {
    final TarefaColaborativa? tarefa = _repository.buscarPorId(id);
    if (tarefa == null) {
      throw EntidadeNaoEncontradaException('Tarefa', id);
    }
    return tarefa;
  }

  Membro _obterMembroObrigatorio(String id) {
    final Membro? membro = _membros[id];
    if (membro == null) {
      throw EntidadeNaoEncontradaException('Membro', id);
    }
    return membro;
  }
}

import '../core/auditoria_mixin.dart';
import '../core/enums.dart';
import '../core/exceptions.dart';
import 'item_trabalho.dart';
import 'subtarefa.dart';

class TarefaColaborativa extends ItemTrabalho with AuditoriaMixin {
  final String criadorId;
  final Set<String> _membrosIds;
  final Set<String> _etiquetas;
  final List<Subtarefa> _subtarefas;

  TarefaColaborativa({
    required String id,
    required String titulo,
    required this.criadorId,
    required Iterable<String> membrosIds,
    String? descricao,
    DateTime? prazo,
    PrioridadeTarefa prioridade = PrioridadeTarefa.media,
    DateTime? criadoEm,
    StatusTarefa status = StatusTarefa.pendente,
    double progresso = 0,
    Iterable<String>? etiquetas,
    Iterable<Subtarefa>? subtarefas,
  })  : _membrosIds = <String>{criadorId, ...membrosIds},
        _etiquetas = <String>{...?etiquetas},
        _subtarefas = <Subtarefa>[...?subtarefas],
        super(
          id: id,
          titulo: titulo,
          descricao: descricao,
          prazo: prazo,
          prioridade: prioridade,
          criadoEm: criadoEm,
          status: status,
          progresso: progresso,
        ) {
    if (criadorId.trim().isEmpty) {
      throw const ValidacaoException('O criador da tarefa e obrigatorio.');
    }
    recalcularProgresso();
    registrarAuditoria('Tarefa "$titulo" criada por $criadorId.');
  }

  TarefaColaborativa.planejamento({
    required String id,
    required String titulo,
    required this.criadorId,
  })  : _membrosIds = <String>{criadorId},
        _etiquetas = <String>{'planejamento'},
        _subtarefas = <Subtarefa>[],
        super(
          id: id,
          titulo: titulo,
          prioridade: PrioridadeTarefa.baixa,
        ) {
    if (criadorId.trim().isEmpty) {
      throw const ValidacaoException('O criador da tarefa e obrigatorio.');
    }
    registrarAuditoria('Tarefa criada pelo construtor nomeado.');
  }

  factory TarefaColaborativa.fromMap(Map<String, dynamic> map) {
    final Object? membrosBrutos = map['membrosIds'];
    final Set<String> membros = membrosBrutos is Iterable<Object?>
        ? membrosBrutos.whereType<String>().toSet()
        : <String>{};

    final Object? etiquetasBrutas = map['etiquetas'];
    final Set<String> etiquetas = etiquetasBrutas is Iterable<Object?>
        ? etiquetasBrutas.whereType<String>().toSet()
        : <String>{};

    final Object? subtarefasBrutas = map['subtarefas'];
    final List<Subtarefa> subtarefas = subtarefasBrutas is Iterable<Object?>
        ? subtarefasBrutas
            .whereType<Map<Object?, Object?>>()
            .map(
              (item) => Subtarefa.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList()
        : <Subtarefa>[];

    final String? prazoTexto = map['prazo'] as String?;
    final String? criadoEmTexto = map['criadoEm'] as String?;
    final String criadorId = map['criadorId'] as String? ?? '';

    return TarefaColaborativa(
      id: map['id'] as String? ?? '',
      titulo: map['titulo'] as String? ?? 'Tarefa sem titulo',
      criadorId: criadorId,
      membrosIds: <String>{criadorId, ...membros},
      descricao: map['descricao'] as String?,
      prazo: prazoTexto == null ? null : DateTime.tryParse(prazoTexto),
      criadoEm:
          criadoEmTexto == null ? null : DateTime.tryParse(criadoEmTexto),
      prioridade: prioridadeTarefaFromString(map['prioridade'] as String?),
      status: statusTarefaFromString(map['status'] as String?),
      progresso: (map['progresso'] as num?)?.toDouble() ?? 0,
      etiquetas: etiquetas,
      subtarefas: subtarefas,
    );
  }

  Set<String> get membrosIds => Set<String>.unmodifiable(_membrosIds);

  Set<String> get etiquetas => Set<String>.unmodifiable(_etiquetas);

  List<Subtarefa> get subtarefas =>
      List<Subtarefa>.unmodifiable(_subtarefas);

  void adicionarMembro(String membroId) {
    if (membroId.trim().isEmpty) {
      throw const ValidacaoException('O id do membro nao pode ser vazio.');
    }
    _membrosIds.add(membroId);
    registrarAuditoria('Membro $membroId adicionado a tarefa $id.');
  }

  void adicionarEtiqueta(String etiqueta) {
    final String valorTratado = etiqueta.trim().toLowerCase();
    if (valorTratado.isNotEmpty) {
      _etiquetas.add(valorTratado);
    }
  }

  void adicionarSubtarefa(Subtarefa subtarefa) {
    if (_subtarefas.any((item) => item.id == subtarefa.id)) {
      throw EntidadeDuplicadaException('Subtarefa', subtarefa.id);
    }
    if (!_membrosIds.contains(subtarefa.responsavelId)) {
      throw ValidacaoException(
        'O responsavel ${subtarefa.responsavelId} nao pertence a tarefa $id.',
      );
    }
    _subtarefas.add(subtarefa);
    recalcularProgresso();
    registrarAuditoria('Subtarefa ${subtarefa.id} adicionada.');
  }

  void delegarSubtarefa(String subtarefaId, String novoResponsavelId) {
    if (!_membrosIds.contains(novoResponsavelId)) {
      throw ValidacaoException(
        'O membro $novoResponsavelId nao participa da tarefa $id.',
      );
    }

    final Subtarefa subtarefa = _subtarefas.firstWhere(
      (item) => item.id == subtarefaId,
      orElse: () =>
          throw EntidadeNaoEncontradaException('Subtarefa', subtarefaId),
    );
    subtarefa.responsavelId = novoResponsavelId;
    registrarAuditoria(
      'Subtarefa $subtarefaId delegada para $novoResponsavelId.',
    );
  }

  void concluirSubtarefa(String subtarefaId) {
    final Subtarefa subtarefa = _subtarefas.firstWhere(
      (item) => item.id == subtarefaId,
      orElse: () =>
          throw EntidadeNaoEncontradaException('Subtarefa', subtarefaId),
    );
    subtarefa.executarPasso(100);
    recalcularProgresso();
    registrarAuditoria('Subtarefa $subtarefaId concluida.');
  }

  void recalcularProgresso() {
    if (_subtarefas.isEmpty) {
      return;
    }
    final double total = _subtarefas.fold<double>(
      0,
      (soma, subtarefa) => soma + subtarefa.progresso,
    );
    progresso = total / _subtarefas.length;
  }

  @override
  void executarPasso(double incremento) {
    if (status == StatusTarefa.bloqueada) {
      throw const TransicaoStatusException(
        'Nao e possivel avancar uma tarefa bloqueada.',
      );
    }
    progresso = (progresso + incremento).clamp(0, 100).toDouble();
    registrarAuditoria(
      'Progresso atualizado para ${progresso.toStringAsFixed(0)}%.',
    );
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'titulo': titulo,
        if (descricao != null) 'descricao': descricao,
        'criadorId': criadorId,
        'membrosIds': <String>[for (final String id in _membrosIds) id],
        'etiquetas': <String>[for (final String tag in _etiquetas) tag],
        'prioridade': prioridade.name,
        'status': status.name,
        'progresso': progresso,
        'criadoEm': criadoEm.toIso8601String(),
        if (prazo != null) 'prazo': prazo?.toIso8601String(),
        'subtarefas': _subtarefas
            .map((subtarefa) => subtarefa.toMap())
            .toList(growable: false),
      };

  @override
  String toString() =>
      '${super.toString()}, membros: ${_membrosIds.length}, '
      'subtarefas: ${_subtarefas.length}';
}


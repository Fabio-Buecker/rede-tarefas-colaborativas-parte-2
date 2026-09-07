import '../core/auditoria_mixin.dart';
import '../core/enums.dart';
import '../core/exceptions.dart';
import 'item_trabalho.dart';
import 'subtarefa.dart';

/// Tarefa principal compartilhada entre vários membros da rede.
///
/// A classe herda as regras de [ItemTrabalho], usa composição ao guardar
/// objetos [Subtarefa] e recebe auditoria por meio de [AuditoriaMixin].
class TarefaColaborativa extends ItemTrabalho with AuditoriaMixin {
  /// Membro que criou a tarefa e que sempre faz parte dela.
  final String criadorId;

  /// Identificadores únicos dos participantes; `Set` evita repetições.
  final Set<String> _membrosIds;

  /// Marcadores normalizados usados para categorizar a tarefa.
  final Set<String> _etiquetas;

  /// Partes menores de trabalho mantidas na ordem de inclusão.
  final List<Subtarefa> _subtarefas;

  /// Construtor completo de uma tarefa colaborativa.
  ///
  /// Os literais com `...` espalham os itens recebidos nas coleções internas.
  /// O criador é inserido no conjunto mesmo que [membrosIds] não o contenha.
  TarefaColaborativa({
    required super.id,
    required String titulo,
    required this.criadorId,
    required Iterable<String> membrosIds,
    super.descricao,
    super.prazo,
    super.prioridade = PrioridadeTarefa.media,
    super.criadoEm,
    super.status = StatusTarefa.pendente,
    super.progresso = 0,
    Iterable<String>? etiquetas,
    Iterable<Subtarefa>? subtarefas,
  })  : _membrosIds = <String>{criadorId, ...membrosIds},
        // `...?` espalha a coleção apenas se ela não for nula.
        _etiquetas = <String>{...?etiquetas},
        _subtarefas = <Subtarefa>[...?subtarefas],
        super(
          titulo: titulo,
        ) {
    if (criadorId.trim().isEmpty) {
      throw const ValidacaoException('O criador da tarefa e obrigatorio.');
    }
    // Subtarefas preexistentes determinam o progresso inicial da tarefa.
    recalcularProgresso();
    registrarAuditoria('Tarefa "$titulo" criada por $criadorId.');
  }

  /// Construtor nomeado para uma tarefa inicial simples de planejamento.
  TarefaColaborativa.planejamento({
    required super.id,
    required super.titulo,
    required this.criadorId,
  })  : _membrosIds = <String>{criadorId},
        _etiquetas = <String>{'planejamento'},
        _subtarefas = <Subtarefa>[],
        super(
          prioridade: PrioridadeTarefa.baixa,
        ) {
    if (criadorId.trim().isEmpty) {
      throw const ValidacaoException('O criador da tarefa e obrigatorio.');
    }
    registrarAuditoria('Tarefa criada pelo construtor nomeado.');
  }

  /// Desserializa uma tarefa e suas subtarefas a partir de um mapa.
  ///
  /// Como mapas podem vir de JSON ou cache sem tipos totalmente confiáveis,
  /// cada coleção é inspecionada antes da conversão. Valores inválidos são
  /// substituídos por coleções vazias ou pelos padrões dos conversores.
  factory TarefaColaborativa.fromMap(Map<String, dynamic> map) {
    final Object? membrosBrutos = map['membrosIds'];
    // `whereType<String>` mantém somente elementos que são realmente textos.
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
            // Cada mapa genérico é convertido e entregue à factory da subtarefa.
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
      criadoEm: criadoEmTexto == null ? null : DateTime.tryParse(criadoEmTexto),
      prioridade: prioridadeTarefaFromString(map['prioridade'] as String?),
      status: statusTarefaFromString(map['status'] as String?),
      progresso: (map['progresso'] as num?)?.toDouble() ?? 0,
      etiquetas: etiquetas,
      subtarefas: subtarefas,
    );
  }

  /// Participantes em uma coleção somente de leitura.
  Set<String> get membrosIds => Set<String>.unmodifiable(_membrosIds);

  /// Etiquetas em uma coleção somente de leitura.
  Set<String> get etiquetas => Set<String>.unmodifiable(_etiquetas);

  /// Subtarefas em uma lista somente de leitura.
  List<Subtarefa> get subtarefas => List<Subtarefa>.unmodifiable(_subtarefas);

  /// Inclui um participante válido e registra a ação na auditoria.
  ///
  /// Por ser um `Set`, adicionar novamente o mesmo identificador não o duplica.
  void adicionarMembro(String membroId) {
    if (membroId.trim().isEmpty) {
      throw const ValidacaoException('O id do membro nao pode ser vazio.');
    }
    _membrosIds.add(membroId);
    registrarAuditoria('Membro $membroId adicionado a tarefa $id.');
  }

  /// Normaliza uma etiqueta em minúsculas e ignora textos vazios.
  void adicionarEtiqueta(String etiqueta) {
    final String valorTratado = etiqueta.trim().toLowerCase();
    if (valorTratado.isNotEmpty) {
      _etiquetas.add(valorTratado);
    }
  }

  /// Anexa uma subtarefa se o id for único e o responsável participar da tarefa.
  void adicionarSubtarefa(Subtarefa subtarefa) {
    // `any` interrompe a busca assim que encontra uma subtarefa com o mesmo id.
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

  /// Transfere uma subtarefa existente para outro membro participante.
  void delegarSubtarefa(String subtarefaId, String novoResponsavelId) {
    if (!_membrosIds.contains(novoResponsavelId)) {
      throw ValidacaoException(
        'O membro $novoResponsavelId nao participa da tarefa $id.',
      );
    }

    // `firstWhere` devolve o item correspondente ou lança a exceção de domínio.
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

  /// Conclui a subtarefa indicada e atualiza o progresso agregado da tarefa.
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

  /// Calcula a média aritmética do progresso das subtarefas.
  ///
  /// `fold` começa em zero e acumula os percentuais. Uma tarefa sem subtarefas
  /// mantém seu progresso atual para também poder avançar diretamente.
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

  /// Avança diretamente a tarefa, respeitando o bloqueio e o limite percentual.
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

  /// Serializa a tarefa completa, incluindo coleções e subtarefas aninhadas.
  ///
  /// Os `for` dentro dos literais criam listas novas. `growable: false` indica
  /// que a lista de mapas resultante terá tamanho fixo.
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

  /// Complementa o resumo herdado com quantidades da colaboração.
  @override
  String toString() => '${super.toString()}, membros: ${_membrosIds.length}, '
      'subtarefas: ${_subtarefas.length}';
}

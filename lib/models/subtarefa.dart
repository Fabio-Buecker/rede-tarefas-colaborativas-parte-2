import '../core/enums.dart';
import '../core/exceptions.dart';
import 'item_trabalho.dart';

/// Unidade menor de trabalho que compõe uma tarefa colaborativa.
///
/// `extends ItemTrabalho` aplica herança: a subtarefa recebe os campos e as
/// regras comuns e implementa os métodos abstratos da classe-base.
class Subtarefa extends ItemTrabalho {
  /// Identificador do membro responsável, protegido por validação no setter.
  String _responsavelId;

  /// Construtor completo para uma subtarefa configurável.
  ///
  /// Parâmetros `super.campo` encaminham diretamente ao construtor de
  /// [ItemTrabalho] os dados herdados, sem repetir nomes no inicializador.
  Subtarefa({
    required super.id,
    required super.titulo,
    required String responsavelId,
    super.descricao,
    super.prazo,
    super.prioridade = PrioridadeTarefa.media,
    super.criadoEm,
    super.status = StatusTarefa.pendente,
    super.progresso = 0,
  }) : _responsavelId = responsavelId.trim() {
    // O setter recusa um responsável vazio durante a própria construção.
    this.responsavelId = _responsavelId;
  }

  /// Construtor nomeado simplificado para subtarefas rápidas e de baixa prioridade.
  Subtarefa.rapida({
    required super.id,
    required super.titulo,
    required String responsavelId,
  }) : _responsavelId = responsavelId.trim(),
       super(prioridade: PrioridadeTarefa.baixa) {
    this.responsavelId = _responsavelId;
  }

  /// Reconstrói uma subtarefa a partir de um mapa serializado.
  ///
  /// [DateTime.tryParse] devolve `null`, em vez de lançar erro, se uma data
  /// recebida não estiver no formato ISO esperado.
  factory Subtarefa.fromMap(Map<String, dynamic> map) {
    final String? prazoTexto = map['prazo'] as String?;
    final String? criadoEmTexto = map['criadoEm'] as String?;

    return Subtarefa(
      id: map['id'] as String? ?? '',
      titulo: map['titulo'] as String? ?? 'Subtarefa sem titulo',
      responsavelId: map['responsavelId'] as String? ?? '',
      descricao: map['descricao'] as String?,
      prazo: prazoTexto == null ? null : DateTime.tryParse(prazoTexto),
      criadoEm: criadoEmTexto == null ? null : DateTime.tryParse(criadoEmTexto),
      prioridade: prioridadeTarefaFromString(map['prioridade'] as String?),
      status: statusTarefaFromString(map['status'] as String?),
      progresso: (map['progresso'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Identificador do responsável atual.
  String get responsavelId => _responsavelId;

  /// Remove espaços e impede que a subtarefa fique sem responsável.
  set responsavelId(String novoResponsavelId) {
    final String valorTratado = novoResponsavelId.trim();
    if (valorTratado.isEmpty) {
      throw const ValidacaoException(
        'Toda subtarefa deve possuir um responsavel.',
      );
    }
    _responsavelId = valorTratado;
  }

  /// Avança o percentual da subtarefa, exceto quando ela está bloqueada.
  ///
  /// `clamp(0, 100)` limita o resultado ao intervalo válido, mesmo quando o
  /// incremento ultrapassa os extremos; `toDouble` preserva o tipo do campo.
  @override
  void executarPasso(double incremento) {
    if (status == StatusTarefa.bloqueada) {
      throw const TransicaoStatusException(
        'Nao e possivel avancar uma subtarefa bloqueada.',
      );
    }
    progresso = (progresso + incremento).clamp(0, 100).toDouble();
  }

  /// Converte todos os dados relevantes em um mapa serializável.
  ///
  /// Enums são gravados por `name` e datas em ISO 8601 para que [fromMap]
  /// consiga reconstruir o objeto posteriormente.
  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'titulo': titulo,
    if (descricao != null) 'descricao': descricao,
    'responsavelId': responsavelId,
    'prioridade': prioridade.name,
    'status': status.name,
    'progresso': progresso,
    'criadoEm': criadoEm.toIso8601String(),
    if (prazo != null) 'prazo': prazo?.toIso8601String(),
  };

  /// Reaproveita o texto da classe-base e acrescenta o responsável.
  @override
  String toString() => '${super.toString()}, responsavel: $responsavelId';
}

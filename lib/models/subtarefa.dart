import '../core/enums.dart';
import '../core/exceptions.dart';
import 'item_trabalho.dart';

class Subtarefa extends ItemTrabalho {
  String _responsavelId;

  Subtarefa({
    required String id,
    required String titulo,
    required String responsavelId,
    String? descricao,
    DateTime? prazo,
    PrioridadeTarefa prioridade = PrioridadeTarefa.media,
    DateTime? criadoEm,
    StatusTarefa status = StatusTarefa.pendente,
    double progresso = 0,
  })  : _responsavelId = responsavelId.trim(),
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
    this.responsavelId = _responsavelId;
  }

  Subtarefa.rapida({
    required String id,
    required String titulo,
    required String responsavelId,
  })  : _responsavelId = responsavelId.trim(),
        super(
          id: id,
          titulo: titulo,
          prioridade: PrioridadeTarefa.baixa,
        ) {
    this.responsavelId = _responsavelId;
  }

  factory Subtarefa.fromMap(Map<String, dynamic> map) {
    final String? prazoTexto = map['prazo'] as String?;
    final String? criadoEmTexto = map['criadoEm'] as String?;

    return Subtarefa(
      id: map['id'] as String? ?? '',
      titulo: map['titulo'] as String? ?? 'Subtarefa sem titulo',
      responsavelId: map['responsavelId'] as String? ?? '',
      descricao: map['descricao'] as String?,
      prazo: prazoTexto == null ? null : DateTime.tryParse(prazoTexto),
      criadoEm:
          criadoEmTexto == null ? null : DateTime.tryParse(criadoEmTexto),
      prioridade: prioridadeTarefaFromString(map['prioridade'] as String?),
      status: statusTarefaFromString(map['status'] as String?),
      progresso: (map['progresso'] as num?)?.toDouble() ?? 0,
    );
  }

  String get responsavelId => _responsavelId;

  set responsavelId(String novoResponsavelId) {
    final String valorTratado = novoResponsavelId.trim();
    if (valorTratado.isEmpty) {
      throw const ValidacaoException(
        'Toda subtarefa deve possuir um responsavel.',
      );
    }
    _responsavelId = valorTratado;
  }

  @override
  void executarPasso(double incremento) {
    if (status == StatusTarefa.bloqueada) {
      throw const TransicaoStatusException(
        'Nao e possivel avancar uma subtarefa bloqueada.',
      );
    }
    progresso = (progresso + incremento).clamp(0, 100).toDouble();
  }

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

  @override
  String toString() => '${super.toString()}, responsavel: $responsavelId';
}


import 'dart:convert';
import 'tarefa_colaborativa.dart';

/// Metadados de persistência separados das regras de domínio herdadas da AP1B.
class RegistroLocal {
  final TarefaColaborativa tarefa;
  final String quadroId;
  final int revisao;
  final bool sincronizado;
  final bool excluido;
  final int? remotoId;

  const RegistroLocal({
    required this.tarefa,
    required this.quadroId,
    this.revisao = 1,
    this.sincronizado = false,
    this.excluido = false,
    this.remotoId,
  });

  RegistroLocal copyWith({
    TarefaColaborativa? tarefa,
    String? quadroId,
    int? revisao,
    bool? sincronizado,
    bool? excluido,
    int? remotoId,
  }) => RegistroLocal(
    tarefa: tarefa ?? this.tarefa,
    quadroId: quadroId ?? this.quadroId,
    revisao: revisao ?? this.revisao,
    sincronizado: sincronizado ?? this.sincronizado,
    excluido: excluido ?? this.excluido,
    remotoId: remotoId ?? this.remotoId,
  );

  Map<String, Object?> toMap() => {
    'id': tarefa.id,
    'quadro_id': quadroId,
    'dados': jsonEncode(tarefa.toMap()),
    'revisao': revisao,
    'sincronizado': sincronizado ? 1 : 0,
    'excluido': excluido ? 1 : 0,
    'remoto_id': remotoId,
  };

  factory RegistroLocal.fromMap(Map<String, Object?> map) => RegistroLocal(
    tarefa: TarefaColaborativa.fromMap(
      jsonDecode(map['dados'] as String) as Map<String, dynamic>,
    ),
    quadroId: map['quadro_id'] as String,
    revisao: map['revisao'] as int,
    sincronizado: map['sincronizado'] == 1,
    excluido: map['excluido'] == 1,
    remotoId: map['remoto_id'] as int?,
  );

  String toJson() => jsonEncode({
    'localId': tarefa.id,
    'title': tarefa.titulo,
    'completed': tarefa.progresso == 100,
    'userId': 1,
    'quadroId': quadroId,
    'revisao': revisao,
    'tasklink': tarefa.toMap(),
  });
}

class Quadro {
  final String id;
  final String nome;
  Quadro({required this.id, required String nome}) : nome = nome.trim() {
    if (id.trim().isEmpty || this.nome.length < 3) {
      throw ArgumentError(
        'Informe um nome de quadro com pelo menos 3 caracteres.',
      );
    }
  }
  Map<String, Object?> toMap() => {'id': id, 'nome': nome};
  factory Quadro.fromMap(Map<String, Object?> map) =>
      Quadro(id: map['id'] as String, nome: map['nome'] as String);
}

class LogSync {
  final String instante;
  final String mensagem;
  final bool sucesso;
  const LogSync(this.instante, this.mensagem, this.sucesso);
  Map<String, Object?> toMap() => {
    'instante': instante,
    'mensagem': mensagem,
    'sucesso': sucesso ? 1 : 0,
  };
  factory LogSync.fromMap(Map<String, Object?> map) => LogSync(
    map['instante'] as String,
    map['mensagem'] as String,
    map['sucesso'] == 1,
  );
}

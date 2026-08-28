enum StatusTarefa {
  pendente,
  emAndamento,
  bloqueada,
  concluida,
}

enum PrioridadeTarefa {
  baixa,
  media,
  alta,
  urgente,
}

extension StatusTarefaTexto on StatusTarefa {
  String get rotulo => switch (this) {
        StatusTarefa.pendente => 'Pendente',
        StatusTarefa.emAndamento => 'Em andamento',
        StatusTarefa.bloqueada => 'Bloqueada',
        StatusTarefa.concluida => 'Concluida',
      };
}

extension PrioridadeTarefaTexto on PrioridadeTarefa {
  String get rotulo => switch (this) {
        PrioridadeTarefa.baixa => 'Baixa',
        PrioridadeTarefa.media => 'Media',
        PrioridadeTarefa.alta => 'Alta',
        PrioridadeTarefa.urgente => 'Urgente',
      };
}

StatusTarefa statusTarefaFromString(String? valor) {
  return StatusTarefa.values.firstWhere(
    (status) => status.name == valor,
    orElse: () => StatusTarefa.pendente,
  );
}

PrioridadeTarefa prioridadeTarefaFromString(String? valor) {
  return PrioridadeTarefa.values.firstWhere(
    (prioridade) => prioridade.name == valor,
    orElse: () => PrioridadeTarefa.media,
  );
}


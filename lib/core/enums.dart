/// Estados possíveis de uma tarefa durante seu ciclo de vida.
///
/// Um `enum` limita o valor a uma das opções declaradas abaixo, evitando o uso
/// de textos livres e possíveis erros de digitação nas comparações.
enum StatusTarefa {
  /// A tarefa foi criada, mas nenhum trabalho foi iniciado.
  pendente,

  /// Existe trabalho realizado, porém a tarefa ainda não terminou.
  emAndamento,

  /// Um impedimento temporário não permite que a tarefa avance.
  bloqueada,

  /// Todo o trabalho necessário foi finalizado.
  concluida,
}

/// Níveis usados para ordenar ou destacar a urgência de uma tarefa.
enum PrioridadeTarefa {
  /// Pode ser atendida depois das demais prioridades.
  baixa,

  /// Prioridade padrão quando nenhum valor é informado.
  media,

  /// Deve receber atenção antes das tarefas comuns.
  alta,

  /// Requer tratamento imediato.
  urgente,
}

/// Acrescenta uma representação amigável a cada [StatusTarefa].
///
/// Uma `extension` inclui comportamento em um tipo existente sem alterar sua
/// declaração original. O getter permite escrever `status.rotulo`.
extension StatusTarefaTexto on StatusTarefa {
  /// Converte o valor técnico do enum em texto próprio para relatórios.
  ///
  /// O `switch` expression é exaustivo: o compilador exige um caso para cada
  /// valor de [StatusTarefa]. `this` representa a instância atual do enum.
  String get rotulo => switch (this) {
    StatusTarefa.pendente => 'Pendente',
    StatusTarefa.emAndamento => 'Em andamento',
    StatusTarefa.bloqueada => 'Bloqueada',
    StatusTarefa.concluida => 'Concluida',
  };
}

/// Acrescenta um rótulo legível aos valores de [PrioridadeTarefa].
extension PrioridadeTarefaTexto on PrioridadeTarefa {
  /// Retorna o texto que será exibido para a prioridade atual.
  String get rotulo => switch (this) {
    PrioridadeTarefa.baixa => 'Baixa',
    PrioridadeTarefa.media => 'Media',
    PrioridadeTarefa.alta => 'Alta',
    PrioridadeTarefa.urgente => 'Urgente',
  };
}

/// Converte o nome persistido em texto para um [StatusTarefa].
///
/// [valor] aceita `null` porque dados externos podem estar incompletos.
/// `firstWhere` procura um enum cujo `name` seja igual ao texto recebido; se
/// nenhum for encontrado, `orElse` aplica [StatusTarefa.pendente] como padrão.
StatusTarefa statusTarefaFromString(String? valor) {
  return StatusTarefa.values.firstWhere(
    (status) => status.name == valor,
    orElse: () => StatusTarefa.pendente,
  );
}

/// Converte texto em [PrioridadeTarefa], usando a prioridade média como padrão.
PrioridadeTarefa prioridadeTarefaFromString(String? valor) {
  return PrioridadeTarefa.values.firstWhere(
    (prioridade) => prioridade.name == valor,
    orElse: () => PrioridadeTarefa.media,
  );
}

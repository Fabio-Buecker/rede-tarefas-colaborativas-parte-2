/// Comportamento reutilizável para objetos que precisam registrar auditoria.
///
/// Um `mixin` compartilha campos e métodos sem exigir que as classes pertençam
/// à mesma hierarquia de herança. Neste projeto ele é aplicado com a palavra
/// `with` ao gerenciador e às tarefas colaborativas.
mixin AuditoriaMixin {
  /// Lista privada e mutável que armazena os registros na ordem de criação.
  final List<String> _historicoAuditoria = <String>[];

  /// Expõe uma visão somente de leitura do histórico.
  ///
  /// Criar uma lista `unmodifiable` impede que código externo use `add`,
  /// `remove` ou `clear` e contorne o método [registrarAuditoria].
  List<String> get historicoAuditoria =>
      List<String>.unmodifiable(_historicoAuditoria);

  /// Retorna o registro mais recente ou `null` quando ainda não há registros.
  /// O operador ternário escolhe uma das duas expressões conforme a condição.
  String? get ultimoRegistroAuditoria =>
      _historicoAuditoria.isEmpty ? null : _historicoAuditoria.last;

  /// Acrescenta [mensagem] ao histórico junto do instante atual em ISO 8601.
  void registrarAuditoria(String mensagem) {
    final String timestamp = DateTime.now().toIso8601String();
    _historicoAuditoria.add('[$timestamp] $mensagem');
  }
}

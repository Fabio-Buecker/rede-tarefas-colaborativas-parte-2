mixin AuditoriaMixin {
  final List<String> _historicoAuditoria = <String>[];

  List<String> get historicoAuditoria =>
      List<String>.unmodifiable(_historicoAuditoria);

  String? get ultimoRegistroAuditoria =>
      _historicoAuditoria.isEmpty ? null : _historicoAuditoria.last;

  void registrarAuditoria(String mensagem) {
    final String timestamp = DateTime.now().toIso8601String();
    _historicoAuditoria.add('[$timestamp] $mensagem');
  }
}


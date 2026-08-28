import '../core/exceptions.dart';

class Membro {
  final String id;
  final String? email;
  String _nome;

  Membro({
    required this.id,
    required String nome,
    this.email,
  }) : _nome = nome.trim() {
    _validarId(id);
    this.nome = _nome;
    _validarEmail(email);
  }

  Membro.convidado({
    required this.id,
    String nome = 'Convidado',
  })  : _nome = nome.trim(),
        email = null {
    _validarId(id);
    this.nome = _nome;
  }

  factory Membro.fromMap(Map<String, dynamic> map) {
    final String id = map['id'] as String? ?? '';
    final String nome = map['nome'] as String? ?? 'Membro sem nome';
    final String? email = map['email'] as String?;

    return Membro(id: id, nome: nome, email: email);
  }

  String get nome => _nome;

  set nome(String novoNome) {
    final String nomeTratado = novoNome.trim();
    if (nomeTratado.length < 3) {
      throw const ValidacaoException(
        'O nome do membro deve possuir pelo menos 3 caracteres.',
      );
    }
    _nome = nomeTratado;
  }

  String get contatoPreferencial => email ?? 'E-mail nao informado';

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'nome': nome,
        if (email != null) 'email': email,
      };

  static void _validarId(String valor) {
    if (valor.trim().isEmpty) {
      throw const ValidacaoException('O id do membro e obrigatorio.');
    }
  }

  static void _validarEmail(String? valor) {
    if (valor != null && (!valor.contains('@') || !valor.contains('.'))) {
      throw const ValidacaoException('O e-mail informado e invalido.');
    }
  }

  @override
  String toString() =>
      'Membro(id: $id, nome: $nome, contato: $contatoPreferencial)';
}

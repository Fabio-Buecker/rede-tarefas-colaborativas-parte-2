import '../core/exceptions.dart';

/// Pessoa que pode participar e receber tarefas na rede colaborativa.
class Membro {
  /// Identificador único do membro.
  final String id;

  /// Endereço de contato opcional; convidados podem não possuir e-mail.
  final String? email;

  /// Nome encapsulado para que qualquer alteração passe pela validação.
  String _nome;

  /// Construtor gerativo principal, usado para membros comuns.
  Membro({
    required this.id,
    required String nome,
    this.email,
  }) : _nome = nome.trim() {
    // Métodos privados estáticos validam os valores sem depender da instância.
    _validarId(id);
    this.nome = _nome;
    _validarEmail(email);
  }

  /// Construtor nomeado para criar um usuário sem endereço de e-mail.
  ///
  /// Ele oferece valores iniciais próprios, mas ainda executa as validações
  /// comuns de identificador e nome.
  Membro.convidado({
    required this.id,
    String nome = 'Convidado',
  })  : _nome = nome.trim(),
        email = null {
    _validarId(id);
    this.nome = _nome;
  }

  /// Constrói um membro a partir de dados genéricos, como JSON decodificado.
  ///
  /// `as String?` verifica o tipo e permite `null`; `??` fornece um valor
  /// alternativo quando a chave está ausente ou contém `null`.
  factory Membro.fromMap(Map<String, dynamic> map) {
    final String id = map['id'] as String? ?? '';
    final String nome = map['nome'] as String? ?? 'Membro sem nome';
    final String? email = map['email'] as String?;

    return Membro(id: id, nome: nome, email: email);
  }

  /// Nome atual do membro.
  String get nome => _nome;

  /// Normaliza o nome e rejeita valores com menos de três caracteres.
  set nome(String novoNome) {
    final String nomeTratado = novoNome.trim();
    if (nomeTratado.length < 3) {
      throw const ValidacaoException(
        'O nome do membro deve possuir pelo menos 3 caracteres.',
      );
    }
    _nome = nomeTratado;
  }

  /// Retorna o e-mail ou uma mensagem segura quando ele não foi informado.
  String get contatoPreferencial => email ?? 'E-mail nao informado';

  /// Serializa o membro em pares de chave e valor.
  ///
  /// O `if` dentro do literal inclui `email` somente quando existe um valor.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'nome': nome,
        if (email != null) 'email': email,
      };

  /// Garante que o identificador possua ao menos um caractere não vazio.
  static void _validarId(String valor) {
    if (valor.trim().isEmpty) {
      throw const ValidacaoException('O id do membro e obrigatorio.');
    }
  }

  /// Faz uma validação simples de formato quando um e-mail é fornecido.
  static void _validarEmail(String? valor) {
    if (valor != null && (!valor.contains('@') || !valor.contains('.'))) {
      throw const ValidacaoException('O e-mail informado e invalido.');
    }
  }

  /// Retorna uma descrição curta útil para logs e demonstrações.
  @override
  String toString() =>
      'Membro(id: $id, nome: $nome, contato: $contatoPreferencial)';
}

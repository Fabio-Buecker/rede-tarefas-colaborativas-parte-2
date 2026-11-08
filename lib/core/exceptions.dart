/// Classe-base para erros previstos pelas regras de negócio do projeto.
///
/// É abstrata porque representa uma categoria de erro e não deve ser criada
/// diretamente. Implementar [Exception] permite lançar as subclasses com
/// `throw` e capturá-las com `try`/`catch`.
abstract class DominioException implements Exception {
  /// Explicação do problema adequada para logs ou para a interface do usuário.
  final String mensagem;

  /// Inicializa uma exceção imutável com sua [mensagem].
  const DominioException(this.mensagem);

  /// Define a forma textual exibida ao interpolar ou imprimir a exceção.
  /// [runtimeType] informa qual subclasse concreta originou o erro.
  @override
  String toString() => '$runtimeType: $mensagem';
}

/// Indica que um dado recebido não atende às validações do domínio.
class ValidacaoException extends DominioException {
  /// Encaminha [mensagem] ao construtor da classe-base com `super`.
  const ValidacaoException(super.mensagem);
}

/// Indica que uma consulta obrigatória não encontrou a entidade solicitada.
class EntidadeNaoEncontradaException extends DominioException {
  /// Nome da categoria pesquisada, por exemplo, `Tarefa` ou `Membro`.
  final String tipo;

  /// Identificador que não foi localizado.
  final String id;

  /// Monta automaticamente uma mensagem com o [tipo] e o [id] recebidos.
  const EntidadeNaoEncontradaException(this.tipo, this.id)
    : super('$tipo com id "$id" nao foi encontrado.');
}

/// Indica tentativa de cadastrar outro objeto com um identificador já usado.
class EntidadeDuplicadaException extends DominioException {
  /// Cria a mensagem de duplicidade a partir do tipo e do identificador.
  const EntidadeDuplicadaException(String tipo, String id)
    : super('$tipo com id "$id" ja esta cadastrado.');
}

/// Indica uma mudança de estado proibida pelas regras de uma tarefa.
class TransicaoStatusException extends DominioException {
  const TransicaoStatusException(super.mensagem);
}

/// Representa uma operação que depende de rede quando o sistema está offline.
class ConectividadeException extends DominioException {
  const ConectividadeException(super.mensagem);
}

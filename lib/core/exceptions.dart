abstract class DominioException implements Exception {
  final String mensagem;

  const DominioException(this.mensagem);

  @override
  String toString() => '$runtimeType: $mensagem';
}

class ValidacaoException extends DominioException {
  const ValidacaoException(super.mensagem);
}

class EntidadeNaoEncontradaException extends DominioException {
  final String tipo;
  final String id;

  const EntidadeNaoEncontradaException(this.tipo, this.id)
      : super('$tipo com id "$id" nao foi encontrado.');
}

class EntidadeDuplicadaException extends DominioException {
  const EntidadeDuplicadaException(String tipo, String id)
      : super('$tipo com id "$id" ja esta cadastrado.');
}

class TransicaoStatusException extends DominioException {
  const TransicaoStatusException(super.mensagem);
}

class ConectividadeException extends DominioException {
  const ConectividadeException(super.mensagem);
}


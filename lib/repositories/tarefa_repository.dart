import '../models/tarefa_colaborativa.dart';

/// Abstração da fonte de dados usada para armazenar tarefas.
///
/// `abstract interface class` declara apenas o contrato público. A camada de
/// negócio depende desta interface, podendo trocar a implementação em memória
/// por banco de dados ou API sem alterar o gerenciador.
abstract interface class TarefaRepository {
  /// Persiste uma nova [tarefa].
  void salvar(TarefaColaborativa tarefa);

  /// Retorna a tarefa do [id] ou `null` quando ela não existe.
  TarefaColaborativa? buscarPorId(String id);

  /// Retorna todas as tarefas disponíveis na fonte de dados.
  List<TarefaColaborativa> listar();

  /// Remove a tarefa do [id] e informa se algum item foi removido.
  bool remover(String id);
}

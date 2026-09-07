import '../core/exceptions.dart';
import '../models/tarefa_colaborativa.dart';
import 'tarefa_repository.dart';

/// Implementação volátil de [TarefaRepository] baseada em um mapa local.
///
/// É apropriada para demonstrações e testes. Os dados existem somente enquanto
/// o processo está em execução e são indexados pelo id para acesso direto.
class TarefaRepositoryMemoria implements TarefaRepository {
  /// Associa cada id à sua tarefa; o campo não é exposto fora da classe.
  final Map<String, TarefaColaborativa> _tarefas =
      <String, TarefaColaborativa>{};

  /// Acesso de mapa retorna `null` naturalmente para uma chave desconhecida.
  @override
  TarefaColaborativa? buscarPorId(String id) => _tarefas[id];

  /// Cria uma lista não modificável para proteger a coleção interna.
  @override
  List<TarefaColaborativa> listar() =>
      List<TarefaColaborativa>.unmodifiable(_tarefas.values);

  /// [Map.remove] devolve o objeto removido ou `null`; a comparação vira `bool`.
  @override
  bool remover(String id) => _tarefas.remove(id) != null;

  /// Salva uma tarefa somente quando seu identificador ainda não está ocupado.
  @override
  void salvar(TarefaColaborativa tarefa) {
    if (_tarefas.containsKey(tarefa.id)) {
      throw EntidadeDuplicadaException('Tarefa', tarefa.id);
    }
    _tarefas[tarefa.id] = tarefa;
  }
}

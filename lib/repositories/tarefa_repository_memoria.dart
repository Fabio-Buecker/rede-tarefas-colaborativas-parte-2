import '../core/exceptions.dart';
import '../models/tarefa_colaborativa.dart';
import 'tarefa_repository.dart';

class TarefaRepositoryMemoria implements TarefaRepository {
  final Map<String, TarefaColaborativa> _tarefas =
      <String, TarefaColaborativa>{};

  @override
  TarefaColaborativa? buscarPorId(String id) => _tarefas[id];

  @override
  List<TarefaColaborativa> listar() =>
      List<TarefaColaborativa>.unmodifiable(_tarefas.values);

  @override
  bool remover(String id) => _tarefas.remove(id) != null;

  @override
  void salvar(TarefaColaborativa tarefa) {
    if (_tarefas.containsKey(tarefa.id)) {
      throw EntidadeDuplicadaException('Tarefa', tarefa.id);
    }
    _tarefas[tarefa.id] = tarefa;
  }
}


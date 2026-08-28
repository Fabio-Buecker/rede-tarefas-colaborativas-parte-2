import '../models/tarefa_colaborativa.dart';

abstract interface class TarefaRepository {
  void salvar(TarefaColaborativa tarefa);

  TarefaColaborativa? buscarPorId(String id);

  List<TarefaColaborativa> listar();

  bool remover(String id);
}


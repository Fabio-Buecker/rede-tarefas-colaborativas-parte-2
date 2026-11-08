import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rede_tarefas_colaborativas/controllers/app_controller.dart';
import 'package:rede_tarefas_colaborativas/datasources/local_dao.dart';
import 'package:rede_tarefas_colaborativas/datasources/api_service.dart';
import 'package:rede_tarefas_colaborativas/models/registro_local.dart';
import 'package:rede_tarefas_colaborativas/models/tarefa_colaborativa.dart';
import 'package:rede_tarefas_colaborativas/repositories/offline_repository.dart';

RegistroLocal exemplo({String id = 't1', bool synced = false, int? remote}) =>
    RegistroLocal(
      tarefa: TarefaColaborativa(
        id: id,
        titulo: 'Preparar entrega',
        criadorId: 'Ana',
        membrosIds: {'Ana', 'Bruno'},
      ),
      quadroId: 'geral',
      sincronizado: synced,
      remotoId: remote,
    );

class FakeLocal implements LocalDatasource {
  final Map<String, RegistroLocal> items = {};
  final Map<String, Quadro> boards = {
    'geral': Quadro(id: 'geral', nome: 'Equipe'),
  };
  final List<LogSync> history = [];
  bool falhar = false;
  @override
  Future<void> salvar(RegistroLocal r) async {
    if (falhar) throw StateError('Disco indisponível');
    items[r.tarefa.id] = r;
  }

  @override
  Future<List<RegistroLocal>> listar({bool incluirExcluidos = false}) async =>
      items.values.where((r) => incluirExcluidos || !r.excluido).toList();
  @override
  Future<bool> confirmar(RegistroLocal r, int? id) async {
    final atual = items[r.tarefa.id];
    if (atual != null && !r.excluido && atual.remotoId == null && id != null) {
      items[r.tarefa.id] = atual.copyWith(remotoId: id);
    }
    if (items[r.tarefa.id]?.revisao != r.revisao) return false;
    if (r.excluido) {
      items.remove(r.tarefa.id);
    } else {
      items[r.tarefa.id] = r.copyWith(sincronizado: true, remotoId: id);
    }
    return true;
  }

  @override
  Future<List<Quadro>> quadros() async => boards.values.toList();
  @override
  Future<void> salvarQuadro(Quadro q) async {
    boards[q.id] = q;
  }

  @override
  Future<void> excluirQuadro(String id) async {
    boards.remove(id);
  }

  @override
  Future<void> log(LogSync l) async {
    history.insert(0, l);
  }

  @override
  Future<List<LogSync>> logs() async => history;
}

Future<AppController> controlador({bool comTarefa = false}) async {
  SharedPreferences.setMockInitialValues({'offline': true});
  final local = FakeLocal();
  if (comTarefa) await local.salvar(exemplo());
  final c = AppController(
    OfflineRepository(
      local,
      ApiService(MockClient((_) async => http.Response('{"id":1}', 201))),
    ),
    await SharedPreferences.getInstance(),
  );
  await c.carregar();
  return c;
}

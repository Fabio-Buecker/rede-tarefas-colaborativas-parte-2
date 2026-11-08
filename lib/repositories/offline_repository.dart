import 'package:uuid/uuid.dart';
import '../datasources/api_service.dart';
import '../datasources/local_dao.dart';
import '../models/registro_local.dart';
import '../models/tarefa_colaborativa.dart';

class ResultadoSync {
  final int enviados;
  final int falhas;
  final String? erro;
  const ResultadoSync(this.enviados, this.falhas, [this.erro]);
}

class OfflineRepository {
  final LocalDatasource local;
  final ApiService api;
  Future<ResultadoSync>? _emCurso;
  OfflineRepository(this.local, this.api);
  Future<List<RegistroLocal>> listar() => local.listar();

  /// Escrita local apenas: a tela pode renderizar imediatamente, sem esperar HTTP.
  Future<void> salvar(RegistroLocal registro) async {
    final todos = await local.listar(incluirExcluidos: true);
    final anteriores = todos.where((r) => r.tarefa.id == registro.tarefa.id);
    final anterior = anteriores.isEmpty ? null : anteriores.first;
    await local.salvar(
      registro.copyWith(
        sincronizado: false,
        revisao: (anterior?.revisao ?? 0) + 1,
        remotoId: anterior?.remotoId,
      ),
    );
  }

  Future<void> excluir(RegistroLocal registro) async {
    await salvar(registro.copyWith(excluido: true));
  }

  Future<ResultadoSync> sincronizar() {
    final atual = _emCurso;
    if (atual != null) return atual;
    final future = _sincronizar();
    _emCurso = future;
    return future.whenComplete(() {
      _emCurso = null;
    });
  }

  Future<ResultadoSync> _sincronizar() async {
    final pendentes = (await local.listar(
      incluirExcluidos: true,
    )).where((r) => !r.sincronizado).toList();
    var enviados = 0;
    var falhas = 0;
    String? erro;
    for (final item in pendentes) {
      try {
        final id = await api.enviar(item);
        if (await local.confirmar(item, id)) enviados++;
        await local.log(
          LogSync(
            DateTime.now().toIso8601String(),
            'Envio de ${item.tarefa.titulo} confirmado (revisão ${item.revisao}).',
            true,
          ),
        );
      } on RedeException catch (e) {
        falhas++;
        erro = e.mensagem;
        await local.log(
          LogSync(
            DateTime.now().toIso8601String(),
            '${item.tarefa.titulo}: $e',
            false,
          ),
        );
      }
    }
    return ResultadoSync(enviados, falhas, erro);
  }

  /// GET explícito de modelos. Cada importação vira uma cópia local editável.
  Future<int> importarCatalogo(String quadroId) async {
    final catalogo = await api.catalogo();
    final existentes = await local.listar(incluirExcluidos: true);
    var quantidade = 0;
    for (final item in catalogo) {
      final remoteId = (item['id'] as num?)?.toInt();
      final id = 'catalogo-$remoteId';
      if (remoteId == null || existentes.any((r) => r.tarefa.id == id)) {
        continue;
      }
      final titulo = item['title'];
      if (titulo is! String || titulo.trim().length < 3) continue;
      final tarefa = TarefaColaborativa(
        id: id,
        titulo: titulo,
        criadorId: 'Equipe',
        membrosIds: {'Equipe'},
        progresso: item['completed'] == true ? 100 : 0,
      );
      await local.salvar(
        RegistroLocal(
          tarefa: tarefa,
          quadroId: quadroId,
          remotoId: remoteId,
          sincronizado: true,
        ),
      );
      quantidade++;
    }
    await local.log(
      LogSync(
        DateTime.now().toIso8601String(),
        '$quantidade modelos importados por GET.',
        true,
      ),
    );
    return quantidade;
  }

  static String novoId() => const Uuid().v4();
}

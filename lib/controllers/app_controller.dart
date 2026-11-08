import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/registro_local.dart';
import '../repositories/offline_repository.dart';

class AppController extends ChangeNotifier {
  final OfflineRepository repository;
  final SharedPreferences preferences;
  List<RegistroLocal> registros = [];
  List<Quadro> quadros = [];
  List<LogSync> historico = [];
  bool carregando = true;
  bool sincronizando = false;
  bool modoOffline;
  bool escuro;
  String? erro;
  String? ultimaSync;
  AppController(this.repository, this.preferences)
    : modoOffline = preferences.getBool('offline') ?? false,
      escuro = preferences.getBool('escuro') ?? false,
      ultimaSync = preferences.getString('ultima_sync');

  int get pendentes => registros.where((r) => !r.sincronizado).length;
  Future<void> carregar() async {
    try {
      registros = await repository.local.listar(incluirExcluidos: true);
      quadros = await repository.local.quadros();
      historico = await repository.local.logs();
      erro = null;
    } catch (e) {
      erro = 'Falha ao abrir os dados locais: $e';
    }
    carregando = false;
    notifyListeners();
  }

  Future<void> salvar(RegistroLocal r) async {
    await repository.salvar(r);
    await carregar();
    if (!modoOffline) unawaited(sincronizar());
  }

  Future<void> excluir(RegistroLocal r) async {
    await repository.excluir(r);
    await carregar();
    if (!modoOffline) unawaited(sincronizar());
  }

  Future<ResultadoSync> sincronizar() async {
    if (modoOffline) {
      return const ResultadoSync(
        0,
        0,
        'Modo offline ativado nas configurações.',
      );
    }
    if (sincronizando) {
      return const ResultadoSync(0, 0, 'Sincronização já está em andamento.');
    }
    sincronizando = true;
    notifyListeners();
    try {
      final resultado = await repository.sincronizar();
      erro = resultado.erro;
      if (resultado.falhas == 0) {
        ultimaSync = DateTime.now().toIso8601String();
        await preferences.setString('ultima_sync', ultimaSync!);
      }
      return resultado;
    } catch (e) {
      erro = 'Não foi possível sincronizar: $e';
      return ResultadoSync(0, 1, erro);
    } finally {
      final falha = erro;
      sincronizando = false;
      await carregar();
      erro = falha;
      notifyListeners();
    }
  }

  Future<void> configurar({bool? offline, bool? temaEscuro}) async {
    modoOffline = offline ?? modoOffline;
    escuro = temaEscuro ?? escuro;
    await preferences.setBool('offline', modoOffline);
    await preferences.setBool('escuro', escuro);
    notifyListeners();
    if (offline == false) unawaited(sincronizar());
  }

  RegistroLocal? porId(String id) {
    final lista = registros.where((r) => r.tarefa.id == id && !r.excluido);
    return lista.isEmpty ? null : lista.first;
  }
}

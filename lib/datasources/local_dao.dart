import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/registro_local.dart';

abstract class LocalDatasource {
  Future<List<Quadro>> quadros();
  Future<void> salvarQuadro(Quadro quadro);
  Future<void> excluirQuadro(String id);
  Future<List<RegistroLocal>> listar({bool incluirExcluidos = false});
  Future<void> salvar(RegistroLocal registro);
  Future<bool> confirmar(RegistroLocal enviado, int? remotoId);
  Future<void> log(LogSync log);
  Future<List<LogSync>> logs();
}

/// Uma conexão por instância de aplicação. SQL nunca é executado nos widgets.
class LocalDao implements LocalDatasource {
  final Database db;
  LocalDao(this.db);
  static Future<LocalDao> abrir({
    DatabaseFactory? factory,
    String? caminho,
  }) async {
    final f = factory ?? databaseFactory;
    final path =
        caminho ?? p.join(await f.getDatabasesPath(), 'tasklink_v2.db');
    final db = await f.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE quadros(id TEXT PRIMARY KEY, nome TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE tarefas(id TEXT PRIMARY KEY, quadro_id TEXT NOT NULL REFERENCES quadros(id) ON DELETE RESTRICT, dados TEXT NOT NULL, revisao INTEGER NOT NULL, sincronizado INTEGER NOT NULL, excluido INTEGER NOT NULL, remoto_id INTEGER)',
          );
          await db.execute(
            'CREATE TABLE subtarefas(id TEXT NOT NULL, tarefa_id TEXT NOT NULL REFERENCES tarefas(id) ON DELETE CASCADE, dados TEXT NOT NULL, PRIMARY KEY(tarefa_id,id))',
          );
          await db.execute(
            'CREATE TABLE sync_logs(id INTEGER PRIMARY KEY AUTOINCREMENT, instante TEXT NOT NULL, mensagem TEXT NOT NULL, sucesso INTEGER NOT NULL)',
          );
          await db.insert('quadros', {
            'id': 'geral',
            'nome': 'Quadro da equipe',
          });
        },
      ),
    );
    return LocalDao(db);
  }

  @override
  Future<List<Quadro>> quadros() async =>
      (await db.query('quadros', orderBy: 'nome')).map(Quadro.fromMap).toList();
  @override
  Future<void> salvarQuadro(Quadro quadro) async {
    if (await db.update(
          'quadros',
          quadro.toMap(),
          where: 'id = ?',
          whereArgs: [quadro.id],
        ) ==
        0) {
      await db.insert('quadros', quadro.toMap());
    }
  }

  @override
  Future<void> excluirQuadro(String id) async {
    final dependentes = await db.query(
      'tarefas',
      columns: ['id'],
      where: 'quadro_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (dependentes.isNotEmpty) {
      throw StateError(
        'Mova ou sincronize a exclusão das tarefas antes de remover o quadro.',
      );
    }
    await db.delete('quadros', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<RegistroLocal>> listar({bool incluirExcluidos = false}) async =>
      (await db.query(
        'tarefas',
        where: incluirExcluidos ? null : 'excluido = 0',
        orderBy: 'rowid DESC',
      )).map(RegistroLocal.fromMap).toList();
  @override
  Future<void> salvar(RegistroLocal registro) => db.transaction((txn) async {
    if (await txn.update(
          'tarefas',
          registro.toMap(),
          where: 'id = ?',
          whereArgs: [registro.tarefa.id],
        ) ==
        0) {
      await txn.insert('tarefas', registro.toMap());
    }
    await txn.delete(
      'subtarefas',
      where: 'tarefa_id = ?',
      whereArgs: [registro.tarefa.id],
    );
    for (final sub in registro.tarefa.subtarefas) {
      await txn.insert('subtarefas', {
        'id': sub.id,
        'tarefa_id': registro.tarefa.id,
        'dados': jsonEncode(sub.toMap()),
      });
    }
  });
  @override
  Future<bool> confirmar(
    RegistroLocal enviado,
    int? remotoId,
  ) => db.transaction((txn) async {
    // Compare-and-set: uma resposta antiga nunca confirma uma edição mais nova.
    final where = 'id = ? AND revisao = ?';
    final args = [enviado.tarefa.id, enviado.revisao];
    if (enviado.excluido) {
      return await txn.delete('tarefas', where: where, whereArgs: args) > 0;
    }
    if (remotoId != null) {
      // Mesmo que outra revisão exista, preserve o ID criado no servidor.
      // Assim um DELETE feito durante um POST ainda sabe o que remover.
      await txn.update(
        'tarefas',
        {'remoto_id': remotoId},
        where: 'id = ? AND remoto_id IS NULL',
        whereArgs: [enviado.tarefa.id],
      );
    }
    return await txn.update(
          'tarefas',
          {'sincronizado': 1, 'remoto_id': remotoId},
          where: where,
          whereArgs: args,
        ) >
        0;
  });
  @override
  Future<void> log(LogSync log) async {
    await db.insert('sync_logs', log.toMap());
  }

  @override
  Future<List<LogSync>> logs() async => (await db.query(
    'sync_logs',
    orderBy: 'id DESC',
    limit: 100,
  )).map(LogSync.fromMap).toList();
}

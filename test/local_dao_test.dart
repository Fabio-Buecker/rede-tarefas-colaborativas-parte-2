import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rede_tarefas_colaborativas/datasources/local_dao.dart';
import 'package:rede_tarefas_colaborativas/models/registro_local.dart';
import 'package:rede_tarefas_colaborativas/models/subtarefa.dart';
import 'test_support.dart';

void main() {
  sqfliteFfiInit();
  late LocalDao dao;
  setUp(() async {
    dao = await LocalDao.abrir(
      factory: databaseFactoryFfi,
      caminho: inMemoryDatabasePath,
    );
  });
  tearDown(() async {
    await dao.db.close();
  });
  group('SQLite real em memória', () {
    test('cria quadro inicial', () async {
      expect((await dao.quadros()).single.id, 'geral');
    });
    test('insere e consulta tarefa', () async {
      await dao.salvar(exemplo());
      expect((await dao.listar()).single.tarefa.titulo, 'Preparar entrega');
    });
    test('atualiza sem duplicar', () async {
      await dao.salvar(exemplo());
      await dao.salvar(exemplo().copyWith(revisao: 2));
      expect((await dao.listar()).single.revisao, 2);
    });
    test('persiste subtarefa relacionada atomicamente', () async {
      final r = exemplo();
      r.tarefa.adicionarSubtarefa(
        Subtarefa(id: 's1', titulo: 'Revisar código', responsavelId: 'Ana'),
      );
      await dao.salvar(r);
      expect((await dao.db.query('subtarefas')).length, 1);
      expect(
        (await dao.listar()).single.tarefa.subtarefas.single.titulo,
        'Revisar código',
      );
    });
    test('não aceita quadro inexistente', () async {
      await expectLater(
        dao.salvar(exemplo().copyWith(quadroId: 'inexistente')),
        throwsA(isA<DatabaseException>()),
      );
      expect(await dao.listar(), isEmpty);
    });
    test('exclusão confirmada limpa filhos por FK', () async {
      final r = exemplo(remote: 1);
      r.tarefa.adicionarSubtarefa(
        Subtarefa(id: 's1', titulo: 'Revisar código', responsavelId: 'Ana'),
      );
      await dao.salvar(r.copyWith(excluido: true));
      await dao.confirmar(r.copyWith(excluido: true), 1);
      expect(await dao.db.query('subtarefas'), isEmpty);
      expect(await dao.listar(incluirExcluidos: true), isEmpty);
    });
    test('quadro com tarefa não é excluído', () async {
      await dao.salvar(exemplo());
      await expectLater(dao.excluirQuadro('geral'), throwsStateError);
      expect(await dao.quadros(), hasLength(1));
    });
    test('CRUD de quadros', () async {
      await dao.salvarQuadro(Quadro(id: 'q', nome: 'Planejamento'));
      await dao.salvarQuadro(Quadro(id: 'q', nome: 'Entregas'));
      expect((await dao.quadros()).any((q) => q.nome == 'Entregas'), true);
      await dao.excluirQuadro('q');
      expect(await dao.quadros(), hasLength(1));
    });
    test('compare-and-set não confirma revisão nova', () async {
      final r = exemplo();
      await dao.salvar(r.copyWith(revisao: 2));
      expect(await dao.confirmar(r, 10), false);
      final atual = (await dao.listar()).single;
      expect(atual.sincronizado, false);
      expect(atual.remotoId, 10);
    });
    test('tombstone fica fora de consultas normais', () async {
      await dao.salvar(exemplo().copyWith(excluido: true));
      expect(await dao.listar(), isEmpty);
      expect(await dao.listar(incluirExcluidos: true), hasLength(1));
    });
    test('armazena log de tentativa', () async {
      await dao.log(const LogSync('agora', 'falha de rede', false));
      expect((await dao.logs()).single.mensagem, 'falha de rede');
    });
  });
}

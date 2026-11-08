import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rede_tarefas_colaborativas/datasources/api_service.dart';
import 'package:rede_tarefas_colaborativas/models/registro_local.dart';
import 'package:rede_tarefas_colaborativas/repositories/offline_repository.dart';
import 'test_support.dart';

void main() {
  late FakeLocal local;
  OfflineRepository repo(
    Future<http.Response> Function(http.Request) handler,
  ) => OfflineRepository(
    local,
    ApiService(MockClient(handler), timeout: const Duration(milliseconds: 15)),
  );
  setUp(() {
    local = FakeLocal();
  });
  group('Serialização SQLite e JSON', () {
    test('Registro realiza roundtrip completo', () {
      final r = exemplo();
      final copy = RegistroLocal.fromMap(r.toMap());
      expect(copy.tarefa.toMap(), r.tarefa.toMap());
    });
    test(
      'booleano pendente é inteiro zero',
      () => expect(exemplo().toMap()['sincronizado'], 0),
    );
    test(
      'booleano sincronizado é inteiro um',
      () => expect(exemplo(synced: true).toMap()['sincronizado'], 1),
    );
    test('JSON inclui título e identificador local', () {
      final m = jsonDecode(exemplo().toJson()) as Map<String, dynamic>;
      expect(m['title'], 'Preparar entrega');
      expect(m['localId'], 't1');
    });
    test('copyWith preserva tarefa e remoto', () {
      final r = exemplo(remote: 7).copyWith(excluido: true);
      expect(r.excluido, true);
      expect(r.remotoId, 7);
    });
    test(
      'quadro valida nome curto',
      () => expect(() => Quadro(id: '1', nome: 'ab'), throwsArgumentError),
    );
    test('quadro realiza roundtrip', () {
      final q = Quadro(id: '1', nome: 'Equipe');
      expect(Quadro.fromMap(q.toMap()).nome, 'Equipe');
    });
    test('log realiza roundtrip', () {
      const l = LogSync('agora', 'falha', false);
      expect(LogSync.fromMap(l.toMap()).sucesso, false);
    });
  });
  group('Repository offline-first', () {
    test('salva local sem fazer HTTP', () async {
      var chamadas = 0;
      final r = repo((_) async {
        chamadas++;
        return http.Response('', 500);
      });
      await r.salvar(exemplo(synced: true));
      expect(chamadas, 0);
      expect((await r.listar()).single.sincronizado, false);
    });
    test('incrementa revisão em edições', () async {
      final r = repo((_) async => http.Response('', 500));
      await r.salvar(exemplo());
      await r.salvar(exemplo());
      expect(local.items['t1']?.revisao, 2);
    });
    test('HTTP 500 mantém dados pendentes', () async {
      final r = repo((_) async => http.Response('', 500));
      await r.salvar(exemplo());
      expect((await r.sincronizar()).falhas, 1);
      expect((await r.listar()).single.sincronizado, false);
    });
    test('socket offline mantém dados', () async {
      final r = repo((_) async => throw const SocketException('offline'));
      await r.salvar(exemplo());
      await r.sincronizar();
      expect(local.items.length, 1);
      expect(local.items['t1']?.sincronizado, false);
    });
    test('ClientException mantém dados', () async {
      final r = repo((_) async => throw http.ClientException('offline'));
      await r.salvar(exemplo());
      expect((await r.sincronizar()).falhas, 1);
    });
    test('timeout mantém pendência', () async {
      final r = repo((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        return http.Response('{"id":2}', 201);
      });
      await r.salvar(exemplo());
      expect((await r.sincronizar()).falhas, 1);
    });
    test('201 confirma sincronização e id remoto', () async {
      final r = repo((_) async => http.Response('{"id":7}', 201));
      await r.salvar(exemplo());
      expect((await r.sincronizar()).enviados, 1);
      expect(local.items['t1']?.remotoId, 7);
      expect(local.items['t1']?.sincronizado, true);
    });
    test('edição remota usa PUT', () async {
      String? method;
      final r = repo((q) async {
        method = q.method;
        return http.Response('{"id":7}', 200);
      });
      await local.salvar(exemplo(remote: 7));
      await r.sincronizar();
      expect(method, 'PUT');
    });
    test('criação remota usa POST e JSON', () async {
      final r = repo((q) async {
        expect(q.method, 'POST');
        expect(jsonDecode(q.body)['localId'], 't1');
        return http.Response('{"id":7}', 201);
      });
      await r.salvar(exemplo());
      await r.sincronizar();
    });
    test('JSON inválido mantém pendência', () async {
      final r = repo((_) async => http.Response('invalido', 200));
      await r.salvar(exemplo());
      expect((await r.sincronizar()).falhas, 1);
    });
    test('resposta sem ID mantém pendência', () async {
      final r = repo((_) async => http.Response('{}', 201));
      await r.salvar(exemplo());
      expect((await r.sincronizar()).falhas, 1);
    });
    test('exclusão esconde local e preserva tombstone', () async {
      final r = repo((_) async => http.Response('', 500));
      await r.salvar(exemplo());
      await r.excluir(exemplo());
      expect(await r.listar(), isEmpty);
      expect(local.items['t1']?.excluido, true);
    });
    test('DELETE remoto confirmado remove tombstone', () async {
      String? method;
      final r = repo((q) async {
        method = q.method;
        return http.Response('{}', 200);
      });
      await local.salvar(exemplo(remote: 7));
      await r.excluir(exemplo(remote: 7));
      await r.sincronizar();
      expect(method, 'DELETE');
      expect(local.items, isEmpty);
    });
    test('DELETE falho conserva tombstone para retry', () async {
      final r = repo((_) async => http.Response('', 503));
      await local.salvar(exemplo(remote: 7));
      await r.excluir(exemplo(remote: 7));
      await r.sincronizar();
      expect(local.items['t1']?.excluido, true);
    });
    test('exclusão ainda não enviada dispensa HTTP', () async {
      var n = 0;
      final r = repo((_) async {
        n++;
        return http.Response('', 500);
      });
      await r.salvar(exemplo());
      await r.excluir(exemplo());
      await r.sincronizar();
      expect(n, 0);
      expect(local.items, isEmpty);
    });
    test('retry após falha confirma o mesmo item', () async {
      var n = 0;
      final r = repo(
        (_) async =>
            ++n == 1 ? http.Response('', 500) : http.Response('{"id":8}', 201),
      );
      await r.salvar(exemplo());
      await r.sincronizar();
      await r.sincronizar();
      expect(local.items.length, 1);
      expect(local.items['t1']?.sincronizado, true);
    });
    test('leitura usa somente fonte local', () async {
      final r = repo((_) async => throw StateError('HTTP proibido'));
      await local.salvar(exemplo());
      expect((await r.listar()).length, 1);
    });
    test('erro de disco não vira sucesso de rede', () async {
      local.falhar = true;
      final r = repo((_) async => http.Response('{"id":1}', 201));
      await expectLater(r.salvar(exemplo()), throwsStateError);
    });
    test('resposta antiga não confirma revisão nova', () async {
      final answer = Completer<http.Response>();
      final called = Completer<void>();
      final r = repo((_) {
        called.complete();
        return answer.future;
      });
      await r.salvar(exemplo());
      final sync = r.sincronizar();
      await called.future;
      await r.salvar(exemplo());
      answer.complete(http.Response('{"id":4}', 201));
      await sync;
      expect(local.items['t1']?.sincronizado, false);
      expect(local.items['t1']?.revisao, 2);
    });
    test('sincronizações concorrentes compartilham envio', () async {
      var n = 0;
      final r = repo((_) async {
        n++;
        return http.Response('{"id":9}', 201);
      });
      await r.salvar(exemplo());
      await Future.wait([r.sincronizar(), r.sincronizar()]);
      expect(n, 1);
    });
    test('GET importado é persistido e não duplica', () async {
      final r = repo((q) async {
        expect(q.method, 'GET');
        return http.Response(
          '[{"id":1,"title":"Modelo remoto","completed":false}]',
          200,
        );
      });
      expect(await r.importarCatalogo('geral'), 1);
      expect(await r.importarCatalogo('geral'), 0);
      expect((await r.listar()).single.sincronizado, true);
    });
    test('GET falho preserva registros anteriores', () async {
      final r = repo((_) async => http.Response('', 500));
      await r.salvar(exemplo());
      await expectLater(
        r.importarCatalogo('geral'),
        throwsA(isA<RedeException>()),
      );
      expect(local.items.length, 1);
    });
    test('GET inválido produz exceção de rede', () async {
      final r = repo((_) async => http.Response('{}', 200));
      await expectLater(
        r.importarCatalogo('geral'),
        throwsA(isA<RedeException>()),
      );
    });
  });
}

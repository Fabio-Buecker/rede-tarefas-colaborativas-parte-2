import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';
import 'package:test/test.dart';

void main() {
  group('Membro', () {
    test('cria membro com construtor gerativo e getter seguro', () {
      final Membro membro = Membro(id: 'm1', nome: 'Fabio Buecker');

      expect(membro.nome, 'Fabio Buecker');
      expect(membro.contatoPreferencial, 'E-mail nao informado');
    });

    test('cria membro por factory fromMap', () {
      final Membro membro = Membro.fromMap(<String, dynamic>{
        'id': 'm2',
        'nome': 'Andre Rezende',
        'email': 'andre@grupo.edu.br',
      });

      expect(membro.email, 'andre@grupo.edu.br');
    });

    test('setter rejeita nome invalido', () {
      final Membro membro = Membro(id: 'm3', nome: 'Juliano');

      expect(
        () => membro.nome = 'A',
        throwsA(isA<ValidacaoException>()),
      );
    });
  });
}


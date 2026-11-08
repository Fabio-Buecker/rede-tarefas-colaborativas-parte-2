// Importa a API pública que será verificada.
import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';
// Disponibiliza `group`, `test`, `expect`, matchers e utilitários de teste.
import 'package:flutter_test/flutter_test.dart';

/// Executa a suíte de testes unitários do modelo [Membro].
void main() {
  // `group` organiza casos relacionados sob o mesmo título no resultado.
  group('Membro', () {
    test('cria membro com construtor gerativo e getter seguro', () {
      // Arrange: cria o objeto sem e-mail para exercitar o valor alternativo.
      final Membro membro = Membro(id: 'm1', nome: 'Fabio Buecker');

      // Assert: `expect` compara o valor real com o resultado esperado.
      expect(membro.nome, 'Fabio Buecker');
      expect(membro.contatoPreferencial, 'E-mail nao informado');
    });

    test('cria membro por factory fromMap', () {
      // Act: converte um mapa que representa dados vindos de fonte externa.
      final Membro membro = Membro.fromMap(<String, dynamic>{
        'id': 'm2',
        'nome': 'Andre Rezende',
        'email': 'andre@grupo.edu.br',
      });

      expect(membro.email, 'andre@grupo.edu.br');
    });

    test('setter rejeita nome invalido', () {
      final Membro membro = Membro(id: 'm3', nome: 'Juliano');

      // Uma função anônima adia a atribuição para o matcher capturar a exceção.
      expect(() => membro.nome = 'A', throwsA(isA<ValidacaoException>()));
    });
  });
}

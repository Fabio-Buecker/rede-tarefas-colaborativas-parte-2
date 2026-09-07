// API pública do domínio e biblioteca de testes.
import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';
import 'package:test/test.dart';

/// Exercita os casos de uso coordenados por [GerenciadorRedeTarefas].
void main() {
  group('GerenciadorRedeTarefas', () {
    // A referência será recriada no `setUp` executado antes de cada teste.
    late GerenciadorRedeTarefas gerenciador;

    setUp(() {
      // Cascades cadastram os dois membros no mesmo gerenciador recém-criado.
      gerenciador = GerenciadorRedeTarefas(TarefaRepositoryMemoria())
        ..cadastrarMembro(Membro(id: 'm1', nome: 'Fabio Buecker'))
        ..cadastrarMembro(Membro(id: 'm2', nome: 'Andre Rezende'));

      // Esta tarefa inicial é o cenário comum usado pelas três verificações.
      gerenciador.criarTarefa(
        TarefaColaborativa(
          id: 't1',
          titulo: 'Implementar dominio',
          criadorId: 'm1',
          membrosIds: <String>{'m2'},
          etiquetas: <String>{'dart'},
        ),
      );
    });

    test('filtra, transforma e calcula metricas funcionais', () {
      // Arrange/Act: consulta o mesmo estado por três representações diferentes.
      final List<TarefaColaborativa> pendentes =
          gerenciador.filtrarPorStatus(StatusTarefa.pendente);
      final List<Map<String, Object>> resumos =
          gerenciador.transformarEmResumos();
      final Map<String, Object> metricas = gerenciador.calcularMetricas();

      // Assert: valida quantidade, transformação e agregação.
      expect(pendentes, hasLength(1));
      expect(resumos.single['titulo'], 'Implementar dominio');
      expect(metricas['total'], 1);
      expect(metricas['etiquetas'], contains('dart'));
    });

    test('simula queda e recuperacao da conectividade', () {
      gerenciador.alterarConectividade(online: false);

      // Passar o método sem parênteses permite que o matcher execute e capture.
      expect(
        gerenciador.sincronizar,
        throwsA(isA<ConectividadeException>()),
      );

      // A conexão restaurada faz a tentativa seguinte completar normalmente.
      gerenciador
        ..alterarConectividade(online: true)
        ..sincronizar();

      expect(gerenciador.ultimaSincronizacao, isNotNull);
      expect(gerenciador.mensagemSincronizacao, contains('Primeira'));
    });

    test('dispara excecao customizada para membro inexistente', () {
      // A função anônima mantém a chamada dentro do controle do matcher.
      expect(
        () => gerenciador.adicionarMembroNaTarefa('t1', 'm99'),
        throwsA(isA<EntidadeNaoEncontradaException>()),
      );
    });
  });
}

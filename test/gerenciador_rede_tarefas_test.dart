import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';
import 'package:test/test.dart';

void main() {
  group('GerenciadorRedeTarefas', () {
    late GerenciadorRedeTarefas gerenciador;

    setUp(() {
      gerenciador = GerenciadorRedeTarefas(TarefaRepositoryMemoria())
        ..cadastrarMembro(Membro(id: 'm1', nome: 'Fabio Buecker'))
        ..cadastrarMembro(Membro(id: 'm2', nome: 'Andre Rezende'));

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
      final List<TarefaColaborativa> pendentes =
          gerenciador.filtrarPorStatus(StatusTarefa.pendente);
      final List<Map<String, Object>> resumos =
          gerenciador.transformarEmResumos();
      final Map<String, Object> metricas = gerenciador.calcularMetricas();

      expect(pendentes, hasLength(1));
      expect(resumos.single['titulo'], 'Implementar dominio');
      expect(metricas['total'], 1);
      expect(metricas['etiquetas'], contains('dart'));
    });

    test('simula queda e recuperacao da conectividade', () {
      gerenciador.alterarConectividade(online: false);

      expect(
        gerenciador.sincronizar,
        throwsA(isA<ConectividadeException>()),
      );

      gerenciador
        ..alterarConectividade(online: true)
        ..sincronizar();

      expect(gerenciador.ultimaSincronizacao, isNotNull);
      expect(gerenciador.mensagemSincronizacao, contains('Primeira'));
    });

    test('dispara excecao customizada para membro inexistente', () {
      expect(
        () => gerenciador.adicionarMembroNaTarefa('t1', 'm99'),
        throwsA(isA<EntidadeNaoEncontradaException>()),
      );
    });
  });
}


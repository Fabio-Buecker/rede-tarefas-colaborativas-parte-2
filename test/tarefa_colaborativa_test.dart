// API pública do projeto e framework de testes.
import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica as regras de composição e colaboração de [TarefaColaborativa].
void main() {
  group('TarefaColaborativa', () {
    // `late` permite inicializar uma nova tarefa no `setUp` antes de cada teste.
    late TarefaColaborativa tarefa;

    // Evita compartilhamento de estado: cada caso começa com um objeto limpo.
    setUp(() {
      tarefa = TarefaColaborativa(
        id: 't1',
        titulo: 'Construir projeto',
        criadorId: 'm1',
        membrosIds: <String>{'m2'},
      );
    });

    test('usa heranca, composicao e recalcula o progresso com fold', () {
      // Duas subtarefas com 100% e 0% devem produzir média de 50%.
      tarefa
        ..adicionarSubtarefa(
          Subtarefa(
            id: 's1',
            titulo: 'Criar modelos',
            responsavelId: 'm1',
            progresso: 100,
          ),
        )
        ..adicionarSubtarefa(
          Subtarefa(id: 's2', titulo: 'Criar servicos', responsavelId: 'm2'),
        );

      // O setter de progresso também muda automaticamente o status.
      expect(tarefa.progresso, 50);
      expect(tarefa.status, StatusTarefa.emAndamento);
    });

    test('delega subtarefa para membro participante', () {
      tarefa.adicionarSubtarefa(
        Subtarefa.rapida(
          id: 's1',
          titulo: 'Revisar codigo',
          responsavelId: 'm1',
        ),
      );

      // Act: troca o responsável de m1 para m2.
      tarefa.delegarSubtarefa('s1', 'm2');

      // `single` exige e retorna o único elemento da lista.
      expect(tarefa.subtarefas.single.responsavelId, 'm2');
      expect(tarefa.historicoAuditoria, isNotEmpty);
    });

    test('impede responsavel que nao pertence a tarefa', () {
      final Subtarefa subtarefa = Subtarefa(
        id: 's1',
        titulo: 'Tarefa invalida',
        responsavelId: 'm9',
      );

      // A subtarefa aponta para m9, que não faz parte da tarefa preparada.
      expect(
        () => tarefa.adicionarSubtarefa(subtarefa),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('factory interpreta mapa sem operador de assercao nula', () {
      // Não usar `!` mantém a leitura segura mesmo com campos opcionais.
      final TarefaColaborativa importada = TarefaColaborativa.fromMap(
        <String, dynamic>{
          'id': 't2',
          'titulo': 'Importada do cache',
          'criadorId': 'm1',
          'membrosIds': <String>['m1', 'm2'],
          'prioridade': 'alta',
        },
      );

      expect(importada.prioridade, PrioridadeTarefa.alta);
      // `containsAll` verifica a presença de todos os ids, sem depender da ordem.
      expect(importada.membrosIds, containsAll(<String>['m1', 'm2']));
    });
  });
}

import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';
import 'package:test/test.dart';

void main() {
  group('TarefaColaborativa', () {
    late TarefaColaborativa tarefa;

    setUp(() {
      tarefa = TarefaColaborativa(
        id: 't1',
        titulo: 'Construir projeto',
        criadorId: 'm1',
        membrosIds: <String>{'m2'},
      );
    });

    test('usa heranca, composicao e recalcula o progresso com fold', () {
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
          Subtarefa(
            id: 's2',
            titulo: 'Criar servicos',
            responsavelId: 'm2',
          ),
        );

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

      tarefa.delegarSubtarefa('s1', 'm2');

      expect(tarefa.subtarefas.single.responsavelId, 'm2');
      expect(tarefa.historicoAuditoria, isNotEmpty);
    });

    test('impede responsavel que nao pertence a tarefa', () {
      final Subtarefa subtarefa = Subtarefa(
        id: 's1',
        titulo: 'Tarefa invalida',
        responsavelId: 'm9',
      );

      expect(
        () => tarefa.adicionarSubtarefa(subtarefa),
        throwsA(isA<ValidacaoException>()),
      );
    });

    test('factory interpreta mapa sem operador de assercao nula', () {
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
      expect(importada.membrosIds, containsAll(<String>['m1', 'm2']));
    });
  });
}


import '../core/enums.dart';
import '../models/membro.dart';
import '../models/tarefa_colaborativa.dart';
import 'gerenciador_rede_tarefas.dart';

class RelatorioService {
  const RelatorioService();

  String gerar(GerenciadorRedeTarefas gerenciador) {
    final List<TarefaColaborativa> tarefas = gerenciador.listarTarefas();
    final Map<String, Object> metricas = gerenciador.calcularMetricas();
    final StringBuffer relatorio = StringBuffer()
      ..writeln('============================================================')
      ..writeln('      REDE DE TAREFAS COLABORATIVAS - RELATORIO FINAL')
      ..writeln('============================================================')
      ..writeln('Membros cadastrados: ${gerenciador.membros.length}')
      ..writeln('Tarefas cadastradas: ${metricas['total']}')
      ..writeln(
        'Progresso medio: '
        '${(metricas['mediaProgresso'] as double).toStringAsFixed(1)}%',
      )
      ..writeln('Conectividade: ${gerenciador.online ? 'ONLINE' : 'OFFLINE'}')
      ..writeln();

    relatorio.writeln('MEMBROS');
    for (final Membro membro in gerenciador.membros) {
      relatorio.writeln('- ${membro.nome} (${membro.contatoPreferencial})');
    }

    relatorio
      ..writeln()
      ..writeln('QUADRO DE TAREFAS');
    for (final StatusTarefa status in StatusTarefa.values) {
      final List<TarefaColaborativa> tarefasDoStatus = tarefas
          .where((tarefa) => tarefa.status == status)
          .toList(growable: false);
      relatorio.writeln('\n${status.rotulo.toUpperCase()} (${tarefasDoStatus.length})');
      for (final TarefaColaborativa tarefa in tarefasDoStatus) {
        relatorio.writeln(
          '- ${tarefa.titulo} | ${tarefa.progresso.toStringAsFixed(0)}% | '
          '${tarefa.membrosIds.length} participante(s)',
        );
      }
    }

    return relatorio.toString();
  }
}


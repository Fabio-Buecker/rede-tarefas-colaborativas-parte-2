import '../core/enums.dart';
import '../models/membro.dart';
import '../models/tarefa_colaborativa.dart';
import 'gerenciador_rede_tarefas.dart';

/// Gera uma apresentação textual do estado atual da rede de tarefas.
///
/// A classe não guarda estado; por isso pode possuir construtor `const` e ser
/// reutilizada sem custo entre várias gerações de relatório.
class RelatorioService {
  /// Cria uma instância constante do serviço.
  const RelatorioService();

  /// Percorre membros, métricas, status e tarefas para compor o relatório.
  String gerar(GerenciadorRedeTarefas gerenciador) {
    final List<TarefaColaborativa> tarefas = gerenciador.listarTarefas();
    final Map<String, Object> metricas = gerenciador.calcularMetricas();
    // `StringBuffer` é mais eficiente que concatenar muitas strings. O operador
    // `..` (cascade) chama vários métodos no mesmo objeto e devolve esse objeto.
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
    // Cada `writeln` acrescenta o texto seguido de uma quebra de linha.
    for (final Membro membro in gerenciador.membros) {
      relatorio.writeln('- ${membro.nome} (${membro.contatoPreferencial})');
    }

    relatorio
      ..writeln()
      ..writeln('QUADRO DE TAREFAS');
    for (final StatusTarefa status in StatusTarefa.values) {
      // O filtro cria o grupo correspondente ao status da iteração atual.
      final List<TarefaColaborativa> tarefasDoStatus = tarefas
          .where((tarefa) => tarefa.status == status)
          .toList(growable: false);
      relatorio.writeln(
        '\n${status.rotulo.toUpperCase()} (${tarefasDoStatus.length})',
      );
      for (final TarefaColaborativa tarefa in tarefasDoStatus) {
        relatorio.writeln(
          '- ${tarefa.titulo} | ${tarefa.progresso.toStringAsFixed(0)}% | '
          '${tarefa.membrosIds.length} participante(s)',
        );
      }
    }

    // Converte todo o conteúdo acumulado no texto final.
    return relatorio.toString();
  }
}

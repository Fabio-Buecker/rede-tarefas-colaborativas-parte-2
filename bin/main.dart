import 'dart:io';

import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';

void main() {
  final TarefaRepository repository = TarefaRepositoryMemoria();
  final GerenciadorRedeTarefas gerenciador =
      GerenciadorRedeTarefas(repository);
  const RelatorioService relatorioService = RelatorioService();

  stdout.writeln('=== DEMONSTRACAO: REDE DE TAREFAS COLABORATIVAS ===\n');

  _cadastrarMembros(gerenciador);
  _criarTarefas(gerenciador);
  _executarFluxos(gerenciador);
  _simularRestricaoMovel(gerenciador);

  stdout.writeln();
  stdout.writeln(relatorioService.gerar(gerenciador));

  final List<Map<String, Object>> resumos =
      gerenciador.transformarEmResumos();
  stdout.writeln('TRANSFORMACAO FUNCIONAL (.map)');
  for (final Map<String, Object> resumo in resumos) {
    stdout.writeln(resumo);
  }

  final String nomeSeguro =
      gerenciador.buscarMembro('membro-inexistente')?.nome ?? 'Nao encontrado';
  stdout.writeln('\nAcesso seguro (?. e ??): $nomeSeguro');
  stdout.writeln(
    'Ultimo log seguro: '
    '${gerenciador.ultimoRegistroAuditoria?.toUpperCase() ?? 'SEM LOG'}',
  );
}

void _cadastrarMembros(GerenciadorRedeTarefas gerenciador) {
  final List<Membro> membros = <Membro>[
    Membro(
      id: 'm1',
      nome: 'Andre Rezende',
      email: 'andre@grupo03.edu.br',
    ),
    Membro(
      id: 'm2',
      nome: 'Fabio Buecker',
      email: 'fabio@grupo03.edu.br',
    ),
    Membro.convidado(id: 'm3', nome: 'Juliano'),
    Membro.fromMap(<String, dynamic>{
      'id': 'm4',
      'nome': 'Davi Checon',
      'email': 'davi@grupo03.edu.br',
    }),
    Membro(
      id: 'm5',
      nome: 'Raphael Picoli',
      email: 'raphael@grupo03.edu.br',
    ),
  ];

  membros.forEach(gerenciador.cadastrarMembro);
  stdout.writeln('[OK] ${membros.length} membros cadastrados.');
}

void _criarTarefas(GerenciadorRedeTarefas gerenciador) {
  final TarefaColaborativa entrega = TarefaColaborativa(
    id: 't1',
    titulo: 'Preparar entrega da AP1B',
    descricao: 'Organizar codigo, documentacao e demonstracao.',
    criadorId: 'm2',
    membrosIds: <String>{'m1', 'm3', 'm4', 'm5'},
    prioridade: PrioridadeTarefa.urgente,
    prazo: DateTime(2026, 9, 10),
    etiquetas: <String>{'faculdade', 'dart', 'ap1b'},
  );

  final TarefaColaborativa estudo = TarefaColaborativa.planejamento(
    id: 't2',
    titulo: 'Revisar conceitos para a arguicao',
    criadorId: 'm1',
  );

  final TarefaColaborativa documentacao = TarefaColaborativa.fromMap(
    <String, dynamic>{
      'id': 't3',
      'titulo': 'Revisar README e referencias',
      'criadorId': 'm4',
      'membrosIds': <String>['m4', 'm5'],
      'prioridade': 'alta',
      'etiquetas': <String>['documentacao'],
    },
  );

  gerenciador
    ..criarTarefa(entrega)
    ..criarTarefa(estudo)
    ..criarTarefa(documentacao);

  stdout.writeln('[OK] 3 tarefas criadas com construtores variados.');
}

void _executarFluxos(GerenciadorRedeTarefas gerenciador) {
  gerenciador
    ..adicionarSubtarefa(
      't1',
      Subtarefa(
        id: 's1',
        titulo: 'Implementar modelos de dominio',
        responsavelId: 'm2',
        prioridade: PrioridadeTarefa.alta,
      ),
    )
    ..adicionarSubtarefa(
      't1',
      Subtarefa.rapida(
        id: 's2',
        titulo: 'Conferir o README',
        responsavelId: 'm4',
      ),
    )
    ..adicionarSubtarefa(
      't1',
      Subtarefa.fromMap(<String, dynamic>{
        'id': 's3',
        'titulo': 'Ensaiar demonstracao da CLI',
        'responsavelId': 'm1',
        'prioridade': 'media',
      }),
    );

  gerenciador
    ..concluirSubtarefa('t1', 's1')
    ..delegarSubtarefa('t1', 's2', 'm5');

  final List<TarefaColaborativa> emAndamento =
      gerenciador.filtrarPorStatus(StatusTarefa.emAndamento);
  final List<TarefaColaborativa> deFabio = gerenciador.tarefasDoMembro('m2');

  stdout.writeln('[OK] Subtarefas inseridas, concluidas e delegadas.');
  stdout.writeln('[FILTRO] Em andamento: ${emAndamento.length}.');
  stdout.writeln('[FILTRO] Tarefas de Fabio: ${deFabio.length}.');

  try {
    gerenciador.delegarSubtarefa('t1', 's3', 'membro-inexistente');
  } on EntidadeNaoEncontradaException catch (erro) {
    stdout.writeln('[EXCECAO TRATADA] $erro');
  } finally {
    stdout.writeln('[FINALMENTE] Fluxo de delegacao invalida encerrado.');
  }
}

void _simularRestricaoMovel(GerenciadorRedeTarefas gerenciador) {
  gerenciador.alterarConectividade(online: false);
  try {
    gerenciador.sincronizar();
  } on ConectividadeException catch (erro) {
    stdout.writeln('[OFFLINE-FIRST] $erro');
  } finally {
    stdout.writeln('[FINALMENTE] Tentativa offline registrada em auditoria.');
  }

  gerenciador
    ..alterarConectividade(online: true)
    ..sincronizar();

  stdout.writeln('[OK] Conectividade restaurada e dados sincronizados.');
}


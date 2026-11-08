// Biblioteca padrão que fornece `stdout` para escrever no terminal.
import 'dart:io';

// Ponto público do pacote; reúne modelos, repositórios e serviços.
import 'package:rede_tarefas_colaborativas/rede_tarefas_colaborativas.dart';

/// Ponto de entrada da demonstração executada por `dart run`.
///
/// A função monta as dependências, executa os principais casos de uso e exibe
/// os resultados. Ela é intencionalmente sequencial para funcionar como roteiro
/// de apresentação dos recursos de orientação a objetos e da linguagem Dart.
void main() {
  // A variável usa o tipo da interface, mas recebe a implementação em memória.
  // Isso demonstra polimorfismo e mantém o serviço desacoplado da persistência.
  final TarefaRepository repository = TarefaRepositoryMemoria();
  final GerenciadorRedeTarefas gerenciador = GerenciadorRedeTarefas(repository);
  // `const` é possível porque o serviço não possui estado interno mutável.
  const RelatorioService relatorioService = RelatorioService();

  stdout.writeln('=== DEMONSTRACAO: REDE DE TAREFAS COLABORATIVAS ===\n');

  // Cada função privada representa uma etapa da simulação.
  _cadastrarMembros(gerenciador);
  _criarTarefas(gerenciador);
  _executarFluxos(gerenciador);
  _simularRestricaoMovel(gerenciador);

  // Gera e escreve o relatório final já com uma linha em branco anterior.
  stdout.writeln();
  stdout.writeln(relatorioService.gerar(gerenciador));

  // O tipo explicita uma lista de mapas cujos valores nunca são nulos.
  final List<Map<String, Object>> resumos = gerenciador.transformarEmResumos();
  stdout.writeln('TRANSFORMACAO FUNCIONAL (.map)');
  for (final Map<String, Object> resumo in resumos) {
    stdout.writeln(resumo);
  }

  // `?.` só lê `nome` se o membro existir e `??` fornece a alternativa.
  final String nomeSeguro =
      gerenciador.buscarMembro('membro-inexistente')?.nome ?? 'Nao encontrado';
  stdout.writeln('\nAcesso seguro (?. e ??): $nomeSeguro');
  stdout.writeln(
    'Ultimo log seguro: '
    '${gerenciador.ultimoRegistroAuditoria?.toUpperCase() ?? 'SEM LOG'}',
  );
}

/// Cria membros pelos diferentes construtores disponíveis e cadastra cada um.
void _cadastrarMembros(GerenciadorRedeTarefas gerenciador) {
  // O literal `<Membro>[...]` fixa o tipo aceito pela lista.
  final List<Membro> membros = <Membro>[
    // Construtor gerativo principal, com e-mail opcional fornecido.
    Membro(id: 'm1', nome: 'Andre Rezende', email: 'andre@grupo03.edu.br'),
    Membro(id: 'm2', nome: 'Fabio Buecker', email: 'fabio@grupo03.edu.br'),
    // Construtor nomeado próprio para um participante sem e-mail.
    Membro.convidado(id: 'm3', nome: 'Juliano'),
    // Factory que converte um mapa, formato comum após decodificar JSON.
    Membro.fromMap(<String, dynamic>{
      'id': 'm4',
      'nome': 'Davi Checon',
      'email': 'davi@grupo03.edu.br',
    }),
    Membro(id: 'm5', nome: 'Raphael Picoli', email: 'raphael@grupo03.edu.br'),
  ];

  // `forEach` recebe a referência do método e o chama para cada membro.
  membros.forEach(gerenciador.cadastrarMembro);
  stdout.writeln('[OK] ${membros.length} membros cadastrados.');
}

/// Cria três tarefas usando as formas de construção oferecidas pelo modelo.
void _criarTarefas(GerenciadorRedeTarefas gerenciador) {
  // Construtor completo com descrição, prazo, prioridade e várias etiquetas.
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

  // Construtor nomeado preenche automaticamente prioridade e etiqueta.
  final TarefaColaborativa estudo = TarefaColaborativa.planejamento(
    id: 't2',
    titulo: 'Revisar conceitos para a arguicao',
    criadorId: 'm1',
  );

  // Factory simula dados recuperados de cache, arquivo ou serviço remoto.
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

  // Cascades (`..`) executam vários métodos sobre o mesmo gerenciador.
  gerenciador
    ..criarTarefa(entrega)
    ..criarTarefa(estudo)
    ..criarTarefa(documentacao);

  stdout.writeln('[OK] 3 tarefas criadas com construtores variados.');
}

/// Demonstra composição, conclusão, delegação, filtros e tratamento de erro.
void _executarFluxos(GerenciadorRedeTarefas gerenciador) {
  // Cada objeto abaixo usa uma forma diferente de construir uma subtarefa.
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

  final List<TarefaColaborativa> emAndamento = gerenciador.filtrarPorStatus(
    StatusTarefa.emAndamento,
  );
  final List<TarefaColaborativa> deFabio = gerenciador.tarefasDoMembro('m2');

  stdout.writeln('[OK] Subtarefas inseridas, concluidas e delegadas.');
  stdout.writeln('[FILTRO] Em andamento: ${emAndamento.length}.');
  stdout.writeln('[FILTRO] Tarefas de Fabio: ${deFabio.length}.');

  // A delegação inválida é proposital: demonstra captura de exceção específica.
  try {
    gerenciador.delegarSubtarefa('t1', 's3', 'membro-inexistente');
  } on EntidadeNaoEncontradaException catch (erro) {
    stdout.writeln('[EXCECAO TRATADA] $erro');
  } finally {
    // `finally` é executado tanto em caso de sucesso quanto de erro.
    stdout.writeln('[FINALMENTE] Fluxo de delegacao invalida encerrado.');
  }
}

/// Simula uma abordagem offline-first comum em aplicações móveis.
void _simularRestricaoMovel(GerenciadorRedeTarefas gerenciador) {
  // A primeira tentativa falha sem descartar as alterações locais.
  gerenciador.alterarConectividade(online: false);
  try {
    gerenciador.sincronizar();
  } on ConectividadeException catch (erro) {
    stdout.writeln('[OFFLINE-FIRST] $erro');
  } finally {
    stdout.writeln('[FINALMENTE] Tentativa offline registrada em auditoria.');
  }

  // Ao restaurar a rede, uma nova tentativa registra a sincronização.
  gerenciador
    ..alterarConectividade(online: true)
    ..sincronizar();

  stdout.writeln('[OK] Conectividade restaurada e dados sincronizados.');
}

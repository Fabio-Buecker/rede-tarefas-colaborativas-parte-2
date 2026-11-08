import 'package:flutter/material.dart';
import '../app.dart';
import '../controllers/app_controller.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  final AppController c;
  const DashboardScreen({super.key, required this.c});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final ativos = c.registros.where((r) => !r.excluido).toList();
      final concluidas = ativos.where((r) => r.tarefa.progresso == 100).length;
      return AppPage(
        title: 'Visão geral',
        c: c,
        floating: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/tarefa/nova'),
          icon: const Icon(Icons.add),
          label: const Text('Nova tarefa'),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Juntos, do plano à entrega.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Organize a equipe. Trabalhe com ou sem internet.'),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final metric in [
                    ('Tarefas', ativos.length),
                    ('Concluídas', concluidas),
                    ('Pendências', c.pendentes),
                    ('Quadros', c.quadros.length),
                  ])
                    SizedBox(
                      width: constraints.maxWidth >= 600
                          ? (constraints.maxWidth - 36) / 4
                          : (constraints.maxWidth - 12) / 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${metric.$2}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge,
                              ),
                              Text(metric.$1),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/quadros'),
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Abrir quadros'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/tarefas'),
                  icon: const Icon(Icons.checklist),
                  label: const Text('Todas as tarefas'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Atividade da equipe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (ativos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Crie a primeira tarefa para começar.'),
              ),
            ...ativos.take(4).map((r) => TaskCard(registro: r)),
            const SizedBox(height: 80),
          ],
        ),
      );
    },
  );
}

class MembersScreen extends StatelessWidget {
  final AppController c;
  const MembersScreen({super.key, required this.c});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final membros =
          c.registros
              .where((r) => !r.excluido)
              .expand((r) => r.tarefa.membrosIds)
              .toSet()
              .toList()
            ..sort();
      return AppPage(
        title: 'Equipe e responsabilidades',
        c: c,
        child: membros.isEmpty
            ? const EmptyState(
                'Adicione participantes no formulário de uma tarefa.',
              )
            : ListView.builder(
                itemCount: membros.length,
                itemBuilder: (context, i) {
                  final nome = membros[i];
                  final tarefas = c.registros
                      .where(
                        (r) =>
                            !r.excluido && r.tarefa.membrosIds.contains(nome),
                      )
                      .toList();
                  return Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(nome),
                      subtitle: Text('${tarefas.length} tarefa(s)'),
                      children: tarefas
                          .map(
                            (r) => ListTile(
                              title: Text(r.tarefa.titulo),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/tarefa',
                                arguments: IdArgs(r.tarefa.id),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
      );
    },
  );
}

class PendingScreen extends StatelessWidget {
  final AppController c;
  const PendingScreen({super.key, required this.c});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final lista = c.registros.where((r) => !r.sincronizado).toList();
      return AppPage(
        title: 'Fila de pendências',
        c: c,
        child: lista.isEmpty
            ? const EmptyState('Nenhuma alteração pendente.')
            : ListView.builder(
                itemCount: lista.length,
                itemBuilder: (_, i) => ListTile(
                  leading: Icon(
                    lista[i].excluido
                        ? Icons.delete_outline
                        : Icons.upload_outlined,
                  ),
                  title: Text(lista[i].tarefa.titulo),
                  subtitle: Text(
                    '${lista[i].excluido ? "Exclusão" : "Criação/edição"} • revisão ${lista[i].revisao}',
                  ),
                  trailing: const SyncBadge(synced: false),
                ),
              ),
      );
    },
  );
}

class SyncScreen extends StatelessWidget {
  final AppController c;
  const SyncScreen({super.key, required this.c});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => AppPage(
      title: 'Sincronização',
      c: c,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${c.pendentes} alteração(ões) aguardando envio',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Última sincronização sem falhas: ${c.ultimaSync ?? "ainda não realizada"}',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: c.sincronizando
                ? null
                : () async {
                    final r = await c.sincronizar();
                    if (context.mounted) {
                      informar(
                        context,
                        r.erro ?? '${r.enviados} alteração(ões) enviada(s).',
                      );
                    }
                  },
            icon: const Icon(Icons.sync),
            label: const Text('Sincronizar agora'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: c.modoOffline || c.sincronizando || c.quadros.isEmpty
                ? null
                : () async {
                    try {
                      final n = await c.repository.importarCatalogo(
                        c.quadros.first.id,
                      );
                      await c.carregar();
                      if (context.mounted) {
                        informar(
                          context,
                          '$n modelos importados no primeiro quadro.',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        informar(
                          context,
                          'Não foi possível importar. Dados locais preservados. $e',
                        );
                      }
                    }
                  },
            icon: const Icon(Icons.download_outlined),
            label: const Text('Importar modelos da API (GET)'),
          ),
          const SizedBox(height: 24),
          Text(
            'Histórico de rede',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (c.historico.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Nenhuma tentativa registrada.'),
            ),
          ...c.historico.map(
            (l) => ListTile(
              leading: Icon(
                l.sucesso ? Icons.check_circle_outline : Icons.error_outline,
              ),
              title: Text(l.mensagem),
              subtitle: Text(l.instante),
            ),
          ),
        ],
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  final AppController c;
  const SettingsScreen({super.key, required this.c});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => AppPage(
      title: 'Configurações',
      c: c,
      child: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo offline'),
            subtitle: const Text(
              'Suspende os envios. Desativar retoma a fila.',
            ),
            value: c.modoOffline,
            onChanged: (v) => c.configurar(offline: v),
          ),
          SwitchListTile(
            title: const Text('Tema escuro'),
            value: c.escuro,
            onChanged: (v) => c.configurar(temaEscuro: v),
          ),
          ListTile(
            title: const Text('API configurada'),
            subtitle: Text('${c.repository.api.endpoint}'),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'O modo offline simula a suspensão de rede. Para comprovar a resiliência real, ative também o modo avião no dispositivo.',
            ),
          ),
        ],
      ),
    ),
  );
}

class AboutScreen extends StatelessWidget {
  final AppController c;
  const AboutScreen({super.key, required this.c});
  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Sobre o TaskLink',
    c: c,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        Icon(Icons.hub_outlined, size: 72),
        SizedBox(height: 16),
        Text('TaskLink 2.0', style: TextStyle(fontSize: 28)),
        Text(
          'Grupo 03 • Tema 07 • Rede de Tarefas Colaborativas\nComputação Móvel • Multivix • AP2B 2026/2',
        ),
        SizedBox(height: 20),
        Text(
          'André Rezende Muruci de Mendonça\nFábio Henrique dos Santos Buecker\nJuliano Jean Pierre\nDavi Checon Bresinski\nRaphael Picoli Zucolotto',
        ),
        SizedBox(height: 20),
        Text(
          'Evolução do núcleo Dart da AP1B. A interface lê o SQLite; a rede envia as pendências sem bloquear o trabalho local.',
        ),
        SizedBox(height: 16),
        Text(
          'Uso de IA: OpenAI Codex/ChatGPT auxiliou na implementação, documentação e testes. A equipe deve estudar e validar o código para a defesa individual.',
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import '../app.dart';
import '../controllers/app_controller.dart';
import '../models/registro_local.dart';
import '../core/enums.dart';

void informar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}

class AppPage extends StatelessWidget {
  final String title;
  final AppController c;
  final Widget child;
  final Widget? floating;
  const AppPage({
    super.key,
    required this.title,
    required this.c,
    required this.child,
    this.floating,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: 'Diagnóstico de sincronização',
          onPressed: () => Navigator.pushNamed(context, '/sincronizacao'),
          icon: Icon(c.modoOffline ? Icons.cloud_off_outlined : Icons.sync),
        ),
      ],
    ),
    drawer: Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.hub_outlined, size: 42),
                  SizedBox(height: 12),
                  Text(
                    'TaskLink',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Text('Seu trabalho continua offline'),
                ],
              ),
            ),
            for (final item in const [
              ('/', 'Visão geral'),
              ('/quadros', 'Quadros'),
              ('/tarefas', 'Tarefas'),
              ('/membros', 'Equipe'),
              ('/pendencias', 'Pendências'),
              ('/sincronizacao', 'Sincronização'),
              ('/configuracoes', 'Configurações'),
              ('/sobre', 'Sobre'),
            ])
              ListTile(
                title: Text(item.$2),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, item.$1);
                },
              ),
          ],
        ),
      ),
    ),
    floatingActionButton: floating,
    body: SafeArea(
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    c.modoOffline ? Icons.cloud_off : Icons.storage,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.modoOffline
                          ? 'Modo offline • alterações salvas neste dispositivo'
                          : 'Dados locais • ${c.pendentes} alteração(ões) pendente(s)',
                    ),
                  ),
                  if (c.sincronizando)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
          if (c.erro != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                c.erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Expanded(
            child: c.carregando
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: child,
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
}

class SyncBadge extends StatelessWidget {
  final bool synced;
  const SyncBadge({super.key, required this.synced});
  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(synced ? Icons.cloud_done_outlined : Icons.schedule, size: 16),
    label: Text(synced ? 'Sincronizado' : 'Pendente'),
  );
}

class TaskCard extends StatelessWidget {
  final RegistroLocal registro;
  const TaskCard({super.key, required this.registro});
  @override
  Widget build(BuildContext context) {
    final t = registro.tarefa;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            Navigator.pushNamed(context, '/tarefa', arguments: IdArgs(t.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.titulo, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SyncBadge(synced: registro.sincronizado),
                  Text('${t.status.rotulo} • ${t.prioridade.rotulo}'),
                  if (t.estaAtrasado) const Text('Prazo vencido'),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: t.progresso / 100),
              const SizedBox(height: 6),
              Text(
                '${t.progresso.toStringAsFixed(0)}% • ${t.subtarefas.length} subtarefas',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String texto;
  const EmptyState(this.texto, {super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 52),
          const SizedBox(height: 16),
          Text(texto, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

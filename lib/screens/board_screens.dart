import 'package:flutter/material.dart';
import '../app.dart';
import '../controllers/app_controller.dart';
import '../models/registro_local.dart';
import '../repositories/offline_repository.dart';
import '../widgets/common.dart';

class BoardsScreen extends StatelessWidget {
  final AppController c;
  const BoardsScreen({super.key, required this.c});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) => AppPage(
      title: 'Quadros da equipe',
      c: c,
      floating: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/quadro/novo'),
        icon: const Icon(Icons.add),
        label: const Text('Novo quadro'),
      ),
      child: c.quadros.isEmpty
          ? const EmptyState('Crie um quadro para organizar as tarefas.')
          : ListView.builder(
              itemCount: c.quadros.length,
              itemBuilder: (_, i) {
                final q = c.quadros[i];
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: const Icon(Icons.dashboard_outlined),
                    title: Text(q.nome),
                    subtitle: Text(
                      '${c.registros.where((r) => r.quadroId == q.id && !r.excluido).length} tarefa(s)',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/quadro',
                      arguments: IdArgs(q.id),
                    ),
                  ),
                );
              },
            ),
    ),
  );
}

class BoardDetailScreen extends StatelessWidget {
  final AppController c;
  final String id;
  const BoardDetailScreen({super.key, required this.c, required this.id});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final quadros = c.quadros.where((q) => q.id == id);
      if (quadros.isEmpty) {
        return AppPage(
          title: 'Quadro',
          c: c,
          child: const EmptyState('Quadro não encontrado.'),
        );
      }
      final tarefas = c.registros
          .where((r) => r.quadroId == id && !r.excluido)
          .toList();
      return AppPage(
        title: quadros.first.nome,
        c: c,
        floating: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(
            context,
            '/tarefa/nova',
            arguments: IdArgs(id),
          ),
          child: const Icon(Icons.add),
        ),
        child: ListView(
          children: [
            Wrap(
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/quadro/editar',
                    arguments: IdArgs(id),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar quadro'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir quadro vazio?'),
                        content: const Text(
                          'Quadros com tarefas ou exclusões pendentes são preservados.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Excluir'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    try {
                      await c.repository.local.excluirQuadro(id);
                      await c.carregar();
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) informar(context, '$e');
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir quadro'),
                ),
              ],
            ),
            if (tarefas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Nenhuma tarefa neste quadro.'),
              ),
            ...tarefas.map((r) => TaskCard(registro: r)),
            const SizedBox(height: 80),
          ],
        ),
      );
    },
  );
}

class BoardFormScreen extends StatefulWidget {
  final AppController c;
  final String? id;
  const BoardFormScreen({super.key, required this.c, this.id});
  @override
  State<BoardFormScreen> createState() => _BoardFormState();
}

class _BoardFormState extends State<BoardFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nome;
  bool _salvando = false;
  @override
  void initState() {
    super.initState();
    final q = widget.c.quadros.where((q) => q.id == widget.id);
    _nome = TextEditingController(text: q.isEmpty ? '' : q.first.nome);
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: widget.id == null ? 'Novo quadro' : 'Editar quadro',
    c: widget.c,
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(labelText: 'Nome do quadro'),
            maxLength: 80,
            validator: (v) => (v ?? '').trim().length < 3
                ? 'Informe pelo menos 3 caracteres.'
                : null,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _salvando
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    setState(() => _salvando = true);
                    try {
                      await widget.c.repository.local.salvarQuadro(
                        Quadro(
                          id: widget.id ?? OfflineRepository.novoId(),
                          nome: _nome.text,
                        ),
                      );
                      await widget.c.carregar();
                      if (context.mounted) {
                        informar(context, 'Quadro salvo neste dispositivo.');
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        informar(context, 'Falha ao salvar: $e');
                      }
                    } finally {
                      if (mounted) setState(() => _salvando = false);
                    }
                  },
            child: const Text('Salvar quadro'),
          ),
        ],
      ),
    ),
  );
}

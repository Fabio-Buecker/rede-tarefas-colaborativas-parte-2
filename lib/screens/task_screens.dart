import 'package:flutter/material.dart';
import '../app.dart';
import '../controllers/app_controller.dart';
import '../core/enums.dart';
import '../models/registro_local.dart';
import '../models/subtarefa.dart';
import '../models/tarefa_colaborativa.dart';
import '../repositories/offline_repository.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  final AppController c;
  const TasksScreen({super.key, required this.c});
  @override
  State<TasksScreen> createState() => _TasksState();
}

class _TasksState extends State<TasksScreen> {
  String busca = '';
  StatusTarefa? status;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.c,
    builder: (context, _) {
      final itens = widget.c.registros
          .where(
            (r) =>
                !r.excluido &&
                r.tarefa.titulo.toLowerCase().contains(busca.toLowerCase()) &&
                (status == null || r.tarefa.status == status),
          )
          .toList();
      return AppPage(
        title: 'Tarefas',
        c: widget.c,
        floating: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/tarefa/nova'),
          child: const Icon(Icons.add),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar tarefa',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => busca = v),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: const Text('Todas'),
                      selected: status == null,
                      onSelected: (_) => setState(() => status = null),
                    ),
                  ),
                  for (final s in StatusTarefa.values)
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: ChoiceChip(
                        label: Text(s.rotulo),
                        selected: status == s,
                        onSelected: (_) => setState(() => status = s),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: itens.isEmpty
                  ? const EmptyState('Nenhuma tarefa encontrada.')
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: itens.length,
                      itemBuilder: (_, i) => TaskCard(registro: itens[i]),
                    ),
            ),
          ],
        ),
      );
    },
  );
}

class TaskDetailScreen extends StatelessWidget {
  final AppController c;
  final String id;
  const TaskDetailScreen({super.key, required this.c, required this.id});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final registro = c.porId(id);
      if (registro == null) {
        return AppPage(
          title: 'Tarefa',
          c: c,
          child: const EmptyState('Tarefa não encontrada.'),
        );
      }
      final t = registro.tarefa;
      return AppPage(
        title: 'Detalhes da tarefa',
        c: c,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(t.titulo, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                SyncBadge(synced: registro.sincronizado),
                Chip(label: Text(t.prioridade.rotulo)),
                Chip(label: Text(t.status.rotulo)),
              ],
            ),
            const SizedBox(height: 16),
            Text(t.descricao ?? 'Sem descrição.'),
            const SizedBox(height: 12),
            Text(
              'Prazo: ${t.prazo?.toIso8601String().split("T").first ?? "não definido"}',
            ),
            Text('Criador: ${t.criadorId}'),
            Text('Participantes: ${t.membrosIds.join(", ")}'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: t.progresso / 100),
            Text('${t.progresso.toStringAsFixed(0)}% concluído'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/tarefa/editar',
                    arguments: IdArgs(id),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/subtarefa/nova',
                    arguments: IdArgs(id),
                  ),
                  icon: const Icon(Icons.add_task),
                  label: const Text('Nova subtarefa'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Excluir tarefa?'),
                        content: const Text(
                          'Ela será removida da lista local e a exclusão ficará na fila de sincronização.',
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
                      await c.excluir(registro);
                      if (context.mounted) {
                        informar(context, 'Exclusão salva localmente.');
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) informar(context, '$e');
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Subtarefas', style: Theme.of(context).textTheme.titleLarge),
            if (t.subtarefas.isEmpty && t.progresso < 100)
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final copia = TarefaColaborativa.fromMap(t.toMap());
                    copia.executarPasso(100);
                    await c.salvar(registro.copyWith(tarefa: copia));
                    if (context.mounted) {
                      informar(context, 'Tarefa concluída e salva localmente.');
                    }
                  } catch (e) {
                    if (context.mounted) informar(context, '$e');
                  }
                },
                icon: const Icon(Icons.done_all),
                label: const Text('Concluir tarefa'),
              ),
            if (t.subtarefas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Divida o trabalho em etapas menores.'),
              ),
            ...t.subtarefas.map(
              (s) => Card(
                child: CheckboxListTile(
                  value: s.progresso == 100,
                  title: Text(s.titulo),
                  subtitle: Text('Responsável: ${s.responsavelId}'),
                  onChanged: s.progresso == 100
                      ? null
                      : (_) async {
                          try {
                            final copia = TarefaColaborativa.fromMap(t.toMap());
                            copia.concluirSubtarefa(s.id);
                            await c.salvar(registro.copyWith(tarefa: copia));
                            if (context.mounted) {
                              informar(
                                context,
                                'Etapa concluída e salva localmente.',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) informar(context, '$e');
                          }
                        },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class TaskFormScreen extends StatefulWidget {
  final AppController c;
  final String? id;
  final String? quadroId;
  const TaskFormScreen({super.key, required this.c, this.id, this.quadroId});
  @override
  State<TaskFormScreen> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController titulo, descricao, criador, membros, prazo;
  RegistroLocal? original;
  String? quadro;
  PrioridadeTarefa prioridade = PrioridadeTarefa.media;
  bool dirty = false, salvando = false;
  @override
  void initState() {
    super.initState();
    original = widget.id == null ? null : widget.c.porId(widget.id!);
    final t = original?.tarefa;
    titulo = TextEditingController(text: t?.titulo);
    descricao = TextEditingController(text: t?.descricao);
    criador = TextEditingController(text: t?.criadorId ?? 'Equipe');
    membros = TextEditingController(text: t?.membrosIds.join(', ') ?? 'Equipe');
    prazo = TextEditingController(
      text: t?.prazo?.toIso8601String().split('T').first,
    );
    quadro =
        original?.quadroId ??
        widget.quadroId ??
        (widget.c.quadros.isEmpty ? null : widget.c.quadros.first.id);
    prioridade = t?.prioridade ?? PrioridadeTarefa.media;
  }

  @override
  void dispose() {
    for (final c in [titulo, descricao, criador, membros, prazo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => salvando = true);
    try {
      final participantes =
          membros.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toSet()
            ..add(criador.text.trim());
      final sub = original?.tarefa.subtarefas ?? <Subtarefa>[];
      if (sub.any((s) => !participantes.contains(s.responsavelId))) {
        throw StateError(
          'Mantenha os responsáveis das subtarefas entre os participantes.',
        );
      }
      final t = TarefaColaborativa(
        id: original?.tarefa.id ?? OfflineRepository.novoId(),
        titulo: titulo.text,
        descricao: descricao.text.trim(),
        criadorId: criador.text.trim(),
        membrosIds: participantes,
        prazo: prazo.text.trim().isEmpty
            ? null
            : DateTime.parse(prazo.text.trim()),
        prioridade: prioridade,
        criadoEm: original?.tarefa.criadoEm,
        progresso: original?.tarefa.progresso ?? 0,
        status: original?.tarefa.status ?? StatusTarefa.pendente,
        subtarefas: sub,
        etiquetas: original?.tarefa.etiquetas,
      );
      await widget.c.salvar(
        RegistroLocal(
          tarefa: t,
          quadroId: quadro!,
          remotoId: original?.remotoId,
        ),
      );
      if (!mounted) return;
      setState(() => dirty = false);
      // PopScope precisa reconstruir antes do pop programático.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          informar(context, 'Tarefa salva neste dispositivo.');
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (mounted) informar(context, 'Não foi possível salvar: $e');
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id != null && original == null) {
      return AppPage(
        title: 'Editar tarefa',
        c: widget.c,
        child: const EmptyState('Tarefa não encontrada.'),
      );
    }
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final sair = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Descartar alterações?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Continuar editando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );
        if (sair == true && mounted) {
          setState(() => dirty = false);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: AppPage(
        title: original == null ? 'Nova tarefa' : 'Editar tarefa',
        c: widget.c,
        child: Form(
          key: _form,
          onChanged: () {
            if (!dirty) setState(() => dirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                controller: titulo,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => (v ?? '').trim().length < 3
                    ? 'Título deve ter pelo menos 3 caracteres.'
                    : null,
              ),
              TextFormField(
                controller: descricao,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: quadro,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Quadro'),
                items: widget.c.quadros
                    .map(
                      (q) => DropdownMenuItem(value: q.id, child: Text(q.nome)),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  quadro = v;
                  dirty = true;
                }),
                validator: (v) =>
                    v == null ? 'Crie e selecione um quadro.' : null,
              ),
              TextFormField(
                controller: criador,
                decoration: const InputDecoration(labelText: 'Criador'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o criador.' : null,
              ),
              TextFormField(
                controller: membros,
                decoration: const InputDecoration(
                  labelText: 'Participantes separados por vírgula',
                ),
              ),
              TextFormField(
                controller: prazo,
                decoration: const InputDecoration(
                  labelText: 'Prazo (AAAA-MM-DD, opcional)',
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return null;
                  final text = v!.trim();
                  final d = DateTime.tryParse(text);
                  return d == null ||
                          d.toIso8601String().split('T').first != text
                      ? 'Informe uma data válida: AAAA-MM-DD.'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PrioridadeTarefa>(
                initialValue: prioridade,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: PrioridadeTarefa.values
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p.rotulo)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      prioridade = v;
                      dirty = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: salvando ? null : salvar,
                child: Text(salvando ? 'Salvando...' : 'Salvar tarefa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SubtaskFormScreen extends StatefulWidget {
  final AppController c;
  final String tarefaId;
  const SubtaskFormScreen({super.key, required this.c, required this.tarefaId});
  @override
  State<SubtaskFormScreen> createState() => _SubtaskFormState();
}

class _SubtaskFormState extends State<SubtaskFormScreen> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  String? responsavel;
  bool salvando = false;
  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.c.porId(widget.tarefaId);
    if (r == null) {
      return AppPage(
        title: 'Nova subtarefa',
        c: widget.c,
        child: const EmptyState('Tarefa não encontrada.'),
      );
    }
    return AppPage(
      title: 'Nova subtarefa',
      c: widget.c,
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título da subtarefa',
              ),
              validator: (v) => (v ?? '').trim().length < 3
                  ? 'Informe pelo menos 3 caracteres.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Responsável'),
              initialValue: responsavel,
              items: r.tarefa.membrosIds
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => responsavel = v,
              validator: (v) => v == null ? 'Selecione um participante.' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!_form.currentState!.validate()) return;
                      setState(() => salvando = true);
                      try {
                        final copia = TarefaColaborativa.fromMap(
                          r.tarefa.toMap(),
                        );
                        copia.adicionarSubtarefa(
                          Subtarefa(
                            id: OfflineRepository.novoId(),
                            titulo: _titulo.text,
                            responsavelId: responsavel!,
                          ),
                        );
                        await widget.c.salvar(r.copyWith(tarefa: copia));
                        if (context.mounted) {
                          informar(context, 'Subtarefa salva localmente.');
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) informar(context, '$e');
                      } finally {
                        if (mounted) setState(() => salvando = false);
                      }
                    },
              child: const Text('Salvar subtarefa'),
            ),
          ],
        ),
      ),
    );
  }
}

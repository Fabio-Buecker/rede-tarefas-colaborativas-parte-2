import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rede_tarefas_colaborativas/app.dart';
import 'package:rede_tarefas_colaborativas/screens/task_screens.dart';
import 'package:rede_tarefas_colaborativas/widgets/common.dart';
import 'test_support.dart';

void main() {
  testWidgets('dashboard renderiza contadores locais', (tester) async {
    final c = await controlador(comTarefa: true);
    await tester.pumpWidget(TaskLinkApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Visão geral'), findsOneWidget);
    expect(find.text('Preparar entrega'), findsOneWidget);
  });
  testWidgets('lista renderiza tarefa pendente', (tester) async {
    final c = await controlador(comTarefa: true);
    await tester.pumpWidget(MaterialApp(home: TasksScreen(c: c)));
    await tester.pumpAndSettle();
    expect(find.byType(TaskCard), findsOneWidget);
    expect(find.text('Pendente'), findsWidgets);
  });
  testWidgets('busca filtra sem rede', (tester) async {
    final c = await controlador(comTarefa: true);
    await tester.pumpWidget(MaterialApp(home: TasksScreen(c: c)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pump();
    expect(find.text('Nenhuma tarefa encontrada.'), findsOneWidget);
  });
  testWidgets('formulario recusa titulo vazio', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await controlador();
    await tester.pumpWidget(MaterialApp(home: TaskFormScreen(c: c)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar tarefa'));
    await tester.tap(find.text('Salvar tarefa'));
    await tester.pump();
    expect(
      find.text('Título deve ter pelo menos 3 caracteres.'),
      findsOneWidget,
    );
    expect(c.registros, isEmpty);
  });
  testWidgets('formulario recusa criador vazio', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await controlador();
    await tester.pumpWidget(MaterialApp(home: TaskFormScreen(c: c)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Nova tarefa');
    await tester.enterText(find.byType(TextFormField).at(2), '');
    await tester.ensureVisible(find.text('Salvar tarefa'));
    await tester.tap(find.text('Salvar tarefa'));
    await tester.pump();
    expect(find.text('Informe o criador.'), findsOneWidget);
  });
  testWidgets('badge diferencia registro sincronizado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SyncBadge(synced: true))),
    );
    expect(find.text('Sincronizado'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
  });
  testWidgets('argumentos invalidos mostram tela segura', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await controlador();
    await tester.pumpWidget(TaskLinkApp(controller: c));
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(Scaffold).first);
    Navigator.pushNamed(ctx, '/tarefa', arguments: 'id-sem-tipo');
    await tester.pumpAndSettle();
    expect(find.text('Navegação inválida'), findsOneWidget);
  });
  testWidgets('navegacao abre detalhes com id tipado', (tester) async {
    final c = await controlador(comTarefa: true);
    await tester.pumpWidget(TaskLinkApp(controller: c));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Preparar entrega'));
    await tester.tap(find.text('Preparar entrega'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhes da tarefa'), findsOneWidget);
    expect(find.text('Participantes: Ana, Bruno'), findsOneWidget);
  });
}

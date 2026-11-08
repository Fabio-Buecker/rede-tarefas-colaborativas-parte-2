import 'package:flutter/material.dart';
import 'controllers/app_controller.dart';
import 'screens/home_screens.dart';
import 'screens/task_screens.dart';
import 'screens/board_screens.dart';

/// Argumento validado na fronteira de navegação; widgets não fazem casts cegos.
class IdArgs {
  final String id;
  const IdArgs(this.id);
}

class TaskLinkApp extends StatelessWidget {
  final AppController controller;
  const TaskLinkApp({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => MaterialApp(
      title: 'TaskLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF176B62),
        scaffoldBackgroundColor: const Color(0xFFF5F8F7),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF68D8BC),
      ),
      themeMode: controller.escuro ? ThemeMode.dark : ThemeMode.light,
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        final id = args is IdArgs && args.id.trim().isNotEmpty ? args.id : null;
        Widget screen;
        switch (settings.name) {
          case '/':
            screen = DashboardScreen(c: controller);
          case '/quadros':
            screen = BoardsScreen(c: controller);
          case '/quadro/novo':
            screen = BoardFormScreen(c: controller);
          case '/quadro/editar':
            screen = id == null
                ? const InvalidRoute()
                : BoardFormScreen(c: controller, id: id);
          case '/quadro':
            screen = id == null
                ? const InvalidRoute()
                : BoardDetailScreen(c: controller, id: id);
          case '/tarefas':
            screen = TasksScreen(c: controller);
          case '/tarefa/nova':
            screen = TaskFormScreen(c: controller, quadroId: id);
          case '/tarefa/editar':
            screen = id == null
                ? const InvalidRoute()
                : TaskFormScreen(c: controller, id: id);
          case '/tarefa':
            screen = id == null
                ? const InvalidRoute()
                : TaskDetailScreen(c: controller, id: id);
          case '/subtarefa/nova':
            screen = id == null
                ? const InvalidRoute()
                : SubtaskFormScreen(c: controller, tarefaId: id);
          case '/membros':
            screen = MembersScreen(c: controller);
          case '/pendencias':
            screen = PendingScreen(c: controller);
          case '/sincronizacao':
            screen = SyncScreen(c: controller);
          case '/configuracoes':
            screen = SettingsScreen(c: controller);
          case '/sobre':
            screen = AboutScreen(c: controller);
          default:
            screen = const InvalidRoute();
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => screen,
        );
      },
    ),
  );
}

class InvalidRoute extends StatelessWidget {
  const InvalidRoute({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Navegação inválida')),
    body: const Center(
      child: Text(
        'Rota ou identificador inválido. Volte e selecione um registro.',
      ),
    ),
  );
}

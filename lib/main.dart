import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'controllers/app_controller.dart';
import 'datasources/api_service.dart';
import 'datasources/local_dao.dart';
import 'repositories/offline_repository.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    DatabaseFactory? factory;
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    }
    final dao = await LocalDao.abrir(factory: factory);
    final preferences = await SharedPreferences.getInstance();
    const endpoint = String.fromEnvironment(
      'API_URL',
      defaultValue: 'https://jsonplaceholder.typicode.com/todos',
    );
    final controller = AppController(
      OfflineRepository(
        dao,
        ApiService(http.Client(), endpoint: Uri.parse(endpoint)),
      ),
      preferences,
    );
    await controller.carregar();
    runApp(TaskLinkApp(controller: controller));
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Não foi possível iniciar o armazenamento local.\n$e'),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rede_tarefas_colaborativas/app.dart';
import 'test_support.dart';

void main() {
  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final loader = FontLoader('Roboto');
      loader.addFont(
        File(
          '$root/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File(
          '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
        ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
      await icons.load();
    }
  });
  testWidgets('dashboard sem overflow em telefone estreito', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = await controlador(comTarefa: true);
    await tester.pumpWidget(TaskLinkApp(controller: c));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    if (Platform.isWindows) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/dashboard_320.png'),
      );
    }
  });
}

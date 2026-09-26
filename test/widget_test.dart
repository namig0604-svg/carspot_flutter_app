// Базовый smoke-test CarSpot: проверяем, что корневой виджет приложения
// (CarSpotApp) строится без ошибок и на первом кадре показывает заставку —
// без реального автовхода/сети (autoLoginFuture готов сразу, поэтому
// SharedPreferences/API не задействуются).
//
// Старый шаблонный тест ссылался на несуществующий пакет 'carspot_project'
// и класс 'MyApp' (дефолтная заглушка `flutter create`, доставшаяся от
// самого первого коммита) — реальный пакет называется 'carspot', а
// корневой виджет — CarSpotApp (см. lib/main.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carspot/main.dart';
import 'package:carspot/providers/auth_provider.dart';

void main() {
  testWidgets('CarSpotApp builds and shows splash on first frame', (WidgetTester tester) async {
    await tester.pumpWidget(CarSpotApp(
      authProvider: AuthProvider(),
      autoLoginFuture: Future<void>.value(),
    ));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('CARSPOT'), findsOneWidget);
  });
}

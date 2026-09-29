import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_rescue_team/ads/ad_service.dart';
import 'package:tiny_rescue_team/app.dart';
import 'package:tiny_rescue_team/app_state.dart';
import 'package:tiny_rescue_team/audio/audio_service.dart';
import 'package:tiny_rescue_team/campaign/catalog.dart';
import 'package:tiny_rescue_team/l10n/gen/app_localizations.dart';
import 'package:tiny_rescue_team/progress/progress_store.dart';
import 'package:tiny_rescue_team/screens/game_screen.dart';

import '../tool/content/slice.dart';

AppState _state(Directory dir, Catalog catalog) => AppState(
  catalog: catalog,
  store: ProgressStore(dir),
  audio: AudioService(enabled: false),
  ads: DisabledAdService(),
  progress: const Progress(),
  loadSource: LoadSource.fresh,
);

Widget _shell(AppState state, Widget home) => AppScope(
  state: state,
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  testWidgets('preview opens deploy', (tester) async {
    final dir = Directory.systemTemp.createTempSync('trt_wid');
    addTearDown(() => dir.deleteSync(recursive: true));
    final catalog = Catalog.fromScenes([
      for (final b in harborSlice()) b.build(),
    ]);
    await tester.pumpWidget(
      _shell(_state(dir, catalog), GameScreen(entry: catalog.entries.first)),
    );
    await tester.pump();
    expect(find.text('First Shift at the Pier'), findsOneWidget);
    expect(find.byKey(const Key('toDeploy')), findsOneWidget);
    await tester.tap(find.byKey(const Key('toDeploy')));
    await tester.pump();
    expect(find.byKey(const Key('dispatch')), findsOneWidget);
  });

  testWidgets('list controls setting persists', (tester) async {
    final dir = Directory.systemTemp.createTempSync('trt_set');
    addTearDown(() => dir.deleteSync(recursive: true));
    final catalog = Catalog.fromScenes([harborSlice().first.build()]);
    final state = _state(dir, catalog);
    await tester.pumpWidget(_shell(state, const SettingsScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('listControls')));
    await tester.pump();
    expect(state.settings.listControls, isTrue);
  });
}

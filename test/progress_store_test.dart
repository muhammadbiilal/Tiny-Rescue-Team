import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_rescue_team/progress/progress_store.dart';
import 'package:tiny_rescue_team/simulation/roles.dart';

void main() {
  test('v2 bestTurns migrates to bestTicks', () {
    final p = Progress.fromJson({
      'schemaVersion': 2,
      'levels': {
        'M001': {'stars': 2, 'bestTurns': 88, 'attempts': 3},
      },
      'settings': {'music': false},
    });
    expect(p.of('M001').bestTicks, 88);
    expect(p.settings.music, isFalse);
    expect(p.tokens, 0);
  });

  test('first win grants tokens; respec refunds upgrades', () {
    var p = const Progress().recordWin('M001', 100, 1);
    expect(p.tokens, 2);
    p = p.recordWin('M001', 80, 2);
    expect(p.tokens, 3);
    expect(p.of('M001').bestTicks, 80);
  });

  test('corrupt file is kept and backup is used', () {
    final dir = Directory.systemTemp.createTempSync('trt_prog');
    addTearDown(() => dir.deleteSync(recursive: true));
    final store = ProgressStore(dir);
    store.save(const Progress(tokens: 4));
    File('${dir.path}/progress.json').writeAsStringSync('{not json');
    File('${dir.path}/progress.json.bak').writeAsStringSync(
      '{"schemaVersion":3,"levels":{},"settings":{},"winsSinceAd":0,"tokens":4,"upgrades":{}}',
    );
    final loaded = store.load();
    expect(store.lastLoad, LoadSource.backup);
    expect(loaded.tokens, 4);
    expect(
      dir.listSync().any((f) => f.path.contains('progress.corrupt-')),
      isTrue,
    );
  });

  test('upgrade json round-trips', () {
    final p = Progress(
      upgrades: {
        Role.rescuer.name: const Upgrades(path: UpgradePath.mobility, tier: 2),
      },
    );
    final again = Progress.fromJson(p.toJson());
    expect(again.upgradeOf(Role.rescuer).tier, 2);
    expect(again.upgradeOf(Role.rescuer).path, UpgradePath.mobility);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_rescue_team/ads/ad_service.dart';
import 'package:tiny_rescue_team/app_state.dart';
import 'package:tiny_rescue_team/audio/audio_service.dart';
import 'package:tiny_rescue_team/campaign/catalog.dart';
import 'package:tiny_rescue_team/progress/progress_store.dart';
import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

class FailingAds implements AdService {
  int calls = 0;
  @override
  AdsMode get mode => AdsMode.test;
  @override
  Future<void> init() async => throw const SocketException('offline');
  @override
  Future<bool> showBetweenLevels() async {
    calls++;
    return false;
  }
}

CatalogEntry entry(String id, int slot) => CatalogEntry(
  MissionScene(
    id: id,
    world: 1,
    slot: slot,
    title: 'Test call',
    brief: 'A test mission used only by ads unit tests.',
    teamSize: 1,
    allowedRoles: const [Role.rescuer],
    nodes: const [SceneNode('a', 100, 200)],
    edges: const [],
    deploy: const [DeployZone('a')],
    objectives: const [Objective(ObjectiveType.civiliansSafe, count: 0)],
  ),
);

void main() {
  test('default build has ads disabled', () {
    expect(adsModeFromEnvironment(), AdsMode.disabled);
    expect(createAdService(AdsMode.disabled).mode, AdsMode.disabled);
  });

  test('production mode is refused until release gates pass', () {
    expect(createAdService(AdsMode.production).mode, AdsMode.disabled);
  });

  test('frequency cap and no ads after tutorials', () {
    const p = AdPolicy(winsBetweenAds: 3);
    expect(p.shouldShowAfterWin(2, tutorialLevel: false), isFalse);
    expect(p.shouldShowAfterWin(3, tutorialLevel: false), isTrue);
    expect(p.shouldShowAfterWin(5, tutorialLevel: true), isFalse);
  });

  test('ad failure never changes progress', () async {
    final dir = Directory.systemTemp.createTempSync('trt_ads');
    addTearDown(() => dir.deleteSync(recursive: true));
    final ads = FailingAds();
    final e = entry('M010', 10);
    final app = AppState(
      catalog: Catalog([e]),
      store: ProgressStore(dir),
      audio: AudioService(enabled: false),
      ads: ads,
      progress: const Progress(winsSinceAd: 5),
      loadSource: LoadSource.fresh,
    );
    await expectLater(ads.init(), throwsA(isA<SocketException>()));
    app.recordWin(e, 40, 3);
    await app.maybeShowAd(e);
    expect(ads.calls, 1);
    expect(app.progress.of('M010').stars, 3);
    expect(app.progress.of('M010').bestTicks, 40);
    expect(
      app.progress.winsSinceAd,
      6,
      reason: 'counter only resets when an ad was actually shown',
    );
  });
}

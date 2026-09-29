import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'ads/ad_service.dart';
import 'app.dart';
import 'app_state.dart';
import 'audio/audio_service.dart';
import 'campaign/catalog.dart';
import 'progress/progress_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final catalog = await Catalog.load(rootBundle);
  final dir = await getApplicationSupportDirectory();
  final store = ProgressStore(dir);
  final progress = store.load();
  final audio = AudioService(
    music: progress.settings.music,
    effects: progress.settings.effects,
  );
  final ads = createAdService(adsModeFromEnvironment());
  final state = AppState(
    catalog: catalog,
    store: store,
    audio: audio,
    ads: ads,
    progress: progress,
    loadSource: store.lastLoad,
  );
  runApp(TinyRescueApp(state: state));
  // Never block first frame on audio or ads.
  audio.preload().then((_) => audio.updateMusic());
  ads.init();
}

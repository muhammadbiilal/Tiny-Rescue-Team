import 'package:flutter/widgets.dart';

import 'ads/ad_service.dart';
import 'audio/audio_service.dart';
import 'campaign/catalog.dart';
import 'progress/progress_store.dart';
import 'simulation/roles.dart';

class AppState extends ChangeNotifier {
  final Catalog catalog;
  final ProgressStore store;
  final AudioService audio;
  final AdService ads;
  final AdPolicy adPolicy;
  final LoadSource loadSource;
  Progress _progress;

  AppState({
    required this.catalog,
    required this.store,
    required this.audio,
    required this.ads,
    required Progress progress,
    required this.loadSource,
    this.adPolicy = const AdPolicy(),
  }) : _progress = progress {
    audio.music = progress.settings.music;
    audio.effects = progress.settings.effects;
  }

  Progress get progress => _progress;
  Settings get settings => _progress.settings;

  void _save(Progress p) {
    _progress = p;
    try {
      store.save(p);
    } catch (e) {
      debugPrint('progress save failed: $e');
    }
    notifyListeners();
  }

  bool isUnlocked(CatalogEntry e) {
    final i = catalog.entries.indexOf(e);
    if (i <= 0) return true;
    return _progress.of(e.id).completed ||
        _progress.of(catalog.entries[i - 1].id).completed;
  }

  bool worldUnlocked(int world) {
    final levels = catalog.inWorld(world);
    return levels.isNotEmpty && isUnlocked(levels.first);
  }

  int completedIn(int world) =>
      catalog.inWorld(world).where((e) => _progress.of(e.id).completed).length;

  int get totalStars => _progress.levels.values.fold(0, (a, p) => a + p.stars);
  int get totalCompleted =>
      catalog.entries.where((e) => _progress.of(e.id).completed).length;
  int get tokens => _progress.tokens;

  CatalogEntry? get nextToPlay {
    for (final e in catalog.entries) {
      if (!_progress.of(e.id).completed && isUnlocked(e)) return e;
    }
    return catalog.entries.isEmpty ? null : catalog.entries.last;
  }

  Upgrades upgradeOf(Role role) => _progress.upgradeOf(role);

  void recordAttempt(CatalogEntry e) => _save(_progress.recordAttempt(e.id));

  void recordWin(CatalogEntry e, int ticks, int stars) =>
      _save(_progress.recordWin(e.id, ticks, stars));

  Future<void> maybeShowAd(CatalogEntry finished) async {
    final tutorial = finished.tier == 'tutorial';
    if (ads.mode == AdsMode.disabled) return;
    if (!adPolicy.shouldShowAfterWin(
      _progress.winsSinceAd,
      tutorialLevel: tutorial,
    ))
      return;
    final shown = await ads.showBetweenLevels();
    if (shown) _save(_progress.copyWith(winsSinceAd: 0));
  }

  void updateSettings(Settings s) {
    audio.music = s.music;
    audio.effects = s.effects;
    audio.updateMusic();
    _save(_progress.copyWith(settings: s));
  }

  /// Spend tokens on the next tier of [path]. Switching path refunds spent tokens.
  String? buyUpgrade(Role role, UpgradePath path) {
    final current = upgradeOf(role);
    if (path == UpgradePath.none) {
      final refund = _spent(current);
      _save(
        _progress.copyWith(
          tokens: tokens + refund,
          upgrades: {..._progress.upgrades, role.name: Upgrades.none},
        ),
      );
      return null;
    }
    if (current.path != UpgradePath.none && current.path != path) {
      return 'Respec this path first.';
    }
    final next = current.path == path ? current.tier + 1 : 1;
    if (next > 3) return 'This path is already complete.';
    final cost = upgradeTierCost[next];
    if (tokens < cost) return 'Need $cost service tokens.';
    _save(
      _progress.copyWith(
        tokens: tokens - cost,
        upgrades: {
          ..._progress.upgrades,
          role.name: Upgrades(path: path, tier: next),
        },
      ),
    );
    return null;
  }

  int _spent(Upgrades u) {
    var n = 0;
    for (var t = 1; t <= u.tier; t++) {
      n += upgradeTierCost[t];
    }
    return n;
  }

  void resetProgress() => _save(Progress(settings: _progress.settings));
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

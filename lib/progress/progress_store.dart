import 'dart:convert';
import 'dart:io';

import '../simulation/roles.dart';

const int progressSchemaVersion = 3;

class LevelProgress {
  final int stars;
  final int bestTicks;
  final int attempts;
  const LevelProgress({this.stars = 0, this.bestTicks = 0, this.attempts = 0});

  bool get completed => stars > 0;

  Map<String, Object?> toJson() => {
    'stars': stars,
    'bestTicks': bestTicks,
    'attempts': attempts,
  };

  static LevelProgress fromJson(Map<String, Object?> j) => LevelProgress(
    stars: (j['stars'] as num?)?.toInt() ?? 0,
    bestTicks:
        (j['bestTicks'] as num?)?.toInt() ??
        (j['bestTurns'] as num?)?.toInt() ??
        0,
    attempts: (j['attempts'] as num?)?.toInt() ?? 0,
  );
}

class Settings {
  final bool music;
  final bool effects;
  final bool reducedMotion;
  final bool highContrast;
  final bool haptics;
  final bool listControls;
  const Settings({
    this.music = true,
    this.effects = true,
    this.reducedMotion = false,
    this.highContrast = false,
    this.haptics = true,
    this.listControls = false,
  });

  Settings copyWith({
    bool? music,
    bool? effects,
    bool? reducedMotion,
    bool? highContrast,
    bool? haptics,
    bool? listControls,
  }) => Settings(
    music: music ?? this.music,
    effects: effects ?? this.effects,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    highContrast: highContrast ?? this.highContrast,
    haptics: haptics ?? this.haptics,
    listControls: listControls ?? this.listControls,
  );

  Map<String, Object?> toJson() => {
    'music': music,
    'effects': effects,
    'reducedMotion': reducedMotion,
    'highContrast': highContrast,
    'haptics': haptics,
    'listControls': listControls,
  };

  static Settings fromJson(Map<String, Object?> j) => Settings(
    music: j['music'] as bool? ?? true,
    effects: j['effects'] as bool? ?? true,
    reducedMotion: j['reducedMotion'] as bool? ?? false,
    highContrast: j['highContrast'] as bool? ?? false,
    haptics: j['haptics'] as bool? ?? true,
    listControls: j['listControls'] as bool? ?? false,
  );
}

class Progress {
  final Map<String, LevelProgress> levels;
  final Settings settings;
  final int winsSinceAd;
  final int tokens;
  final Map<String, Upgrades> upgrades;
  const Progress({
    this.levels = const {},
    this.settings = const Settings(),
    this.winsSinceAd = 0,
    this.tokens = 0,
    this.upgrades = const {},
  });

  LevelProgress of(String id) => levels[id] ?? const LevelProgress();
  Upgrades upgradeOf(Role role) => upgrades[role.name] ?? Upgrades.none;

  Progress copyWith({
    Map<String, LevelProgress>? levels,
    Settings? settings,
    int? winsSinceAd,
    int? tokens,
    Map<String, Upgrades>? upgrades,
  }) => Progress(
    levels: levels ?? this.levels,
    settings: settings ?? this.settings,
    winsSinceAd: winsSinceAd ?? this.winsSinceAd,
    tokens: tokens ?? this.tokens,
    upgrades: upgrades ?? this.upgrades,
  );

  Progress recordAttempt(String id) {
    final p = of(id);
    return copyWith(
      levels: {
        ...levels,
        id: LevelProgress(
          stars: p.stars,
          bestTicks: p.bestTicks,
          attempts: p.attempts + 1,
        ),
      },
    );
  }

  Progress recordWin(String id, int ticks, int stars) {
    final p = of(id);
    final best = p.bestTicks == 0 || ticks < p.bestTicks ? ticks : p.bestTicks;
    final first = p.stars == 0;
    final improved = stars > p.stars;
    var gained = 0;
    if (first) gained += 2;
    if (improved && !first) gained += 1;
    return copyWith(
      levels: {
        ...levels,
        id: LevelProgress(
          stars: stars > p.stars ? stars : p.stars,
          bestTicks: best,
          attempts: p.attempts,
        ),
      },
      winsSinceAd: winsSinceAd + 1,
      tokens: tokens + gained,
    );
  }

  Map<String, Object?> toJson() => {
    'schemaVersion': progressSchemaVersion,
    'levels': {for (final e in levels.entries) e.key: e.value.toJson()},
    'settings': settings.toJson(),
    'winsSinceAd': winsSinceAd,
    'tokens': tokens,
    'upgrades': {for (final e in upgrades.entries) e.key: e.value.toJson()},
  };

  static Progress fromJson(Map<String, Object?> j) {
    final version = (j['schemaVersion'] ?? j['version']) as int? ?? 1;
    if (version > progressSchemaVersion) {
      throw FormatException('progress schema $version is newer than this app');
    }
    if (version == 1) {
      final stars = ((j['stars'] as Map?) ?? const {}).cast<String, Object?>();
      return Progress(
        levels: {
          for (final id
              in ((j['completed'] as List?) ?? const []).cast<String>())
            id: LevelProgress(stars: (stars[id] as num?)?.toInt() ?? 1),
        },
      );
    }
    return Progress(
      levels: {
        for (final e in ((j['levels'] as Map?) ?? const {}).entries)
          e.key as String: LevelProgress.fromJson(
            (e.value as Map).cast<String, Object?>(),
          ),
      },
      settings: Settings.fromJson(
        ((j['settings'] as Map?) ?? const {}).cast<String, Object?>(),
      ),
      winsSinceAd: (j['winsSinceAd'] as num?)?.toInt() ?? 0,
      tokens: (j['tokens'] as num?)?.toInt() ?? 0,
      upgrades: {
        for (final e in ((j['upgrades'] as Map?) ?? const {}).entries)
          e.key as String: Upgrades.fromJson(
            (e.value as Map).cast<String, Object?>(),
          ),
      },
    );
  }
}

enum LoadSource { fresh, main, backup, resetAfterCorruption }

class ProgressStore {
  final Directory dir;
  LoadSource lastLoad = LoadSource.fresh;
  ProgressStore(this.dir);

  File get _main => File('${dir.path}/progress.json');
  File get _backup => File('${dir.path}/progress.json.bak');
  File get _tmp => File('${dir.path}/progress.json.tmp');

  Progress? _read(File f) {
    try {
      if (!f.existsSync()) return null;
      return Progress.fromJson(
        (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return null;
    }
  }

  Progress load() {
    final main = _read(_main);
    if (main != null) {
      lastLoad = LoadSource.main;
      return main;
    }
    final backup = _read(_backup);
    final hadFile = _main.existsSync();
    if (hadFile) {
      _main.copySync(
        '${dir.path}/progress.corrupt-${DateTime.now().millisecondsSinceEpoch}.json',
      );
    }
    if (backup != null) {
      lastLoad = LoadSource.backup;
      return backup;
    }
    lastLoad = hadFile ? LoadSource.resetAfterCorruption : LoadSource.fresh;
    return const Progress();
  }

  void save(Progress p) {
    dir.createSync(recursive: true);
    final raf = _tmp.openSync(mode: FileMode.write);
    raf.writeStringSync(jsonEncode(p.toJson()));
    raf.flushSync();
    raf.closeSync();
    if (_main.existsSync() && _read(_main) != null)
      _main.copySync(_backup.path);
    _tmp.renameSync(_main.path);
  }
}

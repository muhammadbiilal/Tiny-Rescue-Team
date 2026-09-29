import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'campaign/catalog.dart';
import 'l10n/gen/app_localizations.dart';
import 'progress/progress_store.dart';
import 'screens/game_screen.dart';
import 'screens/roster_screen.dart';

class TinyRescueApp extends StatelessWidget {
  final AppState state;
  const TinyRescueApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE63946)),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _notified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notified) return;
    _notified = true;
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final notes = [
      if (app.loadSource == LoadSource.backup) l.recoveredBackup,
      if (app.loadSource == LoadSource.resetAfterCorruption) l.recoveredReset,
      if (app.catalog.problems.isNotEmpty) l.contentProblem,
    ];
    if (notes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(notes.join('\n'))));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final next = app.nextToPlay;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HomeRosterPreview(),
                  const SizedBox(height: 12),
                  Text(
                    l.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(l.tagline, textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    l.totalStars(
                      app.totalStars,
                      app.totalCompleted,
                      app.catalog.entries.length,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (next != null)
                    FilledButton.icon(
                      key: const Key('continue'),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        app.totalCompleted == 0
                            ? l.play
                            : l.continueLevel(next.id),
                      ),
                      onPressed: () => openLevel(context, next),
                    ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('worlds'),
                    icon: const Icon(Icons.map),
                    label: Text(l.worlds),
                    onPressed: () => _push(context, const WorldMapScreen()),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('roster'),
                    icon: const Icon(Icons.groups_outlined),
                    label: Text(l.roster),
                    onPressed: () => _push(context, const RosterScreen()),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.insights),
                    label: Text(l.progress),
                    onPressed: () => _push(context, const ProgressScreen()),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('settings'),
                    icon: const Icon(Icons.settings),
                    label: Text(l.settings),
                    onPressed: () => _push(context, const SettingsScreen()),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _push(context, const CreditsScreen()),
                    child: Text(l.credits),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _push(BuildContext context, Widget w) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

void openLevel(BuildContext context, CatalogEntry e, {bool replace = false}) {
  final route = MaterialPageRoute<void>(builder: (_) => GameScreen(entry: e));
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

class WorldMapScreen extends StatelessWidget {
  const WorldMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.worlds)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final w in worlds)
            if (app.catalog.inWorld(w.number).isNotEmpty)
              _WorldCard(world: w, unlocked: app.worldUnlocked(w.number)),
        ],
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  final WorldInfo world;
  final bool unlocked;
  const _WorldCard({required this.world, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final total = app.catalog.inWorld(world.number).length;
    final done = app.completedIn(world.number);
    return Card(
      key: Key('world-${world.number}'),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        enabled: unlocked,
        leading: CircleAvatar(
          backgroundColor: world.color,
          foregroundColor: Colors.white,
          child: unlocked
              ? Text('${world.number}')
              : const Icon(Icons.lock, size: 18),
        ),
        title: Text(
          '${world.number == 13 ? '' : 'World ${world.number}: '}${world.name}',
        ),
        subtitle: Text(
          unlocked
              ? '${world.theme}\n${l.levelsDone(done, total)}'
              : l.worldLocked,
        ),
        isThreeLine: unlocked,
        trailing: unlocked ? const Icon(Icons.chevron_right) : null,
        onTap: unlocked
            ? () => _push(context, LevelSelectScreen(world: world))
            : null,
      ),
    );
  }
}

class LevelSelectScreen extends StatelessWidget {
  final WorldInfo world;
  const LevelSelectScreen({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final levels = app.catalog.inWorld(world.number);
    return Scaffold(
      appBar: AppBar(
        title: Text(world.name),
        backgroundColor: world.color,
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 96,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: levels.length,
        itemBuilder: (context, i) {
          final e = levels[i];
          final open = app.isUnlocked(e);
          final stars = app.progress.of(e.id).stars;
          return Semantics(
            button: true,
            label: open ? l.levelOpen(e.id, stars) : l.levelLocked(e.id),
            excludeSemantics: true,
            child: Material(
              color: open
                  ? world.color.withValues(alpha: 0.18)
                  : Colors.black12,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: Key('level-${e.id}'),
                borderRadius: BorderRadius.circular(12),
                onTap: open ? () => openLevel(context, e) : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${e.number}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (open)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var s = 1; s <= 3; s++)
                            Icon(
                              s <= stars ? Icons.star : Icons.star_border,
                              size: 16,
                            ),
                        ],
                      )
                    else
                      const Icon(Icons.lock, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final s = app.settings;
    Widget toggle(
      String label,
      bool value,
      Settings Function(bool) apply, [
      String? key,
    ]) => SwitchListTile(
      key: key == null ? null : Key(key),
      title: Text(label),
      value: value,
      onChanged: (v) => app.updateSettings(apply(v)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        children: [
          toggle(l.music, s.music, (v) => s.copyWith(music: v)),
          toggle(l.effects, s.effects, (v) => s.copyWith(effects: v)),
          toggle(l.haptics, s.haptics, (v) => s.copyWith(haptics: v)),
          toggle(
            l.reducedMotion,
            s.reducedMotion,
            (v) => s.copyWith(reducedMotion: v),
          ),
          toggle(
            l.highContrast,
            s.highContrast,
            (v) => s.copyWith(highContrast: v),
          ),
          toggle(
            l.listControls,
            s.listControls,
            (v) => s.copyWith(listControls: v),
            'listControls',
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l.resetProgress),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  content: Text(l.resetConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(l.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(l.erase),
                    ),
                  ],
                ),
              );
              if (ok == true) app.resetProgress();
            },
          ),
        ],
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.progress)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            l.totalStars(
              app.totalStars,
              app.totalCompleted,
              app.catalog.entries.length,
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          for (final w in worlds)
            if (app.catalog.inWorld(w.number).isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.name),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value:
                          app.completedIn(w.number) /
                          app.catalog.inWorld(w.number).length,
                      color: w.color,
                      semanticsLabel: w.name,
                      semanticsValue: l.levelsDone(
                        app.completedIn(w.number),
                        app.catalog.inWorld(w.number).length,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.credits)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(l.creditsBody),
      ),
    );
  }
}

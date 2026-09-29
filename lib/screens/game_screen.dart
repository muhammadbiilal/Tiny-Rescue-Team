import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Simulation;

import '../app.dart' show openLevel;
import '../app_state.dart';
import '../campaign/catalog.dart';
import '../game_scene/rescue_game.dart';
import '../l10n/gen/app_localizations.dart';
import '../simulation/describe.dart';
import '../simulation/engine.dart';
import '../simulation/progression.dart';
import '../simulation/roles.dart' hide Focus;
import '../simulation/roles.dart' as rules show Focus;
import '../simulation/run.dart';
import '../simulation/scene.dart';

enum _Phase { preview, deploy, play, result }

class GameScreen extends StatefulWidget {
  final CatalogEntry entry;
  const GameScreen({super.key, required this.entry});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  _Phase _phase = _Phase.preview;
  late List<UnitSetup> _team;
  RescueGame? _game;
  Simulation? _sim;
  final ValueNotifier<List<String>> _log = ValueNotifier(const []);
  RunResult? _result;
  String? _block;

  MissionScene get scene => widget.entry.scene;

  bool _inited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;
    _inited = true;
    _resetTeam();
  }

  @override
  void dispose() {
    _game?.pauseEngine();
    _log.dispose();
    super.dispose();
  }

  void _resetTeam() {
    final app = context.mounted ? AppScope.of(context) : null;
    final zones = scene.deploy;
    _team = [
      for (var i = 0; i < scene.teamSize && i < scene.allowedRoles.length; i++)
        UnitSetup(
          scene.allowedRoles[i],
          zones[i % zones.length].node,
          upgrades: app?.upgradeOf(scene.allowedRoles[i]) ?? Upgrades.none,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return switch (_phase) {
      _Phase.preview => _Preview(
        entry: widget.entry,
        onNext: () => setState(() => _phase = _Phase.deploy),
      ),
      _Phase.deploy => _Deploy(
        entry: widget.entry,
        team: _team,
        onChanged: (t) => setState(() => _team = t),
        onDispatch: _dispatch,
        error: _block,
      ),
      _Phase.play => _Play(
        entry: widget.entry,
        game: _game!,
        sim: _sim!,
        log: _log,
        onAbility: _ability,
        onRedirect: _redirect,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      _Phase.result => _Result(
        entry: widget.entry,
        result: _result!,
        onReplay: _replay,
        onNext: _next,
      ),
    };
  }

  void _dispatch() {
    final err = validateLoadout(scene, _team);
    if (err != null) {
      setState(() => _block = err);
      return;
    }
    final app = AppScope.of(context);
    app.audio.tap();
    app.recordAttempt(widget.entry);
    _sim = Simulation(scene, _team);
    _log.value = const [];
    _game = RescueGame(
      scene: scene,
      sim: _sim!,
      reducedMotion: app.settings.reducedMotion,
      highContrast: app.settings.highContrast,
      onEvents: (ev) {
        if (!mounted) return;
        for (final e in ev) {
          app.audio.playEvent(e.type);
          final line = describe(e, scene, _team);
          if (line != null)
            _log.value = [
              ..._log.value,
              '${(e.tick / 10).toStringAsFixed(1)}s  $line',
            ];
        }
        if (!_sim!.running && _result == null) {
          final r = RunResult(
            _sim!.outcome,
            _sim!.tick,
            _sim!.events,
            eventHash(_sim!.events),
            starsFor(scene, _sim!.outcome, _sim!.tick),
            _sim!.failReason,
            _sim!.failHints,
            _sim!.abilitiesUsed,
            _sim!.objectives.where((o) => o == ObjState.met).length,
          );
          if (r.won) app.recordWin(widget.entry, r.ticks, r.stars);
          setState(() {
            _result = r;
            _phase = _Phase.result;
          });
        }
      },
    );
    setState(() {
      _block = null;
      _phase = _Phase.play;
    });
  }

  void _ability(int unit) {
    final sim = _sim!;
    final targets = sim.abilityTargets(unit);
    if (targets.isEmpty) {
      setState(
        () => _block =
            sim.validate(Command(sim.tick, CommandType.ability, unit)) ??
            'Nothing in range.',
      );
      return;
    }
    final self = _team[unit].role.def.ability.target == AbilityTarget.self;
    if (self || targets.length == 1) {
      final reason = sim.issue(
        Command(
          sim.tick,
          CommandType.ability,
          unit,
          self ? null : targets.first,
        ),
      );
      if (reason != null) setState(() => _block = reason);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => ListView(
        shrinkWrap: true,
        children: [
          for (final t in targets)
            ListTile(
              title: Text(t),
              onTap: () {
                Navigator.pop(c);
                final reason = sim.issue(
                  Command(sim.tick, CommandType.ability, unit, t),
                );
                if (reason != null && mounted) setState(() => _block = reason);
              },
            ),
        ],
      ),
    );
  }

  void _redirect(int unit) {
    final sim = _sim!;
    final jobs = sim.jobs();
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => ListView(
        shrinkWrap: true,
        children: [
          for (final j in jobs)
            ListTile(
              title: Text(jobTitle(j.id, scene)),
              onTap: () {
                Navigator.pop(c);
                final reason = sim.issue(
                  Command(sim.tick, CommandType.redirect, unit, j.id),
                );
                if (reason != null && mounted) setState(() => _block = reason);
              },
            ),
        ],
      ),
    );
  }

  void _replay() {
    _game?.pauseEngine();
    _game = null;
    _sim = null;
    _result = null;
    _log.value = const [];
    setState(() => _phase = _Phase.deploy);
  }

  void _next() {
    final app = AppScope.of(context);
    final i = app.catalog.entries.indexOf(widget.entry);
    final next = i + 1 < app.catalog.entries.length
        ? app.catalog.entries[i + 1]
        : null;
    if (next != null && app.isUnlocked(next)) {
      openLevel(context, next, replace: true);
    } else {
      Navigator.of(context).pop();
    }
  }
}

class _Preview extends StatelessWidget {
  final CatalogEntry entry;
  final VoidCallback onNext;
  const _Preview({required this.entry, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = entry.scene;
    return Scaffold(
      appBar: AppBar(title: Text(s.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: entry.world == 1
                ? Image.asset(
                    'assets/art/harbor_backdrop.png',
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _worldBanner(entry),
                  )
                : _worldBanner(entry),
          ),
          const SizedBox(height: 12),
          Text(s.brief, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text(l.objective, style: Theme.of(context).textTheme.titleMedium),
          for (final o in s.objectives)
            ListTile(
              dense: true,
              leading: const Icon(Icons.flag_outlined),
              title: Text(objectiveText(o, s)),
            ),
          if (s.hazards.isNotEmpty) ...[
            Text(l.forecast, style: Theme.of(context).textTheme.titleMedium),
            for (final h in s.hazards)
              ListTile(
                dense: true,
                leading: const Icon(Icons.wb_cloudy_outlined),
                title: Text(hazardText(h, s)),
              ),
          ],
          if (s.tutorial.isNotEmpty) ...[
            Text(l.tutorial, style: Theme.of(context).textTheme.titleMedium),
            for (final t in s.tutorial)
              ListTile(
                dense: true,
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(t),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: const Key('toDeploy'),
            onPressed: onNext,
            child: Text(l.placeTeam),
          ),
        ),
      ),
    );
  }
}

class _Deploy extends StatelessWidget {
  final CatalogEntry entry;
  final List<UnitSetup> team;
  final ValueChanged<List<UnitSetup>> onChanged;
  final VoidCallback onDispatch;
  final String? error;
  const _Deploy({
    required this.entry,
    required this.team,
    required this.onChanged,
    required this.onDispatch,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = entry.scene;
    final earned = gearUnlockedAt(missionNumber(s.id));
    final gear = [
      for (final g in s.gear)
        if (earned.contains(g)) g,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.placeTeam)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (error != null)
            MaterialBanner(
              content: Text(error!),
              actions: const [SizedBox.shrink()],
            ),
          for (var i = 0; i < team.length; i++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      roleName[team[i].role]!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(roleTitle[team[i].role]!),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final z in s.deploy)
                          ChoiceChip(
                            key: Key('place-$i-${z.node}'),
                            label: Text(s.node(z.node).label),
                            selected: team[i].node == z.node,
                            onSelected: (_) {
                              final next = [...team];
                              next[i] = team[i].copyWith(node: z.node);
                              onChanged(next);
                            },
                          ),
                      ],
                    ),
                    if (gear.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(l.equipment),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('None'),
                            selected: team[i].gear == null,
                            onSelected: (_) {
                              final next = [...team];
                              next[i] = team[i].copyWith(clearGear: true);
                              onChanged(next);
                            },
                          ),
                          for (final g in gear)
                            ChoiceChip(
                              label: Text(gearTitle[g]!),
                              selected: team[i].gear == g,
                              onSelected: (_) {
                                final next = [...team];
                                next[i] = team[i].copyWith(gear: g);
                                onChanged(next);
                              },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(l.priority),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final f in rules.Focus.values)
                          ChoiceChip(
                            label: Text(focusTitle[f]!),
                            selected: team[i].focus == f,
                            onSelected: (_) {
                              final next = [...team];
                              next[i] = team[i].copyWith(focus: f);
                              onChanged(next);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            key: const Key('dispatch'),
            icon: const Icon(Icons.play_arrow),
            label: Text(l.dispatch),
            onPressed: onDispatch,
          ),
        ),
      ),
    );
  }
}

class _Play extends StatelessWidget {
  final CatalogEntry entry;
  final RescueGame game;
  final Simulation sim;
  final ValueNotifier<List<String>> log;
  final void Function(int unit) onAbility;
  final void Function(int unit) onRedirect;
  final VoidCallback onBack;
  const _Play({
    required this.entry,
    required this.game,
    required this.sim,
    required this.log,
    required this.onAbility,
    required this.onRedirect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${(sim.tick / 10).toStringAsFixed(0)}s'),
        leading: IconButton(onPressed: onBack, icon: const Icon(Icons.close)),
        actions: [
          IconButton(
            key: const Key('pause'),
            tooltip: game.paused ? l.resume : l.pause,
            onPressed: () {
              game.paused = !game.paused;
              (context as Element).markNeedsBuild();
            },
            icon: Icon(game.paused ? Icons.play_arrow : Icons.pause),
          ),
          TextButton(
            key: const Key('speed'),
            onPressed: () {
              game.speed = game.speed >= 2 ? 1 : 2;
              (context as Element).markNeedsBuild();
            },
            child: Text('${game.speed.toStringAsFixed(0)}x'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 5, child: GameWidget(game: game)),
          if (app.settings.listControls || true)
            Expanded(
              flex: 3,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        children: [
                          for (var i = 0; i < sim.units.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilledButton.tonal(
                                key: Key('ability-$i'),
                                onPressed:
                                    sim.chargesLeft <= 0 ||
                                        sim.units[i].abilityUsed
                                    ? null
                                    : () => onAbility(i),
                                child: Text(
                                  '${roleName[sim.units[i].role]!.split(' ').first}: ${abilityTitle[sim.units[i].role.def.ability]}',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: OutlinedButton(
                                key: Key('redirect-$i'),
                                onPressed: sim.redirectsLeft <= 0
                                    ? null
                                    : () => onRedirect(i),
                                child: Text(l.redirect),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: ValueListenableBuilder<List<String>>(
                        valueListenable: log,
                        builder: (c, lines, _) => ListView.builder(
                          reverse: true,
                          itemCount: lines.length,
                          itemBuilder: (c, i) {
                            final line = lines[lines.length - 1 - i];
                            return Semantics(
                              liveRegion: i == 0,
                              child: ListTile(dense: true, title: Text(line)),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  final CatalogEntry entry;
  final RunResult result;
  final VoidCallback onReplay;
  final VoidCallback onNext;
  const _Result({
    required this.entry,
    required this.result,
    required this.onReplay,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final seconds = (result.ticks / 10).round();
    return Scaffold(
      appBar: AppBar(title: Text(result.won ? l.won : l.failed)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              result.won ? l.wonDetail(seconds) : result.failReason,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (result.won)
              Row(
                children: [
                  for (var s = 1; s <= 3; s++)
                    Icon(s <= result.stars ? Icons.star : Icons.star_border),
                ],
              ),
            for (final h in result.hints)
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: Text(h),
              ),
            const Spacer(),
            OutlinedButton(onPressed: onReplay, child: Text(l.replay)),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('nextMission'),
              onPressed: () async {
                if (result.won) await app.maybeShowAd(entry);
                onNext();
              },
              child: Text(l.nextLevel),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _worldBanner(CatalogEntry entry) {
  final info = worlds[(entry.world - 1).clamp(0, worlds.length - 1)];
  return SizedBox(
    height: 140,
    child: ColoredBox(
      color: info.color,
      child: Center(
        child: Text(
          info.name,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    ),
  );
}

/// Bounded deterministic search over team, placement, gear, focus and one
/// ability use. Finds a free-player witness and measures how much the
/// player's choices matter.
library;

import 'engine.dart';
import 'roles.dart';
import 'run.dart';
import 'scene.dart';

class SolverReport {
  final int tried;
  final int won;
  final Witness? best;
  final int bestTicks;
  final int medianWinTicks;

  /// Distinct responder sets with at least one winning setup.
  final int winningTeams;
  final bool needsAbility;
  final bool needsFocus;

  /// A few losing setups, kept for diagnostics and "real choice" evidence.
  final List<List<UnitSetup>> failures;
  const SolverReport({
    this.failures = const [],
    required this.tried,
    required this.won,
    required this.best,
    required this.bestTicks,
    required this.medianWinTicks,
    required this.winningTeams,
    required this.needsAbility,
    required this.needsFocus,
  });

  double get winRate => tried == 0 ? 0 : won / tried;

  /// Share of sampled setups that win, bucketed. Not arbitrary stat inflation:
  /// harder missions are ones where fewer plans work.
  String get difficulty {
    if (best == null) return 'unsolved';
    final r = winRate;
    if (r >= 0.35) return 'straightforward';
    if (r >= 0.12) return 'moderate';
    if (r >= 0.03) return 'hard';
    return 'mastery';
  }
}

List<List<T>> combinations<T>(List<T> items, int k) {
  final out = <List<T>>[];
  void go(int start, List<T> acc) {
    if (acc.length == k) {
      out.add([...acc]);
      return;
    }
    for (var i = start; i < items.length; i++) {
      acc.add(items[i]);
      go(i + 1, acc);
      acc.removeLast();
    }
  }

  go(0, []);
  return out;
}

List<List<String>> placements(List<DeployZone> zones, int n) {
  final out = <List<String>>[];
  final used = <String, int>{};
  void go(List<String> acc) {
    if (acc.length == n) {
      out.add([...acc]);
      return;
    }
    for (final z in zones) {
      final c = used[z.node] ?? 0;
      if (c >= z.capacity) continue;
      used[z.node] = c + 1;
      acc.add(z.node);
      go(acc);
      acc.removeLast();
      used[z.node] = c;
    }
  }

  go([]);
  return out;
}

/// Each entry maps unit index -> gear. Identical items are not permuted.
List<Map<int, Gear>> gearAssignments(List<Gear> pool, int n) {
  final items = [...pool]..sort((a, b) => a.index.compareTo(b.index));
  final out = <Map<int, Gear>>[];
  void go(int i, Map<int, Gear> acc, int minForSame) {
    if (i == items.length) {
      out.add(Map.of(acc));
      return;
    }
    final same = i > 0 && items[i] == items[i - 1];
    go(i + 1, acc, -1);
    for (var u = same ? minForSame + 1 : 0; u < n; u++) {
      if (acc.containsKey(u)) continue;
      acc[u] = items[i];
      go(i + 1, acc, u);
      acc.remove(u);
    }
  }

  go(0, {}, -1);
  return out;
}

class _Setup {
  final List<UnitSetup> loadout;
  RunResult? result;
  _Setup(this.loadout);
}

SolverReport solve(MissionScene s, {int cap = 260, bool tryAbilities = true}) {
  final k = s.teamSize < s.allowedRoles.length
      ? s.teamSize
      : s.allowedRoles.length;
  final teams = combinations(s.allowedRoles, k);
  final places = placements(s.deploy, k);
  final gears = gearAssignments(s.gear, k);
  final perTeam = places.length * gears.length;
  final budget = (cap ~/ teams.length).clamp(1, perTeam);
  final setups = <_Setup>[];
  for (final team in teams) {
    final step = perTeam ~/ budget;
    for (var i = 0; i < budget; i++) {
      final idx = (i * step + (i * 7919) % (step == 0 ? 1 : step)) % perTeam;
      final p = places[idx % places.length];
      final g = gears[idx ~/ places.length];
      setups.add(
        _Setup([
          for (var u = 0; u < k; u++) UnitSetup(team[u], p[u], gear: g[u]),
        ]),
      );
    }
  }
  for (final st in setups) {
    st.result = runMission(s, st.loadout, failFast: true);
  }
  final wins = setups.where((x) => x.result!.won).toList();
  var needsFocus = false;
  var needsAbility = false;
  final extraWins = <(List<UnitSetup>, List<Command>, RunResult)>[];

  if (wins.isEmpty) {
    // Priorities: one responder at a time switches focus.
    final ranked = [...setups]
      ..sort(
        (a, b) => b.result!.objectivesMet.compareTo(a.result!.objectivesMet),
      );
    var budgetFocus = 320;
    outer:
    for (final st in ranked.take(40)) {
      for (var u = 0; u < k; u++) {
        for (final f in Focus.values.skip(1)) {
          if (budgetFocus-- <= 0) break outer;
          final lo = [
            for (var i = 0; i < k; i++)
              i == u ? st.loadout[i].copyWith(focus: f) : st.loadout[i],
          ];
          final r = runMission(s, lo, failFast: true);
          if (r.won) extraWins.add((lo, const [], r));
        }
      }
    }
    needsFocus = extraWins.isNotEmpty;
  }

  if (wins.isEmpty &&
      extraWins.isEmpty &&
      tryAbilities &&
      s.rules.abilityCharges > 0) {
    final ranked = [...setups]
      ..sort(
        (a, b) => b.result!.objectivesMet.compareTo(a.result!.objectivesMet),
      );
    for (final st in ranked.take(24)) {
      for (final c in abilityCandidates(s, st.loadout)) {
        final r = runMission(s, st.loadout, commands: [c], failFast: true);
        if (r.won) extraWins.add((st.loadout, [c], r));
      }
      if (extraWins.length >= 3) break;
    }
    needsAbility = extraWins.isNotEmpty;
  }

  final all = <(List<UnitSetup>, List<Command>, RunResult)>[
    for (final w in wins) (w.loadout, const <Command>[], w.result!),
    ...extraWins,
  ];
  all.sort((a, b) {
    final c = a.$3.ticks.compareTo(b.$3.ticks);
    return c != 0 ? c : a.$2.length.compareTo(b.$2.length);
  });
  final ticks = [for (final w in all) w.$3.ticks]..sort();
  final teamsWon = {
    for (final w in all)
      (w.$1.map((u) => u.role.index).toList()..sort()).join(','),
  };
  final best = all.isEmpty ? null : all.first;
  return SolverReport(
    failures: [
      for (final st in setups.where((x) => !x.result!.won).take(3)) st.loadout,
    ],
    tried: setups.length,
    won: wins.length,
    best: best == null
        ? null
        : Witness(best.$1, best.$2, best.$3.ticks, best.$3.hash),
    bestTicks: best?.$3.ticks ?? 0,
    medianWinTicks: ticks.isEmpty ? 0 : ticks[ticks.length ~/ 2],
    winningTeams: teamsWon.length,
    needsAbility: needsAbility,
    needsFocus: needsFocus,
  );
}

/// Distinct (tick, unit, target) ability uses worth trying for a loadout.
List<Command> abilityCandidates(
  MissionScene s,
  List<UnitSetup> loadout, {
  int max = 36,
}) {
  final sim = Simulation(s, loadout, failFast: true);
  final seen = <String>{};
  final out = <Command>[];
  while (sim.running && out.length < max) {
    if (sim.tick >= deployTicks && sim.tick % 10 == 0) {
      for (var u = 0; u < sim.units.length; u++) {
        final type = loadout[u].role.def.ability.target;
        for (final t in sim.abilityTargets(u)) {
          final key = t == 'self' ? '$u:self:${sim.tick ~/ 60}' : '$u:$t';
          if (seen.add(key)) {
            out.add(
              Command(
                sim.tick,
                CommandType.ability,
                u,
                type == AbilityTarget.self ? null : t,
              ),
            );
          }
        }
      }
    }
    sim.step();
  }
  return out;
}

/// Headless mission runs used by replay, solver, validator and tests.
library;

import 'engine.dart';
import 'roles.dart';
import 'scene.dart';

class RunResult {
  final Outcome outcome;
  final int ticks;
  final List<SimEvent> events;
  final String hash;
  final int stars;
  final String failReason;
  final List<String> hints;
  final int abilitiesUsed;
  final int objectivesMet;
  const RunResult(
    this.outcome,
    this.ticks,
    this.events,
    this.hash,
    this.stars,
    this.failReason,
    this.hints,
    this.abilitiesUsed,
    this.objectivesMet,
  );
  bool get won => outcome == Outcome.won;
}

/// 32-bit FNV-1a over the encoded event log.
String eventHash(Iterable<SimEvent> events) {
  var h = 0x811c9dc5;
  for (final e in events) {
    for (final c in e.encode().codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xffffffff;
    }
    h ^= 0x0a;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

int starsFor(MissionScene s, Outcome o, int ticks) {
  if (o != Outcome.won) return 0;
  if (s.goldTicks > 0 && ticks <= s.goldTicks) return 3;
  if (s.parTicks > 0 && ticks <= s.parTicks) return 2;
  return 1;
}

/// Checks a player's team against the mission's rules. Null when valid.
String? validateLoadout(MissionScene s, List<UnitSetup> loadout) {
  if (loadout.isEmpty) return 'Choose at least one responder.';
  if (loadout.length > s.teamSize)
    return 'This call allows ${s.teamSize} responders.';
  final roles = <Role>{};
  for (final u in loadout) {
    if (!s.allowedRoles.contains(u.role))
      return '${u.role.name} is not available for this call.';
    if (!roles.add(u.role)) return 'Each responder can only be sent once.';
  }
  final used = <String, int>{};
  for (final u in loadout) {
    final zone = s.deploy.where((d) => d.node == u.node);
    if (zone.isEmpty) return 'Place every responder on a start zone.';
    used[u.node] = (used[u.node] ?? 0) + 1;
    if (used[u.node]! > zone.first.capacity)
      return 'Too many responders on one start zone.';
  }
  final pool = <Gear, int>{};
  for (final g in s.gear) {
    pool[g] = (pool[g] ?? 0) + 1;
  }
  for (final u in loadout) {
    if (u.gear == null) continue;
    pool[u.gear!] = (pool[u.gear!] ?? 0) - 1;
    if (pool[u.gear!]! < 0)
      return 'Not enough ${u.gear!.name} for everyone who asked.';
  }
  return null;
}

RunResult runMission(
  MissionScene scene,
  List<UnitSetup> loadout, {
  List<Command> commands = const [],
  bool failFast = false,
}) {
  final sim = Simulation(scene, loadout, failFast: failFast);
  final pending = [...commands]..sort((a, b) => a.tick.compareTo(b.tick));
  var i = 0;
  while (sim.running) {
    while (i < pending.length && pending[i].tick <= sim.tick) {
      final c = pending[i++];
      sim.issue(c);
    }
    sim.step();
  }
  final ticks = sim.tick;
  return RunResult(
    sim.outcome,
    ticks,
    sim.events,
    eventHash(sim.events),
    starsFor(scene, sim.outcome, ticks),
    sim.failReason,
    sim.failHints,
    sim.abilitiesUsed,
    sim.objectives.where((o) => o == ObjState.met).length,
  );
}

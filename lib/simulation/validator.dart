/// Static content checks, witness replay and near-duplicate detection.
library;

import 'engine.dart';
import 'progression.dart';
import 'roles.dart';
import 'run.dart';
import 'scene.dart';

class Issue {
  final String mission;
  final bool error;
  final String message;
  const Issue(this.mission, this.message, {this.error = true});
  @override
  String toString() => '${error ? 'ERROR' : 'warn '} $mission: $message';
}

List<Issue> staticCheck(MissionScene s) {
  final out = <Issue>[];
  void err(String m) => out.add(Issue(s.id, m));
  void warn(String m) => out.add(Issue(s.id, m, error: false));
  final ids = <String>{};
  for (final n in s.nodes) {
    if (!ids.add(n.id)) err('duplicate node ${n.id}');
    if (n.x < 20 || n.x > 780 || n.y < 20 || n.y > 1020)
      err('node ${n.id} outside the play area');
  }
  final nodeIds = {for (final n in s.nodes) n.id};
  final pairs = <String>{};
  final edgeIds = <String>{};
  for (final e in s.edges) {
    if (!edgeIds.add(e.id)) err('duplicate edge ${e.id}');
    if (!nodeIds.contains(e.a) || !nodeIds.contains(e.b))
      err('edge ${e.id} references a missing node');
    if (e.a == e.b) err('edge ${e.id} is a loop');
    final key = ([e.a, e.b]..sort()).join('-');
    if (!pairs.add(key)) err('two lanes join ${e.a} and ${e.b}');
    if (e.block == Block.power || e.block == Block.jam) {
      final l = s.nodes.where((n) => n.id == e.link);
      if (l.isEmpty)
        err(
          'edge ${e.id} needs a valid ${e.block == Block.power ? 'panel' : 'relay'} link',
        );
      if (l.isNotEmpty &&
          l.first.kind !=
              (e.block == Block.power ? NodeKind.panel : NodeKind.relay)) {
        err(
          'edge ${e.id} links to ${e.link} which is not a ${e.block.name} control',
        );
      }
    }
    if (e.label.isEmpty && e.block != Block.none)
      warn('blocked edge ${e.id} has no label for the event log');
  }
  if (s.teamSize < 1 || s.teamSize > 4)
    err('team size ${s.teamSize} outside 1-4');
  if (s.allowedRoles.length < s.teamSize)
    err('fewer allowed responders than team slots');
  final owned = rolesUnlockedAt(missionNumber(s.id));
  for (final r in s.allowedRoles) {
    if (!owned.contains(r))
      err('${r.name} is not unlocked by ${s.id}: not free-player solvable');
  }
  final gearOk = gearUnlockedAt(missionNumber(s.id));
  for (final g in s.gear) {
    if (!gearOk.contains(g)) err('${g.name} is not earned by ${s.id}');
  }
  final cap = s.deploy.fold(0, (a, d) => a + d.capacity);
  if (cap < s.teamSize)
    err('start zones hold $cap responders but team size is ${s.teamSize}');
  for (final d in s.deploy) {
    if (!nodeIds.contains(d.node)) err('start zone ${d.node} missing');
  }
  // Connectivity ignoring blockers and terrain: the map must be one place.
  final adj = <String, List<String>>{for (final n in nodeIds) n: []};
  for (final e in s.edges) {
    adj[e.a]?.add(e.b);
    adj[e.b]?.add(e.a);
  }
  if (s.nodes.isNotEmpty) {
    final seen = <String>{s.nodes.first.id};
    final st = [s.nodes.first.id];
    while (st.isNotEmpty) {
      for (final m in adj[st.removeLast()]!) {
        if (seen.add(m)) st.add(m);
      }
    }
    if (seen.length != nodeIds.length)
      err('map has disconnected parts: ${nodeIds.difference(seen).join(',')}');
  }
  for (final c in s.civilians) {
    if (!nodeIds.contains(c.node)) err('civilian ${c.id} on missing node');
  }
  final escortNeeded = s.objectives.any(
    (o) => o.type == ObjectiveType.civiliansSafe,
  );
  if (escortNeeded && s.shelters.isEmpty)
    err('evacuation objective without a shelter');
  final need = s.needs.fold(0, (a, n) => a + n.count);
  final stock = s.depots.fold(0, (a, d) => a + d.stock);
  if (need > stock) err('needs $need supplies but depots hold $stock');
  for (final h in s.hazards) {
    if (h.at <= 0 || h.at >= s.rules.tickLimit)
      err('hazard at tick ${h.at} outside the mission');
    if (h.edge != null && !edgeIds.contains(h.edge))
      err('hazard references missing edge ${h.edge}');
    if (h.to != null && !nodeIds.contains(h.to))
      err('hazard references missing node ${h.to}');
    if ((h.type == HazardType.surge || h.type == HazardType.jam) &&
        !nodeIds.contains(h.link)) {
      err('${h.type.name} hazard needs a valid link');
    }
  }
  for (final o in s.objectives) {
    if (o.by > 0 &&
        s.tutorial.isEmpty &&
        !s.brief.toLowerCase().contains('before')) {
      err('deadline objective must be explained in the brief or tutorial');
    }
    switch (o.type) {
      case ObjectiveType.civiliansSafe:
        if (o.count < 1 || o.count > s.civilians.length)
          err('civiliansSafe count ${o.count} invalid');
      case ObjectiveType.stabilized:
        if (!s.civilians.any((c) => c.id == o.target && c.needsCare))
          err('stabilized target ${o.target} invalid');
      case ObjectiveType.routeOpen:
        if (!nodeIds.contains(o.a) || !nodeIds.contains(o.b))
          err('routeOpen endpoints invalid');
      case ObjectiveType.delivered:
        if (!s.needs.any((n) => n.id == o.target))
          err('delivered target ${o.target} invalid');
      case ObjectiveType.panelSafe:
        if (!s.nodes.any((n) => n.id == o.target && n.kind == NodeKind.panel))
          err('panel ${o.target} invalid');
      case ObjectiveType.shelterOpen:
        if (!s.shelters.any((x) => x.node == o.target))
          err('shelter ${o.target} invalid');
      case ObjectiveType.protect:
        if (o.nodes.isEmpty || !o.nodes.every(nodeIds.contains))
          err('protect nodes invalid');
      case ObjectiveType.revealed:
        if (o.nodes.isEmpty || !o.nodes.every(edgeIds.contains))
          err('revealed edges invalid');
      case ObjectiveType.contained:
        if (s.fires.isEmpty) err('containment objective without a fire');
    }
  }
  if (s.objectives.isEmpty) err('no objectives');
  // Every obstacle type must be solvable by someone this mission offers.
  bool offered(bool Function(Role, Gear?) f) =>
      s.allowedRoles.any((r) => f(r, null) || s.gear.any((g) => f(r, g)));
  bool can(JobKind k) => offered((r, g) => baseWorkTicks(r, g, k) != null);
  for (final e in s.edges) {
    final ok = switch (e.block) {
      Block.none => true,
      Block.debris => can(JobKind.clearDebris),
      Block.heavy => can(JobKind.clearHeavy),
      Block.dark => can(JobKind.reveal),
      Block.power => can(JobKind.shutdown),
      Block.jam => can(JobKind.signal),
    };
    if (!ok) warn('nobody offered can clear ${e.block.name} on ${e.id}');
    if (e.terrain == Terrain.gap &&
        !can(JobKind.bridgeGap) &&
        !s.allowedRoles.contains(Role.heavyEngineer)) {
      warn('gap ${e.id} cannot be bridged by the offered team');
    }
  }
  if (s.civilians.any((c) => c.needsCare) && !can(JobKind.stabilize))
    err('care needed but nobody offered can give it');
  if (s.civilians.isNotEmpty && !s.allowedRoles.any((r) => r.def.escort))
    err('nobody offered can escort');
  if (s.needs.isNotEmpty && !can(JobKind.deliver))
    err('nobody offered can carry supplies');
  if (s.fires.isNotEmpty && !can(JobKind.extinguish))
    err('nobody offered can contain fire');
  if (s.goldTicks > s.parTicks) err('3-star time is slower than 2-star time');
  if (s.title.isEmpty || s.brief.length < 30)
    err('missing player-facing title or brief');
  return out;
}

/// Replays the stored witness under release rules (no upgrades).
List<Issue> verifyWitness(MissionScene s) {
  final w = s.witness;
  if (w == null) return [Issue(s.id, 'no solution witness')];
  final out = <Issue>[];
  if (w.loadout.any((u) => u.upgrades != Upgrades.none))
    out.add(Issue(s.id, 'witness uses upgrades'));
  final lo = validateLoadout(s, w.loadout);
  if (lo != null) out.add(Issue(s.id, 'witness loadout invalid: $lo'));
  final r = runMission(s, w.loadout, commands: w.commands);
  if (!r.won) out.add(Issue(s.id, 'witness does not win: ${r.failReason}'));
  if (r.hash != w.hash)
    out.add(
      Issue(
        s.id,
        'witness hash ${r.hash} != recorded ${w.hash} (non-deterministic or stale)',
      ),
    );
  if (r.ticks != w.ticks)
    out.add(Issue(s.id, 'witness ticks ${r.ticks} != recorded ${w.ticks}'));
  if (s.goldTicks > 0 && r.ticks > s.parTicks)
    out.add(Issue(s.id, 'witness slower than 2-star time', error: false));
  final fast = runMission(s, w.loadout, commands: w.commands, failFast: true);
  if (fast.outcome != Outcome.won)
    out.add(Issue(s.id, 'witness only wins with stall grace'));
  return out;
}

/// Structural fingerprint: counts of features and objective/hazard mix.
String signature(MissionScene s) {
  final parts = <String>[
    'n${s.nodes.length}',
    'e${s.edges.length}',
    for (final b in Block.values)
      '${b.name}${s.edges.where((e) => e.block == b).length}',
    for (final t in Terrain.values)
      '${t.name}${s.edges.where((e) => e.terrain == t).length}',
    'c${s.civilians.length}',
    'f${s.fires.length}',
    'd${s.needs.length}',
    ...(s.objectives.map((o) => o.type.name).toList()..sort()),
    ...(s.hazards.map((h) => h.type.name).toList()..sort()),
  ];
  return parts.join('|');
}

double _layoutDistance(MissionScene a, MissionScene b) {
  var total = 0.0;
  for (final n in a.nodes) {
    var best = 1e9;
    for (final m in b.nodes) {
      final dx = (n.x - m.x).toDouble(), dy = (n.y - m.y).toDouble();
      final d = dx * dx + dy * dy;
      if (d < best) best = d;
    }
    total += best;
  }
  return total / a.nodes.length;
}

/// Flags missions whose layout and rules nearly match another mission.
List<Issue> duplicateCheck(List<MissionScene> all) {
  final out = <Issue>[];
  final sigs = {for (final s in all) s.id: signature(s)};
  for (var i = 0; i < all.length; i++) {
    for (var j = i + 1; j < all.length; j++) {
      final a = all[i], b = all[j];
      if ((a.nodes.length - b.nodes.length).abs() > 1) continue;
      final layout = _layoutDistance(a, b) + _layoutDistance(b, a);
      final sameRules = sigs[a.id] == sigs[b.id];
      // 30 world units RMS per node is visually the same map.
      if (layout < 2 * 30 * 30 &&
          (sameRules || a.edges.length == b.edges.length)) {
        out.add(Issue(b.id, 'near-duplicate layout of ${a.id}'));
      } else if (sameRules && layout < 2 * 60 * 60) {
        out.add(
          Issue(
            b.id,
            'very similar to ${a.id} (same rules, close layout)',
            error: false,
          ),
        );
      }
    }
  }
  return out;
}

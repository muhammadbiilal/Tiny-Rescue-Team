/// Deterministic fixed-tick rescue simulation. All math is integer so a
/// witness replays identically on every platform.
library;

import 'roles.dart';
import 'scene.dart';

/// Simulation tick length. Rendering interpolates between ticks.
const int tickMs = 100;

/// Responders play their deploy animation before acting.
const int deployTicks = 6;

/// Ticks the team may sit with nothing to do before the mission fails.
const int stallGraceTicks = 40;

enum EventType {
  deploy,
  claim,
  workStart,
  workDone,
  blocked,
  pickUp,
  dropOff,
  waiting,
  pickSupplies,
  delivered,
  stabilized,
  revealed,
  cleared,
  bridged,
  spanEnd,
  shutdown,
  signaled,
  repaired,
  extinguished,
  fireReduced,
  spread,
  spreadHeld,
  flooded,
  collapse,
  surge,
  wind,
  jam,
  shelterOpen,
  civilianFound,
  civilianLost,
  displaced,
  rest,
  restEnd,
  ability,
  redirect,
  commandRejected,
  objectiveMet,
  stall,
  win,
  fail,
}

class SimEvent {
  /// Stable per-run sequence number, shown as E0001 in diagnostics.
  final int id;
  final int tick;
  final EventType type;

  /// Responder index or -1.
  final int unit;
  final String subject;
  final String detail;
  const SimEvent(
    this.id,
    this.tick,
    this.type,
    this.unit,
    this.subject,
    this.detail,
  );

  String get key => 'E${id.toString().padLeft(4, '0')}';
  String encode() => '$tick|${type.name}|$unit|$subject|$detail';
  @override
  String toString() => '$key ${encode()}';
}

enum Activity { idle, moving, working, waiting, resting }

enum Outcome { running, won, failed }

enum ObjState { pending, met, failed }

class Job {
  final String id;
  final JobKind kind;

  /// Edge id, civilian id, need id, panel/relay/shelter node or fire node.
  final String subject;
  final bool critical;
  final bool relevant;
  final int intensity;
  const Job(
    this.id,
    this.kind,
    this.subject, {
    this.critical = false,
    this.relevant = true,
    this.intensity = 1,
  });
}

class UnitState {
  final int index;
  final UnitSetup setup;
  String at;
  String? edge;
  String? to;
  int edgeProgress = 0;
  int edgeLen = 0;
  List<String> path = [];
  Activity activity = Activity.idle;
  String? job;
  JobKind? jobKind;

  /// 0: travelling to first work node; 1: second leg (escort drop, delivery).
  int stage = 0;
  String? target;
  int workDone = 0;
  int workNeeded = 0;
  String? carryingCivilian;
  String? carryNeed;
  int carrying = 0;
  int claimed = 0;
  int jobsDone = 0;
  int restUntil = 0;
  bool abilityUsed = false;
  int swiftUntil = 0;
  int decidedAtVersion = -1;
  String? pendingJob;
  int x, y;
  int prevX, prevY;
  UnitState(this.index, this.setup, this.at, this.x, this.y)
    : prevX = x,
      prevY = y;

  Role get role => setup.role;
  Gear? get gear => setup.gear;
}

class CivState {
  final Civilian def;
  String node;
  bool known;
  bool stabilized;
  bool safe = false;
  bool lost = false;
  int carriedBy = -1;
  String? shelter;
  CivState(this.def)
    : node = def.node,
      known = !def.hidden,
      stabilized = !def.needsCare;
}

class ShelterState {
  final Shelter def;
  int count = 0;
  bool broken;
  ShelterState(this.def) : broken = def.broken;
  bool openAt(int tick) => tick >= def.openAt;
  bool hasRoom() => def.capacity == 0 || count < def.capacity;
}

class Simulation {
  final MissionScene scene;
  final List<UnitSetup> loadout;

  /// Solver mode: fail at the first stall instead of waiting for the player.
  final bool failFast;

  final Map<String, SceneNode> nodes = {};
  final Map<String, SceneEdge> edgeDefs = {};
  final Map<String, List<String>> adjacency = {};
  final Map<String, int> edgeLength = {};
  final Map<String, Block> block = {};
  final Map<String, Terrain> terrain = {};
  final Map<String, String?> link = {};
  final Set<String> bridged = {};
  final Map<String, int> spannedUntil = {};
  final Map<String, int> fires = {};
  final Set<String> everBurned = {};
  final Map<String, CivState> civilians = {};
  final Map<String, ShelterState> shelters = {};
  final Map<String, int> depotStock = {};
  final Map<String, int> delivered = {};
  final Map<String, int> inTransit = {};
  final Set<String> panelsOff = {};
  final Set<String> relaysOn = {};
  final Map<String, int> jobProgress = {};
  final Set<String> routeEdges = {};
  final List<UnitState> units = [];
  final List<SimEvent> events = [];
  final List<Command> _queued = [];
  final List<ObjState> objectives;
  final List<bool> _everMet;

  int tick = 0;
  int version = 0;
  int abilitiesUsed = 0;
  int redirectsUsed = 0;
  Outcome outcome = Outcome.running;
  String failReason = '';
  List<String> failHints = const [];
  int _stallSince = -1;
  int _hazardCursor = 0;
  late final List<HazardEvent> _hazards;

  Simulation(this.scene, this.loadout, {this.failFast = false})
    : objectives = List.filled(scene.objectives.length, ObjState.pending),
      _everMet = List.filled(scene.objectives.length, false) {
    for (final n in scene.nodes) {
      nodes[n.id] = n;
      adjacency[n.id] = [];
    }
    for (final e in scene.edges) {
      edgeDefs[e.id] = e;
      adjacency[e.a]!.add(e.id);
      adjacency[e.b]!.add(e.id);
      edgeLength[e.id] = _dist(
        nodes[e.a]!.x,
        nodes[e.a]!.y,
        nodes[e.b]!.x,
        nodes[e.b]!.y,
      );
      block[e.id] = e.block;
      terrain[e.id] = e.terrain;
      link[e.id] = e.link;
    }
    for (final list in adjacency.values) {
      list.sort();
    }
    for (final f in scene.fires) {
      fires[f.node] = f.intensity;
      everBurned.add(f.node);
    }
    for (final c in scene.civilians) {
      civilians[c.id] = CivState(c);
    }
    for (final s in scene.shelters) {
      shelters[s.node] = ShelterState(s);
    }
    for (final d in scene.depots) {
      depotStock[d.node] = d.stock;
    }
    for (final n in scene.needs) {
      delivered[n.id] = 0;
      inTransit[n.id] = 0;
    }
    _hazards = [...scene.hazards]..sort((a, b) => a.at.compareTo(b.at));
    for (final o in scene.objectives) {
      if (o.type == ObjectiveType.routeOpen)
        routeEdges.addAll(_idealRoute(o.a!, o.b!));
    }
    for (var i = 0; i < loadout.length; i++) {
      final s = loadout[i];
      final n = nodes[s.node]!;
      units.add(UnitState(i, s, s.node, n.x, n.y));
      _emit(EventType.deploy, i, s.node, s.role.name);
    }
  }

  // ---------------------------------------------------------------- queries

  bool get running => outcome == Outcome.running;
  int get chargesLeft => scene.rules.abilityCharges - abilitiesUsed;
  int get redirectsLeft => scene.rules.redirects - redirectsUsed;
  int get civiliansSafe => civilians.values.where((c) => c.safe).length;

  static int _dist(int ax, int ay, int bx, int by) {
    final dx = ax - bx, dy = ay - by;
    return _isqrt(dx * dx + dy * dy);
  }

  static int _isqrt(int v) {
    if (v <= 0) return 0;
    var x = v, y = (x + 1) ~/ 2;
    while (y < x) {
      x = y;
      y = (x + v ~/ x) ~/ 2;
    }
    return x;
  }

  String other(String edgeId, String node) {
    final e = edgeDefs[edgeId]!;
    return e.a == node ? e.b : e.a;
  }

  String? edgeBetween(String a, String b) {
    for (final e in adjacency[a]!) {
      if (other(e, a) == b) return e;
    }
    return null;
  }

  (int, int) edgeMid(String edgeId) {
    final e = edgeDefs[edgeId]!;
    final a = nodes[e.a]!, b = nodes[e.b]!;
    return ((a.x + b.x) ~/ 2, (a.y + b.y) ~/ 2);
  }

  bool gapOpen(String e) =>
      bridged.contains(e) || (spannedUntil[e] ?? -1) > tick;

  /// Whether a plain walker (no boat) could use this lane right now.
  bool walkable(String e) {
    if (block[e] != Block.none) return false;
    if (terrain[e] == Terrain.water) return false;
    if (terrain[e] == Terrain.gap && !gapOpen(e)) return false;
    final d = edgeDefs[e]!;
    return !fires.containsKey(d.a) && !fires.containsKey(d.b);
  }

  bool passable(UnitState u, String e) {
    if (block[e] != Block.none) return false;
    final t = terrain[e]!;
    if (t == Terrain.water && u.role.def.waterSpeed == 0) return false;
    if (t == Terrain.gap && !gapOpen(e)) return false;
    final d = edgeDefs[e]!;
    return !fires.containsKey(d.a) && !fires.containsKey(d.b);
  }

  /// Centi-units per tick.
  int speedOn(UnitState u, String e) {
    final def = u.role.def;
    final base = terrain[e] == Terrain.water ? def.waterSpeed : def.speed;
    var s = base * (100 + u.setup.upgrades.speedPct);
    if (u.carryingCivilian != null && terrain[e] != Terrain.water)
      s = s * 3 ~/ 4;
    if (u.swiftUntil > tick) s = s * 9 ~/ 5;
    return s;
  }

  int travelTicks(UnitState u, String e) {
    final s = speedOn(u, e);
    return (edgeLength[e]! * 100 + s - 1) ~/ s;
  }

  /// Dijkstra over lanes this responder may use. Returns (cost, prev-edge).
  (Map<String, int>, Map<String, String>) reach(UnitState u, String from) {
    final dist = <String, int>{from: 0};
    final prev = <String, String>{};
    final done = <String>{};
    while (true) {
      String? best;
      var bestD = 1 << 40;
      for (final e in dist.entries) {
        if (done.contains(e.key)) continue;
        if (e.value < bestD ||
            (e.value == bestD && best != null && e.key.compareTo(best) < 0)) {
          best = e.key;
          bestD = e.value;
        }
      }
      if (best == null) break;
      done.add(best);
      for (final e in adjacency[best]!) {
        if (!passable(u, e)) continue;
        final n = other(e, best);
        final nd = bestD + travelTicks(u, e);
        final cur = dist[n];
        if (cur == null || nd < cur) {
          dist[n] = nd;
          prev[n] = e;
        }
      }
    }
    return (dist, prev);
  }

  List<String> _pathTo(Map<String, String> prev, String from, String to) {
    final out = <String>[];
    var cur = to;
    while (cur != from) {
      out.add(cur);
      cur = other(prev[cur]!, cur);
    }
    return out.reversed.toList();
  }

  /// Land route ignoring blockers; used to know which lanes a route objective cares about.
  List<String> _idealRoute(String a, String b) {
    final dist = <String, int>{a: 0};
    final prev = <String, String>{};
    final done = <String>{};
    while (true) {
      String? best;
      var bestD = 1 << 40;
      for (final e in dist.entries) {
        if (!done.contains(e.key) &&
            (e.value < bestD ||
                (e.value == bestD && e.key.compareTo(best!) < 0))) {
          best = e.key;
          bestD = e.value;
        }
      }
      if (best == null) break;
      done.add(best);
      for (final e in adjacency[best]!) {
        if (terrain[e] == Terrain.water) continue;
        final n = other(e, best);
        final nd = bestD + edgeLength[e]!;
        if (dist[n] == null || nd < dist[n]!) {
          dist[n] = nd;
          prev[n] = e;
        }
      }
    }
    if (!dist.containsKey(b)) return const [];
    final out = <String>[];
    var cur = b;
    while (cur != a) {
      out.add(prev[cur]!);
      cur = other(prev[cur]!, cur);
    }
    return out;
  }

  bool walkerConnected(String a, String b) {
    if (fires.containsKey(a) || fires.containsKey(b)) return false;
    final seen = <String>{a};
    final stack = [a];
    while (stack.isNotEmpty) {
      final n = stack.removeLast();
      if (n == b) return true;
      for (final e in adjacency[n]!) {
        if (!walkable(e)) continue;
        final m = other(e, n);
        if (seen.add(m)) stack.add(m);
      }
    }
    return false;
  }

  // ------------------------------------------------------------------ events

  void _emit(EventType t, int unit, String subject, [String detail = '']) {
    events.add(SimEvent(events.length + 1, tick, t, unit, subject, detail));
  }

  void _changed() => version++;

  // ------------------------------------------------------------------- jobs

  Set<String> _teamReach() {
    final out = <String>{};
    for (final u in units) {
      if (u.edge != null) {
        out.add(u.at);
        out.add(u.to!);
      }
      final start = u.edge == null ? u.at : u.to!;
      out.addAll(reach(u, start).$1.keys);
    }
    return out;
  }

  List<Job> jobs() {
    final out = <Job>[];
    final teamReach = _teamReach();
    bool frontier(String e) {
      final d = edgeDefs[e]!;
      return routeEdges.contains(e) ||
          (teamReach.contains(d.a) != teamReach.contains(d.b));
    }

    final panelJobs = <String>{};
    final relayJobs = <String>{};
    for (final e in scene.edges) {
      final b = block[e.id]!;
      switch (b) {
        case Block.none:
          break;
        case Block.debris:
          out.add(
            Job(
              'clear:${e.id}',
              JobKind.clearDebris,
              e.id,
              relevant: frontier(e.id),
            ),
          );
        case Block.heavy:
          out.add(
            Job(
              'heavy:${e.id}',
              JobKind.clearHeavy,
              e.id,
              relevant: frontier(e.id),
            ),
          );
        case Block.dark:
          out.add(Job('reveal:${e.id}', JobKind.reveal, e.id));
        case Block.power:
          if (link[e.id] != null) panelJobs.add(link[e.id]!);
        case Block.jam:
          if (link[e.id] != null) relayJobs.add(link[e.id]!);
      }
      if (terrain[e.id] == Terrain.gap && !bridged.contains(e.id)) {
        out.add(
          Job(
            'bridge:${e.id}',
            JobKind.bridgeGap,
            e.id,
            relevant: frontier(e.id),
          ),
        );
      }
    }
    for (final p in panelJobs.toList()..sort()) {
      out.add(Job('shutdown:$p', JobKind.shutdown, p));
    }
    for (final r in relayJobs.toList()..sort()) {
      out.add(Job('signal:$r', JobKind.signal, r));
    }
    for (final f in (fires.keys.toList()..sort())) {
      out.add(Job('fire:$f', JobKind.extinguish, f, intensity: fires[f]!));
    }
    for (final c in civilians.values) {
      if (!c.known || c.safe || c.lost || c.carriedBy >= 0) continue;
      if (!c.stabilized) {
        out.add(
          Job(
            'care:${c.def.id}',
            JobKind.stabilize,
            c.def.id,
            critical: c.def.critical,
          ),
        );
      } else {
        out.add(
          Job(
            'escort:${c.def.id}',
            JobKind.escort,
            c.def.id,
            critical: c.def.critical,
          ),
        );
      }
    }
    for (final n in scene.needs) {
      if (n.count - delivered[n.id]! - inTransit[n.id]! > 0) {
        out.add(Job('deliver:${n.id}', JobKind.deliver, n.id));
      }
    }
    for (final s in shelters.values) {
      if (s.broken)
        out.add(Job('repair:${s.def.node}', JobKind.repair, s.def.node));
    }
    return out;
  }

  Job? jobById(String id) {
    for (final j in jobs()) {
      if (j.id == id) return j;
    }
    return null;
  }

  bool claimedByOther(String jobId, int unit) {
    if (jobId.startsWith('deliver:')) return false;
    for (final u in units) {
      if (u.index != unit && u.job == jobId) return true;
    }
    return false;
  }

  int? workTicksFor(UnitState u, Job j) {
    final base = baseWorkTicks(u.role, u.gear, j.kind);
    if (base == null) return null;
    if (j.kind == JobKind.extinguish) {
      if (u.role != Role.fireSpecialist &&
          j.intensity > extinguisherMaxIntensity)
        return null;
      return base * j.intensity;
    }
    return base;
  }

  int _needed(UnitState u, int ticks) =>
      ticks * (100 - u.setup.upgrades.workCutPct);

  /// Nodes from which [u] can perform [j].
  List<String> workNodes(UnitState u, Job j) {
    switch (j.kind) {
      case JobKind.clearDebris:
      case JobKind.clearHeavy:
      case JobKind.bridgeGap:
        final e = edgeDefs[j.subject]!;
        return [e.a, e.b];
      case JobKind.reveal:
        final e = edgeDefs[j.subject]!;
        if (u.role == Role.droneOperator) {
          final (mx, my) = edgeMid(j.subject);
          return [
            for (final n in scene.nodes)
              if (_dist(n.x, n.y, mx, my) <= droneRevealRange) n.id,
          ];
        }
        return [e.a, e.b];
      case JobKind.shutdown:
      case JobKind.signal:
      case JobKind.repair:
        return [j.subject];
      case JobKind.extinguish:
        return [
          for (final e in adjacency[j.subject]!)
            if (terrain[e] != Terrain.gap &&
                !fires.containsKey(other(e, j.subject)))
              other(e, j.subject),
        ];
      case JobKind.stabilize:
      case JobKind.escort:
        return [civilians[j.subject]!.node];
      case JobKind.deliver:
        return [
          for (final d in (depotStock.keys.toList()..sort()))
            if (depotStock[d]! > 0) d,
        ];
    }
  }

  int _priority(Job j) {
    final p = switch (j.kind) {
      JobKind.stabilize => j.critical ? 0 : 100,
      JobKind.escort => j.critical ? 60 : 150,
      JobKind.extinguish => 120,
      JobKind.shutdown => 200,
      JobKind.signal => 220,
      JobKind.repair => 230,
      JobKind.reveal => 240,
      JobKind.clearDebris || JobKind.clearHeavy || JobKind.bridgeGap => 260,
      JobKind.deliver => 300,
    };
    return j.relevant ? p : p + 4000;
  }

  /// Best (score, work node, path) for [u] doing [j], or null.
  (int, String, List<String>)? evaluate(
    UnitState u,
    Job j,
    (Map<String, int>, Map<String, String>) r,
  ) {
    final w = workTicksFor(u, j);
    if (w == null) return null;
    if (j.kind == JobKind.escort &&
        !_shelterReachableFrom(u, civilians[j.subject]!.node))
      return null;
    if (j.kind == JobKind.deliver) {
      final n = scene.needs.firstWhere((n) => n.id == j.subject);
      if (!reach(u, u.at).$1.containsKey(n.node) && !_reachableVia(u, n.node))
        return null;
    }
    String? bestNode;
    var bestCost = 1 << 40;
    for (final n in workNodes(u, j)) {
      final c = r.$1[n];
      if (c != null &&
          (c < bestCost || (c == bestCost && n.compareTo(bestNode!) < 0))) {
        bestCost = c;
        bestNode = n;
      }
    }
    if (bestNode == null) return null;
    var score = _priority(j) + bestCost + w;
    final focus = focusCategory(u.setup.focus);
    if (focus != null && categoryOf(j.kind) == focus) score -= 1000;
    return (score, bestNode, _pathTo(r.$2, u.at, bestNode));
  }

  bool _reachableVia(UnitState u, String node) {
    for (final d in depotStock.keys) {
      if (depotStock[d]! > 0 && reach(u, d).$1.containsKey(node)) return true;
    }
    return false;
  }

  bool _shelterReachableFrom(UnitState u, String node) {
    final r = reach(u, node).$1;
    for (final s in shelters.values) {
      if (r.containsKey(s.def.node) && (s.hasRoom() || s.def.capacity == 0))
        return true;
    }
    return false;
  }

  // --------------------------------------------------------------- commands

  /// Validates and queues a player command for the next tick.
  /// Returns null when accepted, else a player-facing reason.
  String? issue(Command c) {
    final reason = validate(c);
    if (reason == null) _queued.add(Command(tick, c.type, c.unit, c.target));
    return reason;
  }

  int abilityRange(UnitState u) {
    final r = u.role.def.ability.range;
    return r * (100 + u.setup.upgrades.abilityRangePct) ~/ 100;
  }

  bool _inRange(UnitState u, int x, int y) {
    final r = abilityRange(u);
    return r == 0 || _dist(u.x, u.y, x, y) <= r;
  }

  List<String> _darkWithin(int x, int y, int range) => [
    for (final e in scene.edges)
      if (block[e.id] == Block.dark &&
          _dist(edgeMid(e.id).$1, edgeMid(e.id).$2, x, y) <= range)
        e.id,
  ];

  /// Valid ability targets for responder [unit] right now.
  List<String> abilityTargets(int unit) {
    final u = units[unit];
    final a = u.role.def.ability;
    bool edgeIn(String e) => _inRange(u, edgeMid(e).$1, edgeMid(e).$2);
    bool nodeIn(String n) => _inRange(u, nodes[n]!.x, nodes[n]!.y);
    switch (a) {
      case Ability.rapidAccess:
        return [
          for (final e in scene.edges)
            if (block[e.id] == Block.debris && edgeIn(e.id)) e.id,
        ];
      case Ability.quickRepair:
        return [
          for (final e in scene.edges)
            if (block[e.id] == Block.debris && edgeIn(e.id)) e.id,
          for (final s in shelters.values)
            if (s.broken && nodeIn(s.def.node)) s.def.node,
        ];
      case Ability.triageFocus:
        return [
          for (final c in civilians.values)
            if (c.known && !c.stabilized && !c.lost && nodeIn(c.node)) c.def.id,
        ];
      case Ability.focusedSuppression:
        return [
          for (final f in fires.keys)
            if (nodeIn(f)) f,
        ];
      case Ability.safeShutdown:
        final out = <String>{};
        for (final e in scene.edges) {
          if (block[e.id] == Block.power && link[e.id] != null)
            out.add(link[e.id]!);
        }
        for (final h in _hazards.skip(_hazardCursor)) {
          if (h.type == HazardType.surge &&
              h.link != null &&
              !panelsOff.contains(h.link))
            out.add(h.link!);
        }
        return out.toList()..sort();
      case Ability.priorityDispatch:
        if (!depotStock.values.any((s) => s > 0)) return const [];
        return [
          for (final n in scene.needs)
            if (n.count - delivered[n.id]! - inTransit[n.id]! > 0) n.id,
        ];
      case Ability.temporarySpan:
        return [
          for (final e in scene.edges)
            if (terrain[e.id] == Terrain.gap && !gapOpen(e.id) && edgeIn(e.id))
              e.id,
        ];
      case Ability.revealZone:
        return [
          for (final n in scene.nodes)
            if (_darkWithin(n.x, n.y, a.range).isNotEmpty) n.id,
        ];
      case Ability.surveyPulse:
        return _darkWithin(u.x, u.y, abilityRange(u)).isEmpty
            ? const []
            : const ['self'];
      case Ability.rerouteOrder:
        final any = scene.edges.any(
          (e) =>
              block[e.id] == Block.jam &&
              _dist(edgeMid(e.id).$1, edgeMid(e.id).$2, u.x, u.y) <=
                  abilityRange(u),
        );
        return any ? const ['self'] : const [];
      case Ability.swiftCrossing:
        return const ['self'];
      case Ability.synchronize:
        return units.any((o) => o.activity == Activity.working)
            ? const ['self']
            : const [];
    }
  }

  String? validate(Command c) {
    if (!running) return 'The mission is over.';
    if (c.unit < 0 || c.unit >= units.length) return 'Unknown responder.';
    final u = units[c.unit];
    if (c.type == CommandType.ability) {
      if (tick < deployTicks) return 'The team is still deploying.';
      if (u.abilityUsed) return 'This responder already used their ability.';
      if (chargesLeft <= 0) return 'No ability charges left this mission.';
      final targets = abilityTargets(c.unit);
      if (targets.isEmpty)
        return 'Nothing in range for this ability right now.';
      final t = u.role.def.ability.target == AbilityTarget.self
          ? 'self'
          : c.target;
      if (!targets.contains(t))
        return 'That target is out of range or not affected.';
      return null;
    }
    if (redirectsLeft <= 0) return 'No redirect orders left this mission.';
    final j = c.target == null ? null : jobById(c.target!);
    if (j == null) return 'That task is no longer needed.';
    final start = u.edge == null ? u.at : u.to!;
    final w = workTicksFor(u, j);
    if (w == null) return 'This responder cannot do that task.';
    final r = reach(u, start);
    if (!workNodes(u, j).any(r.$1.containsKey))
      return 'No safe route to that task yet.';
    return null;
  }

  void _apply(Command c) {
    if (validate(c) != null) {
      _emit(EventType.commandRejected, c.unit, c.target ?? '', validate(c)!);
      return;
    }
    final u = units[c.unit];
    if (c.type == CommandType.redirect) {
      redirectsUsed++;
      for (final o in units) {
        if (o.index != u.index && o.job == c.target) _dropJob(o, 'reassigned');
      }
      _dropJob(u, '');
      _emit(EventType.redirect, u.index, c.target!);
      if (u.edge != null) {
        // Mid-lane responders finish the lane, then take the order.
        u.pendingJob = c.target;
        return;
      }
      _takeOrder(u, c.target!);
      return;
    }
    u.abilityUsed = true;
    abilitiesUsed++;
    final a = u.role.def.ability;
    _emit(EventType.ability, u.index, c.target ?? 'self', a.name);
    switch (a) {
      case Ability.rapidAccess:
      case Ability.quickRepair:
        if (shelters.containsKey(c.target)) {
          shelters[c.target]!.broken = false;
          _emit(EventType.repaired, u.index, c.target!);
        } else {
          block[c.target!] = Block.none;
          _emit(EventType.cleared, u.index, c.target!);
        }
      case Ability.triageFocus:
        civilians[c.target]!.stabilized = true;
        _emit(EventType.stabilized, u.index, c.target!);
      case Ability.surveyPulse:
        _revealAround(u.index, u.x, u.y, abilityRange(u));
      case Ability.swiftCrossing:
        u.swiftUntil = tick + 120;
      case Ability.safeShutdown:
        _shutdown(u.index, c.target!);
      case Ability.focusedSuppression:
        final left = fires[c.target]! - 2;
        if (left <= 0) {
          _extinguish(u.index, c.target!);
        } else {
          fires[c.target!] = left;
          _emit(EventType.fireReduced, u.index, c.target!, '$left');
          for (final o in units) {
            if (o.job == 'fire:${c.target}' && o.activity == Activity.working) {
              o.workNeeded = _needed(
                o,
                baseWorkTicks(o.role, o.gear, JobKind.extinguish)! * left,
              );
            }
          }
        }
      case Ability.priorityDispatch:
        final d = (depotStock.keys.toList()..sort()).firstWhere(
          (d) => depotStock[d]! > 0,
        );
        depotStock[d] = depotStock[d]! - 1;
        delivered[c.target!] = delivered[c.target]! + 1;
        _emit(EventType.delivered, u.index, c.target!, '1');
      case Ability.rerouteOrder:
        for (final e in scene.edges) {
          if (block[e.id] == Block.jam &&
              _dist(edgeMid(e.id).$1, edgeMid(e.id).$2, u.x, u.y) <=
                  abilityRange(u)) {
            block[e.id] = Block.none;
            _emit(EventType.cleared, u.index, e.id, 'jam');
          }
        }
      case Ability.revealZone:
        final n = nodes[c.target]!;
        _revealAround(u.index, n.x, n.y, a.range);
      case Ability.temporarySpan:
        spannedUntil[c.target!] = tick + 150;
        _emit(EventType.bridged, u.index, c.target!, 'temporary');
      case Ability.synchronize:
        for (final o in units) {
          if (o.activity == Activity.working) o.workDone += o.workNeeded ~/ 2;
        }
    }
    _changed();
  }

  void _takeOrder(UnitState u, String jobId) {
    u.pendingJob = null;
    final j = jobById(jobId);
    final ev = j == null ? null : evaluate(u, j, reach(u, u.at));
    if (j == null || ev == null) {
      _emit(
        EventType.commandRejected,
        u.index,
        jobId,
        'That task is no longer reachable.',
      );
      return;
    }
    for (final o in units) {
      if (o.index != u.index && o.job == jobId) _dropJob(o, 'reassigned');
    }
    _assign(u, j, ev.$2, ev.$3);
  }

  // ------------------------------------------------------------ job effects

  void _revealEdge(int unit, String e) {
    if (block[e] != Block.dark) return;
    block[e] = Block.none;
    _emit(EventType.revealed, unit, e);
    final d = edgeDefs[e]!;
    _discoverAt(d.a);
    _discoverAt(d.b);
  }

  void _revealAround(int unit, int x, int y, int range) {
    for (final e in _darkWithin(x, y, range)) {
      _revealEdge(unit, e);
    }
    for (final c in civilians.values) {
      final n = nodes[c.node]!;
      if (!c.known && _dist(n.x, n.y, x, y) <= range) _found(c);
    }
  }

  void _discoverAt(String node) {
    for (final c in civilians.values) {
      if (!c.known && c.node == node) _found(c);
    }
  }

  void _found(CivState c) {
    c.known = true;
    _emit(EventType.civilianFound, -1, c.def.id, c.node);
    _changed();
  }

  void _shutdown(int unit, String panel) {
    panelsOff.add(panel);
    for (final e in scene.edges) {
      if (block[e.id] == Block.power && link[e.id] == panel)
        block[e.id] = Block.none;
    }
    _emit(EventType.shutdown, unit, panel);
  }

  void _extinguish(int unit, String node) {
    fires.remove(node);
    _emit(EventType.extinguished, unit, node);
  }

  void _complete(UnitState u) {
    final id = u.job!;
    final subject = id.substring(id.indexOf(':') + 1);
    jobProgress.remove(id);
    switch (u.jobKind!) {
      case JobKind.clearDebris:
      case JobKind.clearHeavy:
        block[subject] = Block.none;
        _emit(EventType.cleared, u.index, subject);
      case JobKind.bridgeGap:
        bridged.add(subject);
        _emit(EventType.bridged, u.index, subject);
      case JobKind.reveal:
        if (u.role == Role.droneOperator) {
          final n = nodes[u.at]!;
          _revealAround(u.index, n.x, n.y, droneRevealRange);
        } else {
          _revealEdge(u.index, subject);
        }
      case JobKind.shutdown:
        _shutdown(u.index, subject);
      case JobKind.signal:
        relaysOn.add(subject);
        for (final e in scene.edges) {
          if (block[e.id] == Block.jam && link[e.id] == subject)
            block[e.id] = Block.none;
        }
        _emit(EventType.signaled, u.index, subject);
      case JobKind.repair:
        shelters[subject]!.broken = false;
        _emit(EventType.repaired, u.index, subject);
      case JobKind.extinguish:
        _extinguish(u.index, subject);
      case JobKind.stabilize:
        civilians[subject]!.stabilized = true;
        _emit(EventType.stabilized, u.index, subject);
      case JobKind.escort:
      case JobKind.deliver:
        break;
    }
    _emit(EventType.workDone, u.index, id);
    _finishJob(u);
    _changed();
  }

  void _finishJob(UnitState u) {
    u.job = null;
    u.jobKind = null;
    u.target = null;
    u.stage = 0;
    u.path = [];
    u.workDone = 0;
    u.workNeeded = 0;
    u.activity = Activity.idle;
    u.jobsDone++;
    final f = scene.rules.fatigueJobs;
    if (f > 0 && u.jobsDone % f == 0) {
      u.activity = Activity.resting;
      u.restUntil = tick + scene.rules.restTicks;
      _emit(EventType.rest, u.index, u.at, '${scene.rules.restTicks}');
    }
  }

  void _dropJob(UnitState u, String why) {
    final id = u.job;
    if (id == null) return;
    if (u.activity == Activity.working && u.workDone > 0)
      jobProgress[id] = u.workDone;
    if (u.jobKind == JobKind.deliver) {
      inTransit[u.carryNeed!] = inTransit[u.carryNeed!]! - u.claimed;
      if (u.carrying > 0) {
        // Supplies go back to the nearest depot stock so nothing is lost.
        final d = (depotStock.keys.toList()..sort()).first;
        depotStock[d] = depotStock[d]! + u.carrying;
      }
      u.carrying = 0;
      u.claimed = 0;
      u.carryNeed = null;
    }
    if (u.jobKind == JobKind.escort && u.carryingCivilian != null) {
      final c = civilians[u.carryingCivilian]!;
      c.carriedBy = -1;
      c.node = u.edge == null ? u.at : u.to!;
      u.carryingCivilian = null;
    }
    if (why.isNotEmpty) _emit(EventType.blocked, u.index, id, why);
    u.job = null;
    u.jobKind = null;
    u.target = null;
    u.stage = 0;
    u.path = [];
    u.workDone = 0;
    u.workNeeded = 0;
    if (u.activity != Activity.resting) u.activity = Activity.idle;
    u.decidedAtVersion = -1;
    _changed();
  }

  void _assign(UnitState u, Job j, String node, List<String> path) {
    u.job = j.id;
    u.jobKind = j.kind;
    u.target = node;
    u.stage = 0;
    u.path = path;
    u.activity = path.isEmpty ? Activity.working : Activity.moving;
    if (j.kind == JobKind.deliver) {
      final n = scene.needs.firstWhere((n) => n.id == j.subject);
      final remaining = n.count - delivered[n.id]! - inTransit[n.id]!;
      u.claimed = remaining < carryCapacity(u.role, u.gear)
          ? remaining
          : carryCapacity(u.role, u.gear);
      u.carryNeed = n.id;
      inTransit[n.id] = inTransit[n.id]! + u.claimed;
    }
    _emit(EventType.claim, u.index, j.id, node);
    if (path.isEmpty) _arrived(u);
  }

  // ------------------------------------------------------------------ tick

  void _decide() {
    final idle = [
      for (final u in units)
        if (u.activity == Activity.idle && u.job == null && u.edge == null) u,
    ];
    if (idle.isEmpty || idle.every((u) => u.decidedAtVersion == version))
      return;
    final all = jobs();
    final reaches = {for (final u in idle) u.index: reach(u, u.at)};
    final options = <(int, int, String, Job, String, List<String>)>[];
    for (final u in idle) {
      for (final j in all) {
        if (claimedByOther(j.id, u.index)) continue;
        final ev = evaluate(u, j, reaches[u.index]!);
        if (ev != null) options.add((ev.$1, u.index, j.id, j, ev.$2, ev.$3));
      }
    }
    options.sort((a, b) {
      final c = a.$1.compareTo(b.$1);
      if (c != 0) return c;
      final d = a.$2.compareTo(b.$2);
      return d != 0 ? d : a.$3.compareTo(b.$3);
    });
    final taken = <String>{};
    final busy = <int>{};
    for (final o in options) {
      if (busy.contains(o.$2)) continue;
      if (o.$4.kind != JobKind.deliver && taken.contains(o.$3)) continue;
      final u = units[o.$2];
      if (o.$4.kind == JobKind.deliver) {
        final n = scene.needs.firstWhere((n) => n.id == o.$4.subject);
        if (n.count - delivered[n.id]! - inTransit[n.id]! <= 0) continue;
      }
      busy.add(o.$2);
      taken.add(o.$3);
      _assign(u, o.$4, o.$5, o.$6);
    }
    for (final u in idle) {
      if (u.job == null) u.decidedAtVersion = version;
    }
  }

  void _hazardStep() {
    while (_hazardCursor < _hazards.length &&
        _hazards[_hazardCursor].at <= tick) {
      final h = _hazards[_hazardCursor++];
      switch (h.type) {
        case HazardType.spread:
          if (!fires.containsKey(h.from) || fires.containsKey(h.to)) break;
          final holder = units.where(
            (u) =>
                u.edge == null &&
                u.at == h.to &&
                (u.role == Role.fireSpecialist ||
                    (u.gear == Gear.extinguisher &&
                        h.intensity <= extinguisherMaxIntensity)),
          );
          if (holder.isNotEmpty) {
            _emit(EventType.spreadHeld, holder.first.index, h.to!, h.from!);
            break;
          }
          fires[h.to!] = h.intensity;
          everBurned.add(h.to!);
          _emit(EventType.spread, -1, h.to!, h.from!);
          _afterFire(h.to!);
        case HazardType.collapse:
          if (block[h.edge] == Block.none && terrain[h.edge] != Terrain.water) {
            block[h.edge!] = h.intensity >= 2 ? Block.heavy : Block.debris;
            _emit(EventType.collapse, -1, h.edge!, block[h.edge]!.name);
          }
        case HazardType.flood:
          if (terrain[h.edge] == Terrain.road) {
            terrain[h.edge!] = Terrain.water;
            if (block[h.edge] == Block.debris) block[h.edge!] = Block.none;
            _emit(EventType.flooded, -1, h.edge!);
          }
        case HazardType.surge:
          if (!panelsOff.contains(h.link) && block[h.edge] == Block.none) {
            block[h.edge!] = Block.power;
            link[h.edge!] = h.link;
            _emit(EventType.surge, -1, h.edge!, h.link!);
          }
        case HazardType.jam:
          if (!relaysOn.contains(h.link) && block[h.edge] == Block.none) {
            block[h.edge!] = Block.jam;
            link[h.edge!] = h.link;
            _emit(EventType.jam, -1, h.edge!, h.link!);
          }
        case HazardType.wind:
          _emit(EventType.wind, -1, h.note);
      }
      _changed();
    }
  }

  void _afterFire(String node) {
    for (final c in civilians.values) {
      if (c.node == node && !c.safe && !c.lost && c.carriedBy < 0) {
        c.lost = true;
        _emit(EventType.civilianLost, -1, c.def.id, node);
      }
    }
    for (final u in units) {
      if (u.edge != null && u.to == node) {
        // Turn back rather than walk into the fire.
        final origin = u.at;
        u.at = node;
        u.to = origin;
        u.edgeProgress = u.edgeLen - u.edgeProgress;
        u.path = [];
        _turningBack.add(u.index);
      } else if (u.edge == null && u.at == node) {
        final escape =
            adjacency[node]!
                .map((e) => other(e, node))
                .where((n) => !fires.containsKey(n))
                .toList()
              ..sort();
        final escorting = u.carryingCivilian != null;
        if (!escorting) _dropJob(u, 'fire');
        if (escape.isNotEmpty) {
          u.at = escape.first;
          final n = nodes[u.at]!;
          u.x = n.x;
          u.y = n.y;
          _emit(EventType.displaced, u.index, u.at, node);
          if (escorting) _replan(u);
        }
      }
    }
  }

  final Set<int> _turningBack = {};

  void _moveUnit(UnitState u) {
    if (u.edge == null) {
      if (u.path.isEmpty) return;
      final next = u.path.first;
      final e = edgeBetween(u.at, next);
      if (e == null || !passable(u, e)) {
        if (!_replan(u)) return;
        return _moveUnit(u);
      }
      u.path = u.path.sublist(1);
      u.edge = e;
      u.to = next;
      u.edgeProgress = 0;
      u.edgeLen = edgeLength[e]! * 100;
    }
    u.edgeProgress += speedOn(u, u.edge!);
    final a = nodes[u.at]!, b = nodes[u.to]!;
    if (u.edgeProgress >= u.edgeLen) {
      u.at = u.to!;
      u.edge = null;
      u.to = null;
      u.x = b.x;
      u.y = b.y;
      if (_turningBack.remove(u.index)) {
        if (u.job != null && !_replan(u)) return;
      }
      if (u.path.isEmpty) {
        _arrived(u);
      }
      return;
    }
    final t = u.edgeLen == 0 ? 0 : u.edgeProgress * 1000 ~/ u.edgeLen;
    u.x = a.x + (b.x - a.x) * t ~/ 1000;
    u.y = a.y + (b.y - a.y) * t ~/ 1000;
  }

  bool _replan(UnitState u) {
    final r = reach(u, u.at);
    if (u.target != null && r.$1.containsKey(u.target)) {
      u.path = _pathTo(r.$2, u.at, u.target!);
      if (u.path.isEmpty) {
        _arrived(u);
      } else if (u.activity == Activity.waiting ||
          u.activity == Activity.idle) {
        u.activity = Activity.moving;
      }
      return u.path.isNotEmpty;
    }
    if (u.job != null && u.stage == 0) {
      final j = jobById(u.job!);
      if (j != null) {
        final ev = evaluate(u, j, r);
        if (ev != null) {
          u.target = ev.$2;
          u.path = ev.$3;
          if (u.path.isEmpty) _arrived(u);
          return u.path.isNotEmpty;
        }
      }
    }
    if (u.stage == 1 && u.jobKind == JobKind.escort && _pickShelter(u))
      return u.path.isNotEmpty;
    _dropJob(u, 'route blocked');
    return false;
  }

  /// Nearest reachable shelter with room, preferring ones usable right now.
  (String, List<String>, bool)? _bestShelter(UnitState u) {
    final r = reach(u, u.at);
    String? best;
    var bestCost = 1 << 40;
    var bestOpen = false;
    for (final s in (shelters.keys.toList()..sort())) {
      final st = shelters[s]!;
      final c = r.$1[s];
      if (c == null || !st.hasRoom()) continue;
      final open = st.openAt(tick) && !st.broken;
      if ((open && !bestOpen) || (open == bestOpen && c < bestCost)) {
        best = s;
        bestCost = c;
        bestOpen = open;
      }
    }
    if (best == null) return null;
    return (best, _pathTo(r.$2, u.at, best), bestOpen);
  }

  bool _pickShelter(UnitState u) {
    final b = _bestShelter(u);
    if (b == null) return false;
    u.target = b.$1;
    u.path = b.$2;
    u.activity = Activity.moving;
    if (u.path.isEmpty) _arrived(u);
    return true;
  }

  void _arrived(UnitState u) {
    _discoverAt(u.at);
    for (final e in adjacency[u.at]!) {
      if (block[e] != Block.dark) _discoverAt(other(e, u.at));
    }
    if (u.job == null) {
      if (u.activity != Activity.resting) u.activity = Activity.idle;
      if (u.pendingJob != null) _takeOrder(u, u.pendingJob!);
      return;
    }
    if (u.at != u.target) return;
    final kind = u.jobKind!;
    if (kind == JobKind.escort) {
      if (u.stage == 0) {
        final c = civilians[u.job!.substring(7)]!;
        if (c.lost || c.safe || c.carriedBy >= 0 || !c.stabilized)
          return _dropJob(u, '');
        c.carriedBy = u.index;
        u.carryingCivilian = c.def.id;
        u.stage = 1;
        _emit(EventType.pickUp, u.index, c.def.id, u.at);
        if (!_pickShelter(u)) {
          _dropJob(u, 'no shelter reachable');
        }
        return;
      }
      _tryDrop(u);
      return;
    }
    if (kind == JobKind.deliver) {
      if (u.stage == 0) {
        final stock = depotStock[u.at] ?? 0;
        final take = stock < u.claimed ? stock : u.claimed;
        if (take <= 0) return _dropJob(u, 'depot empty');
        if (take < u.claimed) {
          inTransit[u.carryNeed!] =
              inTransit[u.carryNeed!]! - (u.claimed - take);
          u.claimed = take;
        }
        depotStock[u.at] = stock - take;
        u.carrying = take;
        u.stage = 1;
        _emit(EventType.pickSupplies, u.index, u.at, '$take');
        final need = scene.needs.firstWhere((n) => n.id == u.carryNeed);
        final r = reach(u, u.at);
        if (!r.$1.containsKey(need.node)) return _dropJob(u, 'route blocked');
        u.target = need.node;
        u.path = _pathTo(r.$2, u.at, need.node);
        u.activity = Activity.moving;
        if (u.path.isEmpty) _arrived(u);
        _changed();
        return;
      }
      delivered[u.carryNeed!] = delivered[u.carryNeed!]! + u.carrying;
      inTransit[u.carryNeed!] = inTransit[u.carryNeed!]! - u.claimed;
      _emit(EventType.delivered, u.index, u.carryNeed!, '${u.carrying}');
      u.carrying = 0;
      u.claimed = 0;
      u.carryNeed = null;
      _emit(EventType.workDone, u.index, u.job!);
      _finishJob(u);
      _changed();
      return;
    }
    final j = jobById(u.job!);
    if (j == null) return _dropJob(u, '');
    final w = workTicksFor(u, j);
    if (w == null) return _dropJob(u, 'cannot handle');
    u.activity = Activity.working;
    u.workNeeded = _needed(u, w);
    u.workDone = jobProgress.remove(u.job!) ?? 0;
    _emit(EventType.workStart, u.index, u.job!, u.at);
  }

  void _tryDrop(UnitState u) {
    final s = shelters[u.at]!;
    if (!s.hasRoom()) {
      final alt = _bestShelter(u);
      if (alt != null && alt.$1 != u.at) {
        u.target = alt.$1;
        u.path = alt.$2;
        u.activity = Activity.moving;
      } else {
        u.activity = Activity.waiting;
      }
      return;
    }
    if (!s.openAt(tick) || s.broken) {
      if (u.activity == Activity.waiting && u.decidedAtVersion == version)
        return;
      u.decidedAtVersion = version;
      // A different shelter may have opened since; go there instead of waiting.
      final alt = _bestShelter(u);
      if (alt != null && alt.$1 != u.at && alt.$3) {
        u.target = alt.$1;
        u.path = alt.$2;
        u.activity = Activity.moving;
        return;
      }
      if (u.activity != Activity.waiting)
        _emit(
          EventType.waiting,
          u.index,
          u.at,
          s.broken ? 'damaged' : 'closed',
        );
      u.activity = Activity.waiting;
      return;
    }
    final c = civilians[u.carryingCivilian]!;
    c.safe = true;
    c.carriedBy = -1;
    c.node = u.at;
    c.shelter = u.at;
    s.count++;
    u.carryingCivilian = null;
    _emit(EventType.dropOff, u.index, c.def.id, u.at);
    _emit(EventType.workDone, u.index, u.job!);
    _finishJob(u);
    _changed();
  }

  bool _jobValid(UnitState u) {
    final id = u.job!;
    final subject = id.substring(id.indexOf(':') + 1);
    switch (u.jobKind!) {
      case JobKind.clearDebris:
        return block[subject] == Block.debris;
      case JobKind.clearHeavy:
        return block[subject] == Block.heavy;
      case JobKind.reveal:
        return block[subject] == Block.dark;
      case JobKind.bridgeGap:
        return !bridged.contains(subject);
      case JobKind.shutdown:
        return !panelsOff.contains(subject);
      case JobKind.signal:
        return !relaysOn.contains(subject);
      case JobKind.repair:
        return shelters[subject]!.broken;
      case JobKind.extinguish:
        return fires.containsKey(subject);
      case JobKind.stabilize:
        final c = civilians[subject]!;
        return !c.stabilized && !c.lost;
      case JobKind.escort:
        final c = civilians[subject]!;
        return !c.lost &&
            !c.safe &&
            (c.carriedBy < 0 || c.carriedBy == u.index);
      case JobKind.deliver:
        return true;
    }
  }

  int _workRate(UnitState u) {
    for (final o in units) {
      if (o.index != u.index &&
          o.role == Role.coordinator &&
          _dist(o.x, o.y, u.x, u.y) <= coordinatorAuraRange) {
        return 125;
      }
    }
    return 100;
  }

  bool _futurePending() {
    if (_hazardCursor < _hazards.length) return true;
    if (shelters.values.any((s) => s.def.openAt > tick)) return true;
    if (spannedUntil.values.any((t) => t > tick)) return true;
    return units.any((u) => u.activity == Activity.resting);
  }

  /// Advances one tick. Returns events emitted during it.
  List<SimEvent> step() {
    if (!running) return const [];
    final first = events.length;
    for (final u in units) {
      u.prevX = u.x;
      u.prevY = u.y;
    }
    final cmds = [..._queued];
    _queued.clear();
    for (final c in cmds) {
      _apply(c);
    }
    _hazardStep();
    for (final s in shelters.values) {
      if (s.def.openAt == tick && tick > 0) {
        _emit(EventType.shelterOpen, -1, s.def.node);
        _changed();
      }
    }
    for (final e in spannedUntil.entries.toList()) {
      if (e.value == tick) {
        _emit(EventType.spanEnd, -1, e.key);
        _changed();
      }
    }
    for (final u in units) {
      if (u.activity == Activity.resting && u.restUntil <= tick) {
        u.activity = Activity.idle;
        _emit(EventType.restEnd, u.index, u.at);
        _changed();
      }
      if (u.job != null && !_jobValid(u)) _dropJob(u, '');
    }
    if (tick >= deployTicks) _decide();
    for (final u in units) {
      if (u.edge != null) {
        _moveUnit(u);
        continue;
      }
      switch (u.activity) {
        case Activity.moving:
          _moveUnit(u);
          if (u.edge == null &&
              u.job == null &&
              u.path.isEmpty &&
              u.activity == Activity.moving) {
            u.activity = Activity.idle;
          }
        case Activity.working:
          u.workDone += _workRate(u);
          if (u.workDone >= u.workNeeded) _complete(u);
        case Activity.waiting:
          if (u.jobKind == JobKind.escort) _tryDrop(u);
        case Activity.idle:
        case Activity.resting:
          break;
      }
    }
    _evaluateObjectives();
    if (running) _checkStall();
    tick++;
    return events.sublist(first);
  }

  void _evaluateObjectives() {
    for (var i = 0; i < scene.objectives.length; i++) {
      if (objectives[i] == ObjState.failed) continue;
      final o = scene.objectives[i];
      final (met, failed) = _objective(o, i);
      final before = objectives[i];
      if (failed) {
        objectives[i] = ObjState.failed;
        _fail(_objectiveFailText(o));
        return;
      }
      objectives[i] = met ? ObjState.met : ObjState.pending;
      if (met) _everMet[i] = true;
      if (met && before != ObjState.met)
        _emit(EventType.objectiveMet, -1, '$i');
      if (!met && o.by > 0 && tick > o.by && !_everMet[i]) {
        objectives[i] = ObjState.failed;
        _fail(_objectiveFailText(o));
        return;
      }
    }
    if (objectives.every((s) => s == ObjState.met)) {
      outcome = Outcome.won;
      _emit(EventType.win, -1, scene.id, '$tick');
    }
  }

  (bool, bool) _objective(Objective o, int i) {
    switch (o.type) {
      case ObjectiveType.civiliansSafe:
        final alive = civilians.values.where((c) => !c.lost).length;
        return (civiliansSafe >= o.count, alive < o.count);
      case ObjectiveType.stabilized:
        final c = civilians[o.target]!;
        return (
          c.stabilized,
          c.lost || (o.by > 0 && tick > o.by && !c.stabilized),
        );
      case ObjectiveType.routeOpen:
        return (walkerConnected(o.a!, o.b!), false);
      case ObjectiveType.contained:
        return (fires.isEmpty, false);
      case ObjectiveType.delivered:
        final n = scene.needs.firstWhere((n) => n.id == o.target);
        return (delivered[n.id]! >= (o.count == 0 ? n.count : o.count), false);
      case ObjectiveType.panelSafe:
        return (panelsOff.contains(o.target), false);
      case ObjectiveType.protect:
        return (true, o.nodes.any(everBurned.contains));
      case ObjectiveType.revealed:
        return (o.nodes.every((e) => block[e] != Block.dark), false);
      case ObjectiveType.shelterOpen:
        final s = shelters[o.target]!;
        return (!s.broken && s.openAt(tick), false);
    }
  }

  String _objectiveFailText(Objective o) => switch (o.type) {
    ObjectiveType.civiliansSafe =>
      'Not enough people could still reach a shelter.',
    ObjectiveType.stabilized =>
      'The priority call was not reached in time; city crews took over.',
    ObjectiveType.protect =>
      'Fire reached the corridor the team had to keep clear.',
    _ => 'An objective missed its deadline.',
  };

  void _fail(String reason, [List<String> hints = const []]) {
    if (!running) return;
    outcome = Outcome.failed;
    failReason = reason;
    failHints = hints.isEmpty ? explainBlockers() : hints;
    _emit(EventType.fail, -1, scene.id, reason);
  }

  void _checkStall() {
    if (tick >= scene.rules.tickLimit) {
      _fail('Time ran out before every objective was met.');
      return;
    }
    if (tick < deployTicks) return;
    // Waiting at a closed shelter is not progress unless something else will change.
    final busy = units.any(
      (u) =>
          u.edge != null ||
          (u.job != null && u.activity != Activity.waiting) ||
          (u.activity != Activity.idle && u.activity != Activity.waiting) ||
          u.decidedAtVersion != version,
    );
    if (busy || _futurePending()) {
      _stallSince = -1;
      return;
    }
    if (_stallSince < 0) {
      _stallSince = tick;
      _emit(EventType.stall, -1, scene.id);
    }
    final abilityHelps =
        chargesLeft > 0 &&
        units.any((u) => !u.abilityUsed && abilityTargets(u.index).isNotEmpty);
    if (failFast && !abilityHelps) {
      _fail('The team has no way to complete the remaining objectives.');
    } else if (tick - _stallSince >= stallGraceTicks) {
      _fail('The team has no way to complete the remaining objectives.');
    }
  }

  /// Plain-language dependencies the current team cannot satisfy.
  List<String> explainBlockers() {
    final out = <String>{};
    bool team(bool Function(UnitState) f) => units.any(f);
    final reachSet = _teamReach();
    for (final e in scene.edges) {
      final d = edgeDefs[e.id]!;
      final frontier =
          reachSet.contains(d.a) != reachSet.contains(d.b) ||
          routeEdges.contains(e.id);
      if (!frontier) continue;
      final name = d.label.isEmpty ? 'a lane' : d.label;
      switch (block[e.id]!) {
        case Block.debris:
          if (!team(
            (u) => baseWorkTicks(u.role, u.gear, JobKind.clearDebris) != null,
          )) {
            out.add(
              'Debris on $name needs a Rescuer, Engineer, Heavy Engineer or a Cutter.',
            );
          }
        case Block.heavy:
          if (!team(
            (u) => baseWorkTicks(u.role, u.gear, JobKind.clearHeavy) != null,
          )) {
            out.add(
              'Heavy debris on $name needs a Heavy Engineer or a Spreader.',
            );
          }
        case Block.dark:
          if (!team(
            (u) => baseWorkTicks(u.role, u.gear, JobKind.reveal) != null,
          )) {
            out.add(
              '$name is unlit: bring a Scout, Drone Operator or a Floodlight.',
            );
          }
        case Block.power:
          if (!team((u) => u.role == Role.technician))
            out.add('$name is live: a Technician must shut the panel.');
        case Block.jam:
          if (!team(
            (u) => baseWorkTicks(u.role, u.gear, JobKind.signal) != null,
          )) {
            out.add(
              'Crowd jam on $name: a Dispatcher, Coordinator or Radio can clear it from the relay.',
            );
          }
        case Block.none:
          if (terrain[e.id] == Terrain.water &&
              !team((u) => u.role.def.waterSpeed > 0)) {
            out.add('Water on $name: only a Boat Pilot can cross.');
          }
          if (terrain[e.id] == Terrain.gap &&
              !gapOpen(e.id) &&
              !team((u) => u.role == Role.heavyEngineer)) {
            out.add('The gap at $name needs a Heavy Engineer to bridge.');
          }
      }
    }
    for (final c in civilians.values) {
      if (c.lost || c.safe) continue;
      if (!c.known) {
        out.add(
          'Someone may be waiting in an unlit area. Reveal the dark lanes first.',
        );
      } else if (!c.stabilized &&
          !team(
            (u) => baseWorkTicks(u.role, u.gear, JobKind.stabilize) != null,
          )) {
        out.add(
          'A person needs care before moving: bring a Medic or a First-Aid Kit.',
        );
      } else if (!team((u) => u.role.def.escort)) {
        out.add(
          'Nobody can escort people: bring a Rescuer, Medic, Boat Pilot or Coordinator.',
        );
      }
    }
    for (final f in fires.entries) {
      if (f.value > extinguisherMaxIntensity &&
          !team((u) => u.role == Role.fireSpecialist)) {
        out.add(
          'The fire at ${nodes[f.key]!.label.isEmpty ? 'the site' : nodes[f.key]!.label} is too strong for an extinguisher: bring a Fire Specialist.',
        );
      } else if (!team(
        (u) => baseWorkTicks(u.role, u.gear, JobKind.extinguish) != null,
      )) {
        out.add(
          'Nobody can contain fire: bring a Fire Specialist or an Extinguisher.',
        );
      }
    }
    for (final s in shelters.values) {
      if (s.broken &&
          !team((u) => baseWorkTicks(u.role, u.gear, JobKind.repair) != null)) {
        out.add(
          'A shelter door is damaged: bring an Engineer, Heavy Engineer or a Toolkit.',
        );
      }
    }
    if (scene.needs.isNotEmpty &&
        !team((u) => carryCapacity(u.role, u.gear) > 0)) {
      out.add(
        'Supplies need a carrier: Rescuer, Logistics Lead, Boat Pilot or a Cargo Sled.',
      );
    }
    if (out.isEmpty)
      out.add(
        'Try different start positions or priorities so responders reach tasks sooner.',
      );
    return out.toList();
  }
}

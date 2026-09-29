/// Mission scene data contract (schema 1). One scene per mission ID.
library;

import 'roles.dart';

const int sceneSchema = 1;

enum Terrain { road, water, gap }

enum Block { none, debris, heavy, jam, power, dark }

enum NodeKind {
  street,
  junction,
  deploy,
  shelter,
  depot,
  need,
  panel,
  relay,
  pier,
  lookout,
}

class SceneNode {
  final String id;
  final int x, y;
  final NodeKind kind;
  final String label;
  const SceneNode(
    this.id,
    this.x,
    this.y, {
    this.kind = NodeKind.street,
    this.label = '',
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'x': x,
    'y': y,
    if (kind != NodeKind.street) 'kind': kind.name,
    if (label.isNotEmpty) 'label': label,
  };
  static SceneNode fromJson(Map<String, Object?> j) => SceneNode(
    j['id'] as String,
    (j['x'] as num).toInt(),
    (j['y'] as num).toInt(),
    kind: _enum(NodeKind.values, j['kind'], NodeKind.street),
    label: j['label'] as String? ?? '',
  );
}

class SceneEdge {
  final String id;
  final String a, b;
  final Terrain terrain;
  final Block block;

  /// For [Block.power]: the panel that isolates this edge.
  /// For [Block.jam]: the relay that clears it.
  final String? link;
  final String label;
  const SceneEdge(
    this.id,
    this.a,
    this.b, {
    this.terrain = Terrain.road,
    this.block = Block.none,
    this.link,
    this.label = '',
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'a': a,
    'b': b,
    if (terrain != Terrain.road) 'terrain': terrain.name,
    if (block != Block.none) 'block': block.name,
    'link': ?link,
    if (label.isNotEmpty) 'label': label,
  };
  static SceneEdge fromJson(Map<String, Object?> j) => SceneEdge(
    j['id'] as String,
    j['a'] as String,
    j['b'] as String,
    terrain: _enum(Terrain.values, j['terrain'], Terrain.road),
    block: _enum(Block.values, j['block'], Block.none),
    link: j['link'] as String?,
    label: j['label'] as String? ?? '',
  );
}

class Civilian {
  final String id;
  final String node;
  final bool needsCare;

  /// Critical civilians appear first in AI priority and in the forecast.
  final bool critical;

  /// Only known once an adjacent dark lane is revealed or a responder is adjacent.
  final bool hidden;

  /// 0..3 visual variant.
  final int look;
  const Civilian(
    this.id,
    this.node, {
    this.needsCare = false,
    this.critical = false,
    this.hidden = false,
    this.look = 0,
  });

  Map<String, Object?> toJson() => {
    'id': id,
    'node': node,
    if (needsCare) 'needsCare': true,
    if (critical) 'critical': true,
    if (hidden) 'hidden': true,
    if (look != 0) 'look': look,
  };
  static Civilian fromJson(Map<String, Object?> j) => Civilian(
    j['id'] as String,
    j['node'] as String,
    needsCare: j['needsCare'] as bool? ?? false,
    critical: j['critical'] as bool? ?? false,
    hidden: j['hidden'] as bool? ?? false,
    look: (j['look'] as num?)?.toInt() ?? 0,
  );
}

class Shelter {
  final String node;

  /// 0 = unlimited.
  final int capacity;

  /// Tick when the shelter opens. 0 = open from the start.
  final int openAt;
  final bool broken;
  const Shelter(
    this.node, {
    this.capacity = 0,
    this.openAt = 0,
    this.broken = false,
  });

  Map<String, Object?> toJson() => {
    'node': node,
    if (capacity != 0) 'capacity': capacity,
    if (openAt != 0) 'openAt': openAt,
    if (broken) 'broken': true,
  };
  static Shelter fromJson(Map<String, Object?> j) => Shelter(
    j['node'] as String,
    capacity: (j['capacity'] as num?)?.toInt() ?? 0,
    openAt: (j['openAt'] as num?)?.toInt() ?? 0,
    broken: j['broken'] as bool? ?? false,
  );
}

class Depot {
  final String node;
  final int stock;
  const Depot(this.node, this.stock);
  Map<String, Object?> toJson() => {'node': node, 'stock': stock};
  static Depot fromJson(Map<String, Object?> j) =>
      Depot(j['node'] as String, (j['stock'] as num).toInt());
}

class Need {
  final String id;
  final String node;
  final int count;
  const Need(this.id, this.node, this.count);
  Map<String, Object?> toJson() => {'id': id, 'node': node, 'count': count};
  static Need fromJson(Map<String, Object?> j) =>
      Need(j['id'] as String, j['node'] as String, (j['count'] as num).toInt());
}

class Fire {
  final String node;
  final int intensity;
  const Fire(this.node, this.intensity);
  Map<String, Object?> toJson() => {'node': node, 'intensity': intensity};
  static Fire fromJson(Map<String, Object?> j) =>
      Fire(j['node'] as String, (j['intensity'] as num).toInt());
}

class DeployZone {
  final String node;
  final int capacity;
  const DeployZone(this.node, {this.capacity = 1});
  Map<String, Object?> toJson() => {
    'node': node,
    if (capacity != 1) 'capacity': capacity,
  };
  static DeployZone fromJson(Map<String, Object?> j) => DeployZone(
    j['node'] as String,
    capacity: (j['capacity'] as num?)?.toInt() ?? 1,
  );
}

enum HazardType {
  /// Fire spreads from [from] to [to] if [from] is still burning.
  spread,

  /// Debris falls onto [edge].
  collapse,

  /// Road [edge] floods and becomes water.
  flood,

  /// [edge] becomes live, isolated by panel [link], unless that panel is already off.
  surge,

  /// Informational: forecast wind change. Following spreads carry the direction.
  wind,

  /// Crowd jam on [edge], cleared by relay [link].
  jam,
}

class HazardEvent {
  final int at;
  final HazardType type;
  final String? from, to, edge, link;
  final int intensity;
  final String note;
  const HazardEvent(
    this.at,
    this.type, {
    this.from,
    this.to,
    this.edge,
    this.link,
    this.intensity = 1,
    this.note = '',
  });

  Map<String, Object?> toJson() => {
    'at': at,
    'type': type.name,
    'from': ?from,
    'to': ?to,
    'edge': ?edge,
    'link': ?link,
    if (intensity != 1) 'intensity': intensity,
    if (note.isNotEmpty) 'note': note,
  };
  static HazardEvent fromJson(Map<String, Object?> j) => HazardEvent(
    (j['at'] as num).toInt(),
    _enum(HazardType.values, j['type'], HazardType.wind),
    from: j['from'] as String?,
    to: j['to'] as String?,
    edge: j['edge'] as String?,
    link: j['link'] as String?,
    intensity: (j['intensity'] as num?)?.toInt() ?? 1,
    note: j['note'] as String? ?? '',
  );
}

enum ObjectiveType {
  civiliansSafe,
  stabilized,
  routeOpen,
  contained,
  delivered,
  panelSafe,
  protect,
  revealed,
  shelterOpen,
}

class Objective {
  final ObjectiveType type;
  final int count;
  final String? target;
  final String? a, b;
  final List<String> nodes;

  /// Deadline tick, 0 = none. Only used where the brief explains it.
  final int by;
  const Objective(
    this.type, {
    this.count = 0,
    this.target,
    this.a,
    this.b,
    this.nodes = const [],
    this.by = 0,
  });

  Map<String, Object?> toJson() => {
    'type': type.name,
    if (count != 0) 'count': count,
    'target': ?target,
    'a': ?a,
    'b': ?b,
    if (nodes.isNotEmpty) 'nodes': nodes,
    if (by != 0) 'by': by,
  };
  static Objective fromJson(Map<String, Object?> j) => Objective(
    _enum(ObjectiveType.values, j['type'], ObjectiveType.civiliansSafe),
    count: (j['count'] as num?)?.toInt() ?? 0,
    target: j['target'] as String?,
    a: j['a'] as String?,
    b: j['b'] as String?,
    nodes: ((j['nodes'] as List?) ?? const []).cast<String>(),
    by: (j['by'] as num?)?.toInt() ?? 0,
  );
}

class Rules {
  /// Jobs before a mandatory rest. 0 = no fatigue.
  final int fatigueJobs;
  final int restTicks;

  /// Team-wide ability uses per mission; each responder at most once.
  final int abilityCharges;
  final int redirects;
  final int tickLimit;
  const Rules({
    this.fatigueJobs = 0,
    this.restTicks = 40,
    this.abilityCharges = 1,
    this.redirects = 1,
    this.tickLimit = 3000,
  });

  Map<String, Object?> toJson() => {
    if (fatigueJobs != 0) 'fatigueJobs': fatigueJobs,
    if (restTicks != 40) 'restTicks': restTicks,
    'abilityCharges': abilityCharges,
    'redirects': redirects,
    if (tickLimit != 3000) 'tickLimit': tickLimit,
  };
  static Rules fromJson(Map<String, Object?>? j) => j == null
      ? const Rules()
      : Rules(
          fatigueJobs: (j['fatigueJobs'] as num?)?.toInt() ?? 0,
          restTicks: (j['restTicks'] as num?)?.toInt() ?? 40,
          abilityCharges: (j['abilityCharges'] as num?)?.toInt() ?? 1,
          redirects: (j['redirects'] as num?)?.toInt() ?? 1,
          tickLimit: (j['tickLimit'] as num?)?.toInt() ?? 3000,
        );
}

class UnitSetup {
  final Role role;
  final String node;
  final Gear? gear;
  final Focus focus;
  final Upgrades upgrades;
  const UnitSetup(
    this.role,
    this.node, {
    this.gear,
    this.focus = Focus.auto,
    this.upgrades = Upgrades.none,
  });

  UnitSetup copyWith({
    String? node,
    Gear? gear,
    bool clearGear = false,
    Focus? focus,
    Upgrades? upgrades,
  }) => UnitSetup(
    role,
    node ?? this.node,
    gear: clearGear ? null : (gear ?? this.gear),
    focus: focus ?? this.focus,
    upgrades: upgrades ?? this.upgrades,
  );

  Map<String, Object?> toJson() => {
    'role': role.name,
    'node': node,
    if (gear != null) 'gear': gear!.name,
    if (focus != Focus.auto) 'focus': focus.name,
    if (upgrades != Upgrades.none) 'upgrades': upgrades.toJson(),
  };
  static UnitSetup fromJson(Map<String, Object?> j) => UnitSetup(
    Role.parse(j['role'] as String),
    j['node'] as String,
    gear: Gear.parse(j['gear'] as String?),
    focus: _enum(Focus.values, j['focus'], Focus.auto),
    upgrades: Upgrades.fromJson(
      (j['upgrades'] as Map?)?.cast<String, Object?>(),
    ),
  );
}

enum CommandType { ability, redirect }

class Command {
  final int tick;
  final CommandType type;
  final int unit;

  /// Edge/node/civilian/need/panel id, or job id for redirects. Null for self abilities.
  final String? target;
  const Command(this.tick, this.type, this.unit, [this.target]);

  Map<String, Object?> toJson() => {
    'tick': tick,
    'type': type.name,
    'unit': unit,
    'target': ?target,
  };
  static Command fromJson(Map<String, Object?> j) => Command(
    (j['tick'] as num).toInt(),
    _enum(CommandType.values, j['type'], CommandType.ability),
    (j['unit'] as num).toInt(),
    j['target'] as String?,
  );
}

class Witness {
  final List<UnitSetup> loadout;
  final List<Command> commands;
  final int ticks;
  final String hash;
  const Witness(this.loadout, this.commands, this.ticks, this.hash);

  Map<String, Object?> toJson() => {
    'loadout': [for (final u in loadout) u.toJson()],
    'commands': [for (final c in commands) c.toJson()],
    'ticks': ticks,
    'hash': hash,
  };
  static Witness fromJson(Map<String, Object?> j) => Witness(
    [
      for (final u in (j['loadout'] as List))
        UnitSetup.fromJson((u as Map).cast()),
    ],
    [
      for (final c in ((j['commands'] as List?) ?? const []))
        Command.fromJson((c as Map).cast()),
    ],
    (j['ticks'] as num).toInt(),
    j['hash'] as String,
  );
}

/// Editorial / QA state recorded per mission.
class Review {
  /// `hand` for hand-authored, `curated_generated` for generator output that
  /// passed automated curation.
  final String authoring;
  final String solver;
  final int setupsTried;
  final int setupsWon;
  final String difficulty;
  final String editorial;
  final String human;
  const Review({
    this.authoring = 'hand',
    this.solver = 'unverified',
    this.setupsTried = 0,
    this.setupsWon = 0,
    this.difficulty = '',
    this.editorial = 'pending',
    this.human = 'not_played',
  });

  Map<String, Object?> toJson() => {
    'authoring': authoring,
    'solver': solver,
    'setupsTried': setupsTried,
    'setupsWon': setupsWon,
    'difficulty': difficulty,
    'editorial': editorial,
    'human': human,
  };
  static Review fromJson(Map<String, Object?>? j) => j == null
      ? const Review()
      : Review(
          authoring: j['authoring'] as String? ?? 'hand',
          solver: j['solver'] as String? ?? 'unverified',
          setupsTried: (j['setupsTried'] as num?)?.toInt() ?? 0,
          setupsWon: (j['setupsWon'] as num?)?.toInt() ?? 0,
          difficulty: j['difficulty'] as String? ?? '',
          editorial: j['editorial'] as String? ?? 'pending',
          human: j['human'] as String? ?? 'not_played',
        );
}

class MissionScene {
  final String id;
  final int revision;
  final int world;
  final int slot;
  final String title;
  final String brief;
  final List<String> tutorial;
  final List<String> strategies;
  final int teamSize;
  final List<Role> allowedRoles;
  final List<Gear> gear;
  final List<SceneNode> nodes;
  final List<SceneEdge> edges;
  final List<DeployZone> deploy;
  final List<Civilian> civilians;
  final List<Shelter> shelters;
  final List<Depot> depots;
  final List<Need> needs;
  final List<Fire> fires;
  final List<HazardEvent> hazards;
  final List<Objective> objectives;
  final Rules rules;

  /// 2-star and 3-star time limits in ticks, derived from verified solutions.
  final int parTicks;
  final int goldTicks;

  /// Visual layout hints for the district painter: `water:x,y,w,h` etc.
  final List<String> decor;
  final Witness? witness;
  final Review review;

  const MissionScene({
    required this.id,
    this.revision = 1,
    required this.world,
    required this.slot,
    required this.title,
    required this.brief,
    this.tutorial = const [],
    this.strategies = const [],
    required this.teamSize,
    required this.allowedRoles,
    this.gear = const [],
    required this.nodes,
    required this.edges,
    required this.deploy,
    this.civilians = const [],
    this.shelters = const [],
    this.depots = const [],
    this.needs = const [],
    this.fires = const [],
    this.hazards = const [],
    required this.objectives,
    this.rules = const Rules(),
    this.parTicks = 0,
    this.goldTicks = 0,
    this.decor = const [],
    this.witness,
    this.review = const Review(),
  });

  SceneNode node(String id) => nodes.firstWhere((n) => n.id == id);
  SceneEdge edge(String id) => edges.firstWhere((e) => e.id == id);

  MissionScene copyWith({
    int? revision,
    int? parTicks,
    int? goldTicks,
    Witness? witness,
    Review? review,
    List<HazardEvent>? hazards,
    List<Objective>? objectives,
    Rules? rules,
  }) => MissionScene(
    id: id,
    revision: revision ?? this.revision,
    world: world,
    slot: slot,
    title: title,
    brief: brief,
    tutorial: tutorial,
    strategies: strategies,
    teamSize: teamSize,
    allowedRoles: allowedRoles,
    gear: gear,
    nodes: nodes,
    edges: edges,
    deploy: deploy,
    civilians: civilians,
    shelters: shelters,
    depots: depots,
    needs: needs,
    fires: fires,
    hazards: hazards ?? this.hazards,
    objectives: objectives ?? this.objectives,
    rules: rules ?? this.rules,
    parTicks: parTicks ?? this.parTicks,
    goldTicks: goldTicks ?? this.goldTicks,
    decor: decor,
    witness: witness ?? this.witness,
    review: review ?? this.review,
  );

  Map<String, Object?> toJson() => {
    'schema': sceneSchema,
    'id': id,
    'revision': revision,
    'world': world,
    'slot': slot,
    'title': title,
    'brief': brief,
    if (tutorial.isNotEmpty) 'tutorial': tutorial,
    if (strategies.isNotEmpty) 'strategies': strategies,
    'teamSize': teamSize,
    'allowedRoles': [for (final r in allowedRoles) r.name],
    if (gear.isNotEmpty) 'gear': [for (final g in gear) g.name],
    'nodes': [for (final n in nodes) n.toJson()],
    'edges': [for (final e in edges) e.toJson()],
    'deploy': [for (final d in deploy) d.toJson()],
    if (civilians.isNotEmpty)
      'civilians': [for (final c in civilians) c.toJson()],
    if (shelters.isNotEmpty) 'shelters': [for (final s in shelters) s.toJson()],
    if (depots.isNotEmpty) 'depots': [for (final d in depots) d.toJson()],
    if (needs.isNotEmpty) 'needs': [for (final n in needs) n.toJson()],
    if (fires.isNotEmpty) 'fires': [for (final f in fires) f.toJson()],
    if (hazards.isNotEmpty) 'hazards': [for (final h in hazards) h.toJson()],
    'objectives': [for (final o in objectives) o.toJson()],
    'rules': rules.toJson(),
    'parTicks': parTicks,
    'goldTicks': goldTicks,
    if (decor.isNotEmpty) 'decor': decor,
    if (witness != null) 'witness': witness!.toJson(),
    'review': review.toJson(),
  };

  static MissionScene fromJson(Map<String, Object?> j) {
    final schema = (j['schema'] as num?)?.toInt() ?? 0;
    if (schema != sceneSchema)
      throw FormatException('scene ${j['id']}: unsupported schema $schema');
    List<T> list<T>(String k, T Function(Map<String, Object?>) f) => [
      for (final e in ((j[k] as List?) ?? const []))
        f((e as Map).cast<String, Object?>()),
    ];
    return MissionScene(
      id: j['id'] as String,
      revision: (j['revision'] as num?)?.toInt() ?? 1,
      world: (j['world'] as num).toInt(),
      slot: (j['slot'] as num).toInt(),
      title: j['title'] as String,
      brief: j['brief'] as String,
      tutorial: ((j['tutorial'] as List?) ?? const []).cast<String>(),
      strategies: ((j['strategies'] as List?) ?? const []).cast<String>(),
      teamSize: (j['teamSize'] as num).toInt(),
      allowedRoles: [
        for (final r in (j['allowedRoles'] as List)) Role.parse(r as String),
      ],
      gear: [
        for (final g in ((j['gear'] as List?) ?? const []))
          Gear.parse(g as String)!,
      ],
      nodes: list('nodes', SceneNode.fromJson),
      edges: list('edges', SceneEdge.fromJson),
      deploy: list('deploy', DeployZone.fromJson),
      civilians: list('civilians', Civilian.fromJson),
      shelters: list('shelters', Shelter.fromJson),
      depots: list('depots', Depot.fromJson),
      needs: list('needs', Need.fromJson),
      fires: list('fires', Fire.fromJson),
      hazards: list('hazards', HazardEvent.fromJson),
      objectives: list('objectives', Objective.fromJson),
      rules: Rules.fromJson((j['rules'] as Map?)?.cast<String, Object?>()),
      parTicks: (j['parTicks'] as num?)?.toInt() ?? 0,
      goldTicks: (j['goldTicks'] as num?)?.toInt() ?? 0,
      decor: ((j['decor'] as List?) ?? const []).cast<String>(),
      witness: j['witness'] == null
          ? null
          : Witness.fromJson((j['witness'] as Map).cast()),
      review: Review.fromJson((j['review'] as Map?)?.cast<String, Object?>()),
    );
  }
}

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  if (name == null) return fallback;
  for (final v in values) {
    if (v.name == name) return v;
  }
  throw FormatException('unknown value "$name" for ${fallback.runtimeType}');
}

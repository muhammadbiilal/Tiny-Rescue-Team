/// Static rules data for responders, gear, jobs and upgrades.
/// Pure Dart: no Flutter imports anywhere under lib/simulation.
library;

enum JobKind {
  clearDebris,
  clearHeavy,
  bridgeGap,
  reveal,
  signal,
  shutdown,
  extinguish,
  stabilize,
  escort,
  deliver,
  repair,
}

enum JobCategory { civilians, routes, hazards, supplies }

JobCategory categoryOf(JobKind k) => switch (k) {
  JobKind.stabilize || JobKind.escort => JobCategory.civilians,
  JobKind.extinguish || JobKind.shutdown => JobCategory.hazards,
  JobKind.deliver => JobCategory.supplies,
  _ => JobCategory.routes,
};

/// Player-set priority per responder. `auto` uses the default policy.
enum Focus { auto, civilians, routes, hazards, supplies }

JobCategory? focusCategory(Focus f) => switch (f) {
  Focus.auto => null,
  Focus.civilians => JobCategory.civilians,
  Focus.routes => JobCategory.routes,
  Focus.hazards => JobCategory.hazards,
  Focus.supplies => JobCategory.supplies,
};

enum AbilityTarget { edge, civilian, node, fire, panel, need, self }

enum Ability {
  rapidAccess(AbilityTarget.edge, 320),
  triageFocus(AbilityTarget.civilian, 360),
  quickRepair(AbilityTarget.edge, 320),
  surveyPulse(AbilityTarget.self, 460),
  swiftCrossing(AbilityTarget.self, 0),
  safeShutdown(AbilityTarget.panel, 0),
  focusedSuppression(AbilityTarget.fire, 360),
  priorityDispatch(AbilityTarget.need, 0),
  rerouteOrder(AbilityTarget.self, 460),
  revealZone(AbilityTarget.node, 400),
  temporarySpan(AbilityTarget.edge, 320),
  synchronize(AbilityTarget.self, 0);

  final AbilityTarget target;

  /// World units. 0 means unlimited range (or not range based).
  final int range;
  const Ability(this.target, this.range);
}

enum Gear {
  cutter,
  spreader,
  floodlight,
  firstAid,
  extinguisher,
  cargoSled,
  toolkit,
  radio;

  static Gear? parse(String? s) =>
      s == null ? null : Gear.values.firstWhere((g) => g.name == s);
}

enum Role {
  rescuer,
  medic,
  engineer,
  scout,
  boatPilot,
  technician,
  fireSpecialist,
  logistics,
  dispatcher,
  droneOperator,
  heavyEngineer,
  coordinator;

  static Role parse(String s) => Role.values.firstWhere((r) => r.name == s);
  RoleDef get def => roleDefs[this]!;
}

class RoleDef {
  final Role role;

  /// First mission number where this responder is on the free roster.
  final int unlockMission;

  /// Land speed, world units per tick.
  final int speed;

  /// 0 = cannot travel on water.
  final int waterSpeed;
  final int carry;
  final bool escort;

  /// Base work duration in ticks for jobs this role can do natively.
  final Map<JobKind, int> work;
  final Ability ability;
  const RoleDef({
    required this.role,
    required this.unlockMission,
    required this.speed,
    this.waterSpeed = 0,
    this.carry = 0,
    this.escort = false,
    this.work = const {},
    required this.ability,
  });
}

const Map<Role, RoleDef> roleDefs = {
  Role.rescuer: RoleDef(
    role: Role.rescuer,
    unlockMission: 1,
    speed: 7,
    carry: 1,
    escort: true,
    work: {JobKind.clearDebris: 50},
    ability: Ability.rapidAccess,
  ),
  Role.medic: RoleDef(
    role: Role.medic,
    unlockMission: 1,
    speed: 6,
    escort: true,
    work: {JobKind.stabilize: 40},
    ability: Ability.triageFocus,
  ),
  Role.scout: RoleDef(
    role: Role.scout,
    unlockMission: 31,
    speed: 8,
    work: {JobKind.reveal: 15},
    ability: Ability.surveyPulse,
  ),
  Role.boatPilot: RoleDef(
    role: Role.boatPilot,
    unlockMission: 61,
    speed: 6,
    waterSpeed: 9,
    carry: 1,
    escort: true,
    ability: Ability.swiftCrossing,
  ),
  Role.technician: RoleDef(
    role: Role.technician,
    unlockMission: 91,
    speed: 6,
    work: {JobKind.shutdown: 30},
    ability: Ability.safeShutdown,
  ),
  Role.fireSpecialist: RoleDef(
    role: Role.fireSpecialist,
    unlockMission: 121,
    speed: 6,
    work: {JobKind.extinguish: 20},
    ability: Ability.focusedSuppression,
  ),
  Role.engineer: RoleDef(
    role: Role.engineer,
    unlockMission: 11,
    speed: 6,
    work: {JobKind.clearDebris: 35, JobKind.repair: 40},
    ability: Ability.quickRepair,
  ),
  Role.logistics: RoleDef(
    role: Role.logistics,
    unlockMission: 181,
    speed: 6,
    carry: 2,
    ability: Ability.priorityDispatch,
  ),
  Role.dispatcher: RoleDef(
    role: Role.dispatcher,
    unlockMission: 211,
    speed: 6,
    work: {JobKind.signal: 25},
    ability: Ability.rerouteOrder,
  ),
  Role.droneOperator: RoleDef(
    role: Role.droneOperator,
    unlockMission: 151,
    speed: 6,
    work: {JobKind.reveal: 20},
    ability: Ability.revealZone,
  ),
  Role.heavyEngineer: RoleDef(
    role: Role.heavyEngineer,
    unlockMission: 271,
    speed: 5,
    work: {
      JobKind.clearDebris: 25,
      JobKind.clearHeavy: 45,
      JobKind.bridgeGap: 70,
      JobKind.repair: 50,
    },
    ability: Ability.temporarySpan,
  ),
  Role.coordinator: RoleDef(
    role: Role.coordinator,
    unlockMission: 301,
    speed: 6,
    escort: true,
    work: {JobKind.signal: 45},
    ability: Ability.synchronize,
  ),
};

/// Drone operators reveal from a distance; everyone else from an edge endpoint.
const int droneRevealRange = 360;

/// Teammates within this distance of a coordinator work 25% faster.
const int coordinatorAuraRange = 260;

/// Work duration in ticks for [role] with optional [gear], or null if unable.
/// Fire duration is per intensity point.
int? baseWorkTicks(Role role, Gear? gear, JobKind kind) {
  final native = role.def.work[kind];
  switch (kind) {
    case JobKind.clearDebris:
      if (gear == Gear.cutter) return native == null ? 90 : (native * 6) ~/ 10;
      return native;
    case JobKind.clearHeavy:
      if (native != null) return native;
      if (gear == Gear.spreader)
        return role == Role.engineer || role == Role.rescuer ? 80 : 100;
      return null;
    case JobKind.reveal:
      if (native != null) return native;
      return gear == Gear.floodlight ? 35 : null;
    case JobKind.stabilize:
      if (native != null) return native;
      return gear == Gear.firstAid ? 80 : null;
    case JobKind.extinguish:
      if (native != null) return native;
      return gear == Gear.extinguisher ? 45 : null;
    case JobKind.repair:
      if (native != null) return native;
      return gear == Gear.toolkit ? 80 : null;
    case JobKind.signal:
      if (native != null) return native;
      return gear == Gear.radio ? 50 : null;
    case JobKind.escort:
      return role.def.escort ? 0 : null;
    case JobKind.deliver:
      return carryCapacity(role, gear) > 0 ? 0 : null;
    case JobKind.bridgeGap:
    case JobKind.shutdown:
      return native;
  }
}

int carryCapacity(Role role, Gear? gear) {
  final c = role.def.carry;
  if (gear == Gear.cargoSled) return c + 1;
  return c;
}

/// Extinguisher gear only handles small fires.
const int extinguisherMaxIntensity = 1;

/// Two branching upgrade paths, three tiers each. Choosing a path is free to
/// change (respec refunds everything). Bounded: no infinite stat growth.
enum UpgradePath { none, mobility, expertise }

class Upgrades {
  final UpgradePath path;
  final int tier;
  const Upgrades({this.path = UpgradePath.none, this.tier = 0});
  static const none = Upgrades();

  int get speedPct =>
      path == UpgradePath.mobility ? const [0, 6, 12, 18][tier] : 0;
  int get workCutPct =>
      path == UpgradePath.expertise ? const [0, 10, 18, 25][tier] : 0;

  /// Mobility tier 3 extends ability range by 30%.
  int get abilityRangePct => path == UpgradePath.mobility && tier >= 3 ? 30 : 0;

  Map<String, Object?> toJson() => {'path': path.name, 'tier': tier};
  static Upgrades fromJson(Map<String, Object?>? j) => j == null
      ? none
      : Upgrades(
          path: UpgradePath.values.firstWhere(
            (p) => p.name == j['path'],
            orElse: () => UpgradePath.none,
          ),
          tier: ((j['tier'] as num?)?.toInt() ?? 0).clamp(0, 3),
        );

  @override
  bool operator ==(Object other) =>
      other is Upgrades && other.path == path && other.tier == tier;
  @override
  int get hashCode => Object.hash(path, tier);
}

/// Token cost of each tier; fixed and transparent.
const List<int> upgradeTierCost = [0, 2, 4, 6];

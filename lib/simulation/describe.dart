/// Player-facing English text for roles, gear and event log lines.
library;

import 'engine.dart';
import 'roles.dart';
import 'scene.dart';

const Map<Role, String> roleTitle = {
  Role.rescuer: 'Rescuer',
  Role.medic: 'Medic',
  Role.engineer: 'Engineer',
  Role.scout: 'Scout',
  Role.boatPilot: 'Boat Pilot',
  Role.technician: 'Technician',
  Role.fireSpecialist: 'Fire Specialist',
  Role.logistics: 'Logistics Lead',
  Role.dispatcher: 'Dispatcher',
  Role.droneOperator: 'Drone Operator',
  Role.heavyEngineer: 'Heavy Engineer',
  Role.coordinator: 'Coordinator',
};

/// Original characters; no real agencies or people.
const Map<Role, String> roleName = {
  Role.rescuer: 'Rosa Quill',
  Role.medic: 'Tomi Okafor',
  Role.engineer: 'Bea Kowal',
  Role.scout: 'Juno Park',
  Role.boatPilot: 'Marco Reyes',
  Role.technician: 'Priya Sethi',
  Role.fireSpecialist: 'Hana Ito',
  Role.logistics: 'Sol Mendel',
  Role.dispatcher: 'Ada Brightwater',
  Role.droneOperator: 'Leo Tan',
  Role.heavyEngineer: 'Otto Brandt',
  Role.coordinator: 'Mae Castillo',
};

const Map<Ability, String> abilityTitle = {
  Ability.rapidAccess: 'Rapid Access',
  Ability.triageFocus: 'Triage Focus',
  Ability.quickRepair: 'Quick Repair',
  Ability.surveyPulse: 'Survey Pulse',
  Ability.swiftCrossing: 'Swift Crossing',
  Ability.safeShutdown: 'Safe Shutdown',
  Ability.focusedSuppression: 'Focused Suppression',
  Ability.priorityDispatch: 'Priority Dispatch',
  Ability.rerouteOrder: 'Reroute Order',
  Ability.revealZone: 'Reveal Zone',
  Ability.temporarySpan: 'Temporary Span',
  Ability.synchronize: 'Synchronize Teams',
};

const Map<Ability, String> abilityHelp = {
  Ability.rapidAccess: 'Instantly clears one debris lane near Rosa.',
  Ability.triageFocus:
      'Instantly steadies one person near Tomi who needs care.',
  Ability.quickRepair:
      'Instantly clears debris or fixes a shelter door near Bea.',
  Ability.surveyPulse: 'Reveals every unlit lane around Juno.',
  Ability.swiftCrossing: 'Marco moves 80% faster for 12 seconds.',
  Ability.safeShutdown: 'Shuts one power panel from anywhere.',
  Ability.focusedSuppression: 'Knocks a nearby fire down by two levels.',
  Ability.priorityDispatch:
      'Sends one supply crate straight to a site that needs it.',
  Ability.rerouteOrder: 'Clears crowd jams around Ada.',
  Ability.revealZone: 'Reveals unlit lanes around any chosen spot.',
  Ability.temporarySpan: 'Opens a nearby gap for 15 seconds.',
  Ability.synchronize: 'Everyone working finishes half of their task at once.',
};

const Map<Gear, String> gearTitle = {
  Gear.cutter: 'Cutter',
  Gear.spreader: 'Spreader',
  Gear.floodlight: 'Floodlight',
  Gear.firstAid: 'First-Aid Kit',
  Gear.extinguisher: 'Extinguisher',
  Gear.cargoSled: 'Cargo Sled',
  Gear.toolkit: 'Toolkit',
  Gear.radio: 'Radio',
};

const Map<Gear, String> gearHelp = {
  Gear.cutter: 'Clears debris faster; lets anyone clear light debris.',
  Gear.spreader: 'Lets a responder clear heavy debris slowly.',
  Gear.floodlight: 'Lets a responder light up an adjacent dark lane.',
  Gear.firstAid: 'Lets a responder give basic care slowly.',
  Gear.extinguisher: 'Puts out small fires (level 1).',
  Gear.cargoSled: 'Carry one more supply crate.',
  Gear.toolkit: 'Lets a responder repair a shelter door slowly.',
  Gear.radio: 'Lets a responder clear crowd jams from a relay.',
};

const Map<Focus, String> focusTitle = {
  Focus.auto: 'Balanced',
  Focus.civilians: 'People first',
  Focus.routes: 'Routes first',
  Focus.hazards: 'Hazards first',
  Focus.supplies: 'Supplies first',
};

String jobTitle(String jobId, MissionScene s) {
  final i = jobId.indexOf(':');
  final kind = jobId.substring(0, i);
  final subject = jobId.substring(i + 1);
  String place(String node) {
    final n = s.nodes.where((x) => x.id == node);
    return n.isEmpty || n.first.label.isEmpty ? 'the site' : n.first.label;
  }

  String lane(String edge) {
    final e = s.edges.where((x) => x.id == edge);
    return e.isEmpty || e.first.label.isEmpty ? 'a lane' : e.first.label;
  }

  String civ(String id) {
    final c = s.civilians.where((x) => x.id == id);
    return c.isEmpty ? 'a resident' : 'the resident at ${place(c.first.node)}';
  }

  return switch (kind) {
    'clear' => 'clear ${lane(subject)}',
    'heavy' => 'shift heavy debris on ${lane(subject)}',
    'bridge' => 'bridge ${lane(subject)}',
    'reveal' => 'light up ${lane(subject)}',
    'shutdown' => 'shut the panel at ${place(subject)}',
    'signal' => 'signal from ${place(subject)}',
    'repair' => 'repair ${place(subject)}',
    'fire' => 'contain the fire at ${place(subject)}',
    'care' => 'give care to ${civ(subject)}',
    'escort' => 'escort ${civ(subject)}',
    'deliver' =>
      'deliver supplies to ${place(s.needs.firstWhere((n) => n.id == subject).node)}',
    _ => jobId,
  };
}

/// One log line, or null for events too minor to list.
String? describe(SimEvent e, MissionScene s, List<UnitSetup> team) {
  String who(int i) => i < 0 || i >= team.length
      ? 'The team'
      : roleName[team[i].role]!.split(' ').first;
  String place(String node) {
    final n = s.nodes.where((x) => x.id == node);
    return n.isEmpty || n.first.label.isEmpty ? 'the site' : n.first.label;
  }

  String lane(String edge) {
    final x = s.edges.where((y) => y.id == edge);
    return x.isEmpty || x.first.label.isEmpty ? 'a lane' : x.first.label;
  }

  String civAt(String id) {
    final c = s.civilians.where((x) => x.id == id);
    return c.isEmpty
        ? 'a resident'
        : 'the resident from ${place(c.first.node)}';
  }

  switch (e.type) {
    case EventType.deploy:
      return '${who(e.unit)} deployed at ${place(e.subject)}.';
    case EventType.claim:
      return '${who(e.unit)} heads to ${jobTitle(e.subject, s)}.';
    case EventType.workStart:
    case EventType.workDone:
      return null;
    case EventType.blocked:
      return e.detail.isEmpty
          ? null
          : '${who(e.unit)} stopped (${e.detail}) and is rethinking.';
    case EventType.pickUp:
      return '${who(e.unit)} is guiding ${civAt(e.subject)}.';
    case EventType.dropOff:
      return '${civAt(e.subject)[0].toUpperCase()}${civAt(e.subject).substring(1)} is safe at ${place(e.detail)}.';
    case EventType.waiting:
      return '${who(e.unit)} waits: ${place(e.subject)} is ${e.detail}.';
    case EventType.pickSupplies:
      return '${who(e.unit)} loaded ${e.detail} crate${e.detail == '1' ? '' : 's'}.';
    case EventType.delivered:
      return '${e.detail} crate${e.detail == '1' ? '' : 's'} delivered to ${place(s.needs.firstWhere((n) => n.id == e.subject).node)}.';
    case EventType.stabilized:
      return '${who(e.unit)} steadied ${civAt(e.subject)}.';
    case EventType.revealed:
      return '${who(e.unit)} lit up ${lane(e.subject)}.';
    case EventType.cleared:
      return '${who(e.unit)} cleared ${lane(e.subject)}.';
    case EventType.bridged:
      return e.detail == 'temporary'
          ? '${who(e.unit)} laid a temporary span on ${lane(e.subject)}.'
          : '${who(e.unit)} bridged ${lane(e.subject)}.';
    case EventType.spanEnd:
      return 'The temporary span on ${lane(e.subject)} was packed away.';
    case EventType.shutdown:
      return '${who(e.unit)} shut the power panel at ${place(e.subject)}.';
    case EventType.signaled:
      return '${who(e.unit)} signalled from ${place(e.subject)}; crowds are moving.';
    case EventType.repaired:
      return '${who(e.unit)} repaired ${place(e.subject)}.';
    case EventType.extinguished:
      return '${who(e.unit)} put out the fire at ${place(e.subject)}.';
    case EventType.fireReduced:
      return 'The fire at ${place(e.subject)} is down to level ${e.detail}.';
    case EventType.spread:
      return 'Fire spread from ${place(e.detail)} to ${place(e.subject)}.';
    case EventType.spreadHeld:
      return '${who(e.unit)} held the fire back at ${place(e.subject)}.';
    case EventType.flooded:
      return '${lane(e.subject)} flooded.';
    case EventType.collapse:
      return 'Debris fell on ${lane(e.subject)}.';
    case EventType.surge:
      return '${lane(e.subject)} went live.';
    case EventType.wind:
      return e.subject.isEmpty ? 'The wind changed.' : e.subject;
    case EventType.jam:
      return 'Crowds jammed ${lane(e.subject)}.';
    case EventType.shelterOpen:
      return '${place(e.subject)} opened its doors.';
    case EventType.civilianFound:
      return 'Someone is waiting at ${place(e.detail)}.';
    case EventType.civilianLost:
      return 'The resident at ${place(e.detail)} moved to a safe room; the team can no longer reach them.';
    case EventType.displaced:
      return '${who(e.unit)} stepped back from the fire to ${place(e.subject)}.';
    case EventType.rest:
      return '${who(e.unit)} takes a short breather.';
    case EventType.restEnd:
      return '${who(e.unit)} is ready again.';
    case EventType.ability:
      final a = Ability.values.firstWhere((x) => x.name == e.detail);
      return '${who(e.unit)} used ${abilityTitle[a]}.';
    case EventType.redirect:
      return '${who(e.unit)} was ordered to ${jobTitle(e.subject, s)}.';
    case EventType.commandRejected:
      return 'Order not possible: ${e.detail}';
    case EventType.objectiveMet:
      return 'Objective complete: ${objectiveText(s.objectives[int.parse(e.subject)], s)}.';
    case EventType.stall:
      return 'The team has nothing they can do. An ability or order may help.';
    case EventType.win:
      return 'All objectives complete.';
    case EventType.fail:
      return e.detail;
  }
}

String objectiveText(Objective o, MissionScene s) {
  String place(String? node) {
    final n = s.nodes.where((x) => x.id == node);
    return n.isEmpty || n.first.label.isEmpty ? 'the site' : n.first.label;
  }

  final by = o.by > 0 ? ' within ${(o.by / 10).round()} s' : '';
  return switch (o.type) {
    ObjectiveType.civiliansSafe =>
      'Guide ${o.count} ${o.count == 1 ? 'person' : 'people'} to a shelter$by',
    ObjectiveType.stabilized =>
      'Give care at ${place(s.civilians.firstWhere((c) => c.id == o.target).node)}$by',
    ObjectiveType.routeOpen =>
      'Open a safe route from ${place(o.a)} to ${place(o.b)}$by',
    ObjectiveType.contained => 'Put out every fire$by',
    ObjectiveType.delivered =>
      'Deliver ${o.count == 0 ? s.needs.firstWhere((n) => n.id == o.target).count : o.count} crates to ${place(s.needs.firstWhere((n) => n.id == o.target).node)}$by',
    ObjectiveType.panelSafe => 'Shut the panel at ${place(o.target)}$by',
    ObjectiveType.protect =>
      'Keep fire away from ${o.nodes.map(place).join(' and ')}',
    ObjectiveType.revealed => 'Survey the unlit lanes$by',
    ObjectiveType.shelterOpen => 'Reopen ${place(o.target)}$by',
  };
}

/// Forecast line for a scheduled hazard, shown before dispatch.
String hazardText(HazardEvent h, MissionScene s) {
  String place(String? node) {
    final n = s.nodes.where((x) => x.id == node);
    return n.isEmpty || n.first.label.isEmpty ? 'the site' : n.first.label;
  }

  String lane(String? edge) {
    final x = s.edges.where((y) => y.id == edge);
    return x.isEmpty || x.first.label.isEmpty ? 'a lane' : x.first.label;
  }

  final t = '${(h.at / 10).round()} s';
  return switch (h.type) {
    HazardType.spread =>
      '$t: fire may spread from ${place(h.from)} to ${place(h.to)}',
    HazardType.collapse =>
      '$t: ${lane(h.edge)} may be blocked by falling debris',
    HazardType.flood => '$t: ${lane(h.edge)} will flood',
    HazardType.surge =>
      '$t: ${lane(h.edge)} goes live unless ${place(h.link)} is shut',
    HazardType.wind => '$t: ${h.note.isEmpty ? 'wind change' : h.note}',
    HazardType.jam =>
      '$t: crowds will jam ${lane(h.edge)} unless ${place(h.link)} signals',
  };
}

// Riverside M071-M090. Boat Pilot stays on the free roster; advanced uses four roles.
import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

import 'builder.dart';

const _syn = [Role.boatPilot, Role.rescuer, Role.medic];
const _fix = [Role.boatPilot, Role.rescuer, Role.engineer];
const _scan = [Role.boatPilot, Role.scout, Role.medic];
const _quad = [Role.boatPilot, Role.rescuer, Role.medic, Role.engineer];
const _quadScan = [Role.boatPilot, Role.rescuer, Role.medic, Role.scout];

List<SceneBuilder> riversideRest() => [
  m071(),
  m072(),
  m073(),
  m074(),
  m075(),
  m076(),
  m077(),
  m078(),
  m079(),
  m080(),
  m081(),
  m082(),
  m083(),
  m084(),
  m085(),
  m086(),
  m087(),
  m088(),
  m089(),
  m090(),
];

/// Open a safe route + inspect / blocked junction.
SceneBuilder m071() {
  final b = SceneBuilder('M071', 3, 11)
    ..title = 'Blocked Ferry Cross'
    ..brief =
        'North Landing must be reachable from South Levee on land. Ferry Cross is shuttered. Callers hide in west reeds across a dark cut. Water is the boat job, not the route job.'
    ..tutorial = [
      'Route open counts land lanes only. Water does not count as the tower road.',
      'Juno or a Floodlight opens the reeds. Rosa clears Ferry Cross.',
    ]
    ..strategies = [
      'Rosa on the cross. Juno reeds. Marco ferries if the land road is slow.',
      'Clear the cross first so the landing is a land walk.',
    ]
    ..teamSize = 3
    ..roles = _scan
    ..gear = [Gear.cutter, Gear.floodlight]
    ..decor.addAll(['water:300,240,200,400', 'pier:360,140,80,50']);
  final south = b.start('south', 400, 1000, 'South Levee', capacity: 2);
  final west = b.start('west', 80, 860, 'Reed Gate');
  final cross = b.node('cross', 400, 640, 'Ferry Cross', NodeKind.junction);
  final reed = b.node('reed', 140, 480, 'West Reeds');
  final north = b.node('north', 400, 160, 'North Landing', NodeKind.pier);
  final hall = b.shelter('hall', 640, 400, 'Levee Hall');
  b
    ..lane(south, cross, 'Levee Cross')
    ..lane(west, reed, 'Reed Rise')
    ..lane(cross, north, 'Ferry Cross', Block.debris)
    ..lane(reed, cross, 'Reed Cross', Block.dark)
    ..lane(reed, north, 'Reed Water', Block.none, Terrain.water)
    ..lane(cross, hall, 'Cross Hall')
    ..lane(north, hall, 'North Hall');
  b.person(reed, hidden: true);
  b.goal(ObjectiveType.routeOpen, a: south, b: north);
  b.goal(ObjectiveType.revealed, nodes: ['reed-cross']);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Contain + two teams / branching access.
SceneBuilder m072() {
  final b = SceneBuilder('M072', 3, 12)
    ..title = 'Island Fire, Two Banks'
    ..brief =
        'Pitch on Reed Island spreads toward both banks if left. West bank and east bank are separate jobs. Branching water: lighting or holding one bank does not hold the other.'
    ..tutorial = [
      'Boat crew on the island. Bank crew on land. Extinguisher belongs on the boat.',
      'Protect both banks. Fire on either fails.',
    ]
    ..strategies = [
      'Extinguisher on Marco south slip. Rosa west. Tomi east.',
      'Marco puts it out before either spread. Banks only escort.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['water:240,280,320,280', 'pier:360,220,80,40']);
  final s = b.start('s', 400, 1000, 'South Slip');
  final w = b.start('w', 80, 860, 'West Bank Gate');
  final e = b.start('e', 720, 860, 'East Bank Gate');
  final isle = b.node('isle', 400, 520, 'Reed Island', NodeKind.pier);
  final west = b.node('west', 140, 400, 'West Bank');
  final east = b.node('east', 660, 400, 'East Bank');
  final hall = b.shelter('hall', 400, 180, 'Twin Hall');
  b
    ..lane(s, isle, 'South Water', Block.none, Terrain.water)
    ..lane(w, west, 'West Rise')
    ..lane(e, east, 'East Rise')
    ..lane(isle, west, 'West Cut', Block.none, Terrain.water)
    ..lane(isle, east, 'East Cut', Block.none, Terrain.water)
    ..lane(west, hall, 'West Hall')
    ..lane(east, hall, 'East Hall')
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water);
  b.fire(isle);
  b.person(west);
  b.person(east);
  b.hazards.addAll(const [
    HazardEvent(220, HazardType.spread, from: 'isle', to: 'west'),
    HazardEvent(220, HazardType.spread, from: 'isle', to: 'east'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [west, east]);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Deliver + simultaneous calls / timed shelter capacity.
SceneBuilder m073() {
  final b = SceneBuilder('M073', 3, 13)
    ..title = 'Grain, Two Keepers, One Seat'
    ..brief =
        'One grain sack for Island Clinic. A miller and a slip keeper both need walking out. Tiny Boathouse seats one; Reed Chapel opens at sixteen seconds.'
    ..tutorial = [
      'Timed seats. Put one neighbour in the boathouse, wait for chapel, or ferry both after it opens.',
      'Sled on land. Marco on the clinic water.',
    ]
    ..strategies = [
      'Sled on Rosa to the west slip. Marco clinic. Tomi miller then chapel clock.',
      'Marco hauls one sack without the sled if Rosa is busy escorting.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.cargoSled]
    ..decor.addAll(['water:360,200,140,500', 'pier:500,200,80,40']);
  final mg = b.start('mg', 80, 1000, 'Mill Gate');
  final sg = b.start('sg', 400, 1000, 'South Slip');
  final eg = b.start('eg', 720, 980, 'East Keeper');
  final mill = b.depot('mill', 120, 700, 'River Mill', 1);
  final millerN = b.node('mn', 120, 480, 'Miller');
  final clinic = b.need('clinic', 600, 400, 'Island Clinic', 1);
  final keep = b.node('keep', 680, 700, 'Slip Keeper');
  final tiny = b.shelter('tiny', 400, 320, 'Tiny Boathouse', capacity: 1);
  final chapel = b.shelter('chapel', 400, 160, 'Reed Chapel', openAt: 160);
  b
    ..lane(mg, mill, 'Mill Rise')
    ..lane(sg, tiny, 'Slip Boat')
    ..lane(eg, keep, 'Keeper Rise')
    ..lane(mill, millerN, 'Mill Miller')
    ..lane(millerN, tiny, 'Miller Boat')
    ..lane(keep, tiny, 'Keeper Water', Block.none, Terrain.water)
    ..lane(tiny, 'clinic', 'Boat Clinic', Block.none, Terrain.water)
    ..lane(tiny, chapel, 'Boat Chapel')
    ..lane('clinic', chapel, 'Clinic Chapel', Block.none, Terrain.water)
    ..lane(keep, chapel, 'Keeper Chapel');
  b.person(millerN);
  b.person(keep);
  b.goal(ObjectiveType.delivered, target: clinic, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Inspect + stabilize / one constrained vehicle.
SceneBuilder m074() {
  final b = SceneBuilder('M074', 3, 14)
    ..title = 'One Boat, Hidden Miller'
    ..brief =
        'The miller is hidden on Reed Island in unlit reeds and needs care. The only way onto the island is water. One boat. Land crew lights from the bank if they carry the Floodlight to a water edge, or Marco carries it across.'
    ..tutorial = [
      'Constrained boat: only Marco steps onto the island.',
      'Floodlight on whoever can stand next to the dark cut.',
    ]
    ..strategies = [
      'Floodlight on Marco. Tomi waits at Reed Hall. Rosa spare on the bank.',
      'Floodlight on Rosa at the bank edge; Marco crosses after it opens.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['water:240,280,320,300', 'smoke:320,360,160,120']);
  final s = b.start('s', 400, 1000, 'South Slip', capacity: 2);
  final bnk = b.start('b', 80, 800, 'Bank Gate');
  final bank = b.node('bank', 160, 560, 'West Bank');
  final isle = b.node('isle', 400, 480, 'Reed Island', NodeKind.pier);
  final hall = b.shelter('hall', 400, 200, 'Reed Hall');
  b
    ..lane(s, isle, 'South Cut', Block.none, Terrain.water)
    ..lane(bnk, bank, 'Bank Rise')
    ..lane(bank, isle, 'Bank Fog', Block.dark)
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(bank, hall, 'Bank Hall');
  final miller = b.person(isle, care: true, critical: true, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['bank-isle']);
  b.goal(ObjectiveType.stabilized, target: miller);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Restore shelter + contain / shared resource.
SceneBuilder m075() {
  final b = SceneBuilder('M075', 3, 15)
    ..title = 'One Toolkit, Island Pitch'
    ..brief =
        'Ferry Hall is jammed and pitch burns on the island. One Toolkit, one Extinguisher. Shared tools: Bea repairs, Marco fights fire from the water.'
    ..tutorial = [
      'Shared Toolkit and Extinguisher. Do not stack both on one person unless you like waiting.',
      'Hall is land. Fire is water. Split the crew.',
    ]
    ..strategies = [
      'Toolkit on Bea at Hall Gate. Extinguisher on Marco at the slip.',
      'Rosa can take the Toolkit if Bea is sent to the island with water she cannot use.',
    ]
    ..teamSize = 3
    ..roles = _fix
    ..gear = [Gear.toolkit, Gear.extinguisher]
    ..decor.addAll(['water:400,280,280,360', 'pier:480,200,80,40']);
  final hg = b.start('hg', 80, 1000, 'Hall Gate');
  final sg = b.start('sg', 400, 1000, 'South Slip');
  final eg = b.start('eg', 720, 980, 'East Post');
  final hall = b.shelter('hall', 160, 480, 'Ferry Hall', broken: true);
  final isle = b.node('isle', 520, 480, 'Pitch Island', NodeKind.pier);
  final east = b.node('east', 700, 640, 'East Bank');
  b
    ..lane(hg, hall, 'Hall Rise')
    ..lane(sg, isle, 'Slip Island', Block.none, Terrain.water)
    ..lane(eg, east, 'East Rise')
    ..lane(hall, isle, 'Hall Water', Block.none, Terrain.water)
    ..lane(isle, east, 'Island East', Block.none, Terrain.water)
    ..lane(hall, east, 'Hall East', Block.debris);
  b.fire(isle);
  b.person(east);
  b.hazards.add(
    const HazardEvent(230, HazardType.spread, from: 'isle', to: 'east'),
  );
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Two teams + inspect / responder fatigue.
SceneBuilder m076() {
  final b = SceneBuilder('M076', 3, 16)
    ..title = 'Tired Bank, Hidden Island'
    ..brief =
        'A bank neighbour waits in the open. An island caller is hidden in fog. After two jobs everyone rests. Boat crew and bank crew should not share the same two jobs.'
    ..tutorial = [
      'Fatigue. Do not send Tomi to light, care, and escort all three tasks.',
      'Juno lights. Marco islands. Tomi banks.',
    ]
    ..strategies = [
      'Juno south slip with Floodlight backup unused. Marco island. Tomi bank.',
      'If Juno starts on the bank, Marco still has to cross for the hidden caller.',
    ]
    ..teamSize = 3
    ..roles = _scan
    ..gear = [Gear.floodlight]
    ..rules = const Rules(fatigueJobs: 2, restTicks: 40)
    ..decor.addAll(['water:280,300,240,280', 'smoke:320,360,160,100']);
  final s = b.start('s', 400, 1000, 'South Slip');
  final w = b.start('w', 80, 880, 'Bank Gate');
  final e = b.start('e', 720, 880, 'East Spare');
  final bank = b.node('bank', 140, 560, 'West Bank');
  final isle = b.node('isle', 400, 480, 'Fog Island', NodeKind.pier);
  final hall = b.shelter('hall', 400, 200, 'Bank Hall');
  b
    ..lane(s, isle, 'South Fog', Block.dark)
    ..lane(w, bank, 'Bank Rise')
    ..lane(e, hall, 'East Hall')
    ..lane(bank, isle, 'Bank Water', Block.none, Terrain.water)
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(bank, hall, 'Bank Hall Lane');
  b.person(bank);
  b.person(isle, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['s-isle']);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Protect + two teams / delayed hazard.
SceneBuilder m077() {
  final b = SceneBuilder('M077', 3, 17)
    ..title = 'Towpath Before the Flood'
    ..brief =
        'Towpath must stay clear of fire. Pitch at the west drum will reach it. The east approach floods at about twenty seconds and becomes water, splitting the land crew from the path unless they beat the clock or send Marco.'
    ..tutorial = [
      'Delayed flood on East Approach. Land responders lose that road.',
      'Protect Towpath. Island/boat is a second job from the drum.',
    ]
    ..strategies = [
      'Extinguisher on Rosa at the drum. Marco east water after the flood. Tomi towpath neighbour.',
      'Extinguisher on Marco via west water. Rosa holds the towpath.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['water:80,400,160,160', 'pier:320,240,80,40']);
  final d = b.start('d', 80, 1000, 'Drum Gate');
  final t = b.start('t', 400, 1000, 'Tow Gate');
  final e = b.start('e', 720, 980, 'East Gate');
  final drum = b.node('drum', 140, 640, 'West Drum');
  final tow = b.node('tow', 400, 480, 'Towpath');
  final east = b.node('east', 680, 640, 'East Approach');
  final hall = b.shelter('hall', 400, 200, 'Tow Hall');
  b
    ..lane(d, drum, 'Drum Rise')
    ..lane(t, tow, 'Tow Rise')
    ..lane(e, east, 'East Rise')
    ..lane(drum, tow, 'Drum Tow')
    ..lane(east, tow, 'East Approach')
    ..lane(drum, east, 'Drum Water', Block.none, Terrain.water)
    ..lane(tow, hall, 'Tow Hall Lane')
    ..lane(east, hall, 'East Hall');
  b.fire(drum);
  b.person(east);
  b.hazards.addAll(const [
    HazardEvent(200, HazardType.spread, from: 'drum', to: 'tow'),
    HazardEvent(
      200,
      HazardType.flood,
      edge: 'east-tow',
      note: 'East Approach takes on water',
    ),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [tow]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Two distinct simultaneous-call pairs / changing wind.
SceneBuilder m078() {
  final b = SceneBuilder('M078', 3, 18)
    ..title = 'Miller Call and Fog Call'
    ..brief =
        'Two separate call pairs: the miller on the west mill needs care, and a fog keeper on the east bank is hidden. Pitch on the island will follow the wind onto East Bank if it is not put out. These are not the same job copied twice.'
    ..tutorial = [
      'West mill is land care. East fog is inspect plus care. Island fire is a third clock.',
      'Wind then spread onto the east keeper\'s bank.',
    ]
    ..strategies = [
      'Extinguisher on Marco. Floodlight on Rosa east. Tomi west miller.',
      'If Marco starts east he still has to reach water before the spread.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.extinguisher, Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['water:300,280,200,300', 'smoke:520,400,200,140']);
  final w = b.start('w', 80, 1000, 'Mill Gate');
  final s = b.start('s', 400, 1000, 'South Slip');
  final e = b.start('e', 720, 980, 'Fog Gate');
  final mill = b.node('mill', 120, 640, 'West Mill');
  final isle = b.node('isle', 400, 500, 'Pitch Island', NodeKind.pier);
  final fog = b.node('fog', 680, 500, 'East Fog');
  final hall = b.shelter('hall', 400, 200, 'Pair Hall');
  b
    ..lane(w, mill, 'Mill Rise')
    ..lane(s, isle, 'Slip Island', Block.none, Terrain.water)
    ..lane(e, fog, 'Fog Rise')
    ..lane(mill, hall, 'Mill Hall')
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(fog, hall, 'Fog Hall', Block.dark)
    ..lane(isle, fog, 'Island Fog', Block.none, Terrain.water)
    ..lane(mill, isle, 'Mill Water', Block.none, Terrain.water);
  b.fire(isle);
  b.person(mill, care: true);
  b.person(fog, care: true, hidden: true);
  b.hazards.addAll(const [
    HazardEvent(90, HazardType.wind, note: 'Wind turns onto East Fog'),
    HazardEvent(230, HazardType.spread, from: 'isle', to: 'fog'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Evacuate + stabilize / limited equipment.
SceneBuilder m079() {
  final b = SceneBuilder('M079', 3, 19)
    ..title = 'One First Aid Kit'
    ..brief =
        'The island miller needs care, and two bank neighbours must walk to Reed Hall. Only one First Aid kit. The miller sits behind a fog plank Tomi can walk once it is lit, and also a water cut Marco can use.'
    ..tutorial = [
      'Limited kit. Tomi probably keeps it. Marco ferries the east neighbour.',
      'The miller is not water-only: light the west plank so Tomi can reach them.',
    ]
    ..strategies = [
      'Floodlight on Tomi to the plank. Marco east neighbour. Rosa west neighbour.',
      'Floodlight on Marco; he lights from the water edge, Tomi walks the plank.',
    ]
    ..roles = _syn
    ..teamSize = 3
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..decor.addAll([
      'water:240,600,320,120',
      'smoke:80,200,180,140',
      'pier:480,560,80,40',
    ]);
  final w = b.start('w', 80, 80, 'North Mill Gate');
  final s = b.start('s', 400, 80, 'North Slip');
  final e = b.start('e', 720, 200, 'East Bluff');
  final west = b.node('west', 80, 280, 'West Neighbour');
  final loft = b.node('loft', 80, 500, 'Mill Loft');
  final isle = b.node('isle', 480, 700, 'Island Miller', NodeKind.pier);
  final east = b.node('east', 720, 500, 'East Neighbour');
  final hall = b.shelter('hall', 400, 940, 'Reed Hall');
  b
    ..lane(w, west, 'West Drop')
    ..lane(s, loft, 'Slip Loft')
    ..lane(e, east, 'Bluff Drop')
    ..lane(west, loft, 'Neighbour Loft')
    ..lane(loft, isle, 'Loft Plank', Block.dark)
    ..lane(s, isle, 'Slip Water', Block.none, Terrain.water)
    ..lane(isle, east, 'Island East', Block.none, Terrain.water)
    ..lane(west, hall, 'West Hall', Block.debris)
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(east, hall, 'East Hall');
  final miller = b.person(isle, care: true, critical: true);
  b.person(west);
  b.person(east);
  b.goal(ObjectiveType.stabilized, target: miller);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Stabilize + contain / uncertain visibility.
SceneBuilder m080() {
  final b = SceneBuilder('M080', 3, 20)
    ..title = 'Fog Pitch and the Keeper'
    ..brief =
        'Pitch burns behind unlit island fog. The slip keeper on the east bank needs care. Light the island, put the fire out, steady the keeper.'
    ..tutorial = [
      'Uncertain visibility on the fire itself. You cannot fight what you cannot reach.',
      'Extinguisher on Marco. Tomi east keeper. Rosa spare light or land.',
    ]
    ..strategies = [
      'Floodlight and Extinguisher on Marco. Tomi east. Rosa west spare.',
      'Rosa lights the plank; Marco crosses water with water and the extinguisher.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.extinguisher, Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['water:240,300,280,280', 'smoke:300,360,160,120']);
  final s = b.start('s', 400, 1000, 'South Slip');
  final w = b.start('w', 80, 860, 'West Gate');
  final e = b.start('e', 720, 860, 'East Gate');
  final isle = b.node('isle', 400, 520, 'Fog Pitch', NodeKind.pier);
  final east = b.node('east', 680, 520, 'Slip Keeper');
  final hall = b.shelter('hall', 400, 200, 'Fog Hall');
  b
    ..lane(s, isle, 'South Fog', Block.dark)
    ..lane(w, isle, 'West Water', Block.none, Terrain.water)
    ..lane(e, east, 'East Rise')
    ..lane(isle, east, 'Island Keeper', Block.none, Terrain.water)
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(east, hall, 'Keeper Hall');
  b.fire(isle);
  final keep = b.person(east, care: true, critical: true);
  b.hazards.add(
    const HazardEvent(240, HazardType.spread, from: 'isle', to: 'east'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.stabilized, target: keep);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Open route + inspect / split starts. Team 4.
SceneBuilder m081() {
  final b = SceneBuilder('M081', 3, 21)
    ..title = 'Four Posts to North Landing'
    ..brief =
        'North Landing must be reachable on land from South Levee. Four posts, one responder each. Hidden reed callers sit on the west water-cut. Ferry Cross is shuttered.'
    ..tutorial = [
      'Split four ways. Rosa belongs on the cross. Juno or Floodlight on the reeds.',
      'Marco is the water spare. Tomi escorts.',
    ]
    ..strategies = [
      'Rosa south to the cross. Juno west reeds. Marco east water. Tomi north-side escort.',
      'Clear Ferry Cross; do not rely on water for the route stamp.',
    ]
    ..teamSize = 4
    ..roles = _quadScan
    ..gear = [Gear.cutter, Gear.floodlight]
    ..decor.addAll(['water:80,300,200,300', 'pier:360,80,80,40']);
  final s = b.start('s', 400, 80, 'South Levee');
  final w = b.start('w', 80, 200, 'Reed Post');
  final e = b.start('e', 720, 200, 'East Post');
  final n = b.start('n', 400, 980, 'North Spare');
  final cross = b.node('cross', 400, 400, 'Ferry Cross', NodeKind.junction);
  final reed = b.node('reed', 160, 560, 'West Reeds');
  final north = b.node('north', 400, 720, 'North Landing', NodeKind.pier);
  final hall = b.shelter('hall', 640, 560, 'Landing Hall');
  b
    ..lane(s, cross, 'South Cross')
    ..lane(w, reed, 'Reed Drop')
    ..lane(e, hall, 'East Hall')
    ..lane(n, north, 'North Drop')
    ..lane(cross, north, 'Ferry Cross', Block.debris)
    ..lane(reed, cross, 'Reed Cross', Block.dark)
    ..lane(reed, north, 'Reed Water', Block.none, Terrain.water)
    ..lane(north, hall, 'North Hall Lane')
    ..lane(cross, hall, 'Cross Hall');
  b.person(reed, hidden: true);
  b.goal(ObjectiveType.routeOpen, a: s, b: north);
  b.goal(ObjectiveType.revealed, nodes: ['reed-cross']);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Contain + two teams / two viable routes.
SceneBuilder m082() {
  final b = SceneBuilder('M082', 3, 22)
    ..title = 'Two Cuts to the Drum'
    ..brief =
        'West drum fire will reach Towpath. West cut is land. East cut is water. Either route lets the Extinguisher arrive. Bank crew holds the towpath neighbour either way.'
    ..tutorial = [
      'Two viable routes to the drum. Boat or boots.',
      'Protect Towpath. Split: one fighter, one holder, two spare.',
    ]
    ..strategies = [
      'Extinguisher on Rosa west. Marco east spare. Tomi towpath. Bea shutters.',
      'Extinguisher on Marco east water. Rosa holds land.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.extinguisher, Gear.cutter]
    ..decor.addAll(['water:480,240,220,400', 'pier:520,160,80,40']);
  final w = b.start('w', 80, 80, 'West Post');
  final t = b.start('t', 400, 80, 'Tow Post');
  final e = b.start('e', 720, 80, 'East Slip');
  final s = b.start('s', 400, 980, 'South Spare');
  final drum = b.node('drum', 160, 400, 'West Drum');
  final tow = b.node('tow', 400, 400, 'Towpath');
  final slip = b.node('slip', 680, 400, 'East Slip', NodeKind.pier);
  final hall = b.shelter('hall', 400, 720, 'South Hall');
  b
    ..lane(w, drum, 'West Drum Lane')
    ..lane(t, tow, 'Tow Drop')
    ..lane(e, slip, 'East Drop')
    ..lane(s, hall, 'South Hall Lane')
    ..lane(drum, tow, 'Drum Tow')
    ..lane(slip, drum, 'Slip Drum', Block.none, Terrain.water)
    ..lane(tow, hall, 'Tow Hall')
    ..lane(slip, hall, 'Slip Hall', Block.none, Terrain.water)
    ..lane(drum, hall, 'Drum Hall', Block.debris);
  b.fire(drum);
  b.person(tow);
  b.hazards.add(
    const HazardEvent(210, HazardType.spread, from: 'drum', to: 'tow'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [tow]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Deliver + simultaneous calls / blocked junction.
SceneBuilder m083() {
  final b = SceneBuilder('M083', 3, 23)
    ..title = 'Grain at the Shuttered Cross'
    ..brief =
        'Two sacks for Island Clinic. A miller and a slip keeper both wait. Ferry Cross is shuttered, so the sled cannot turn toward the clinic slip until that junction is cleared.'
    ..tutorial = [
      'Blocked junction on the clinic turn. Clear it or send Marco the long water from the mill.',
      'Two calls plus delivery. Four people.',
    ]
    ..strategies = [
      'Rosa on the cross. Sled on Bea. Tomi miller. Marco keeper and clinic water.',
      'Skip the cross: mill-water-clinic with Marco carrying one at a time.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.cargoSled, Gear.cutter]
    ..decor.addAll(['water:400,480,280,200', 'pier:560,400,80,40']);
  final m = b.start('m', 80, 80, 'Mill Post');
  final c = b.start('c', 400, 80, 'Cross Post');
  final k = b.start('k', 720, 80, 'Keeper Post');
  final s = b.start('s', 400, 980, 'South Slip');
  final mill = b.depot('mill', 140, 320, 'River Mill', 2);
  final millerN = b.node('mn', 140, 520, 'Miller');
  final cross = b.node('cross', 400, 320, 'Ferry Cross', NodeKind.junction);
  final clinic = b.need('clinic', 640, 520, 'Island Clinic', 2);
  final keep = b.node('keep', 700, 320, 'Slip Keeper');
  final hall = b.shelter('hall', 400, 720, 'South Hall');
  b
    ..lane(m, mill, 'Mill Drop')
    ..lane(c, cross, 'Cross Drop')
    ..lane(k, keep, 'Keeper Drop')
    ..lane(s, hall, 'Slip Hall Lane')
    ..lane(mill, millerN, 'Mill Miller')
    ..lane(mill, cross, 'Mill Cross')
    ..lane(cross, 'clinic', 'Cross Clinic', Block.debris)
    ..lane(keep, 'clinic', 'Keeper Clinic', Block.none, Terrain.water)
    ..lane(mill, 'clinic', 'Mill Water', Block.none, Terrain.water)
    ..lane(millerN, hall, 'Miller Hall')
    ..lane(keep, hall, 'Keeper Hall')
    ..lane('clinic', hall, 'Clinic Hall', Block.none, Terrain.water);
  b.person(millerN);
  b.person(keep);
  b.goal(ObjectiveType.delivered, target: clinic, count: 2);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Inspect + stabilize / branching access.
SceneBuilder m084() {
  final b = SceneBuilder('M084', 3, 24)
    ..title = 'West Fog, East Reeds'
    ..brief =
        'Two hidden keepers need care: west fog mill and east reed loft. Branching: lighting west does not light east. Water sits between them for Marco.'
    ..tutorial = [
      'Branching fog. One Floodlight. Marco can stand on a water edge to light the other fork.',
      'Tomi still steadies both. First Aid on a second carer if she is far.',
    ]
    ..strategies = [
      'Floodlight on Rosa west. Marco east water. Tomi follows the first open fork. Bea spare.',
      'Marco lights both from the mid cut. Tomi only cares.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..decor.addAll([
      'smoke:40,360,200,200',
      'smoke:560,360,200,200',
      'water:300,400,200,80',
    ]);
  final n = b.start('n', 400, 80, 'North Hall Gate', capacity: 2);
  final w = b.start('w', 80, 200, 'West Fog Post');
  final e = b.start('e', 720, 200, 'East Reed Post');
  final hall = b.shelter('hall', 400, 280, 'North Hall');
  final west = b.node('west', 140, 560, 'West Fog');
  final east = b.node('east', 660, 560, 'East Reeds');
  final mid = b.node('mid', 400, 560, 'Mid Cut', NodeKind.pier);
  b
    ..lane(n, hall, 'Gate Hall')
    ..lane(w, west, 'West Drop')
    ..lane(e, east, 'East Drop')
    ..lane(hall, west, 'Hall West', Block.dark)
    ..lane(hall, east, 'Hall East', Block.dark)
    ..lane(west, mid, 'West Water', Block.none, Terrain.water)
    ..lane(east, mid, 'East Water', Block.none, Terrain.water)
    ..lane(mid, hall, 'Mid Hall', Block.none, Terrain.water);
  final a = b.person(west, care: true, hidden: true);
  final c = b.person(east, care: true, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['hall-west', 'hall-east']);
  b.goal(ObjectiveType.stabilized, target: a);
  b.goal(ObjectiveType.stabilized, target: c);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Restore shelter + contain / timed capacity.
SceneBuilder m085() {
  final b = SceneBuilder('M085', 3, 25)
    ..title = 'Ferry Hall and the Tiny Slip'
    ..brief =
        'Ferry Hall is jammed. Pitch on the island will reach East Bank. Tiny Slip seats one and is open; Reed Chapel opens at fourteen seconds. Repair, fight fire, seat people on the clock.'
    ..tutorial = [
      'Tiny Slip holds one. Chapel is the second seat and the clock.',
      'Bea on the hall door. Extinguisher on Marco.',
    ]
    ..strategies = [
      'Bea hall. Marco island. Tomi first neighbour to Tiny Slip. Rosa chapel clock.',
      'Put the fire out before walking anyone along East Bank.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.toolkit, Gear.extinguisher]
    ..decor.addAll(['water:400,300,240,280', 'pier:480,220,80,40']);
  final h = b.start('h', 80, 80, 'Hall Post');
  final s = b.start('s', 400, 80, 'South Slip');
  final e = b.start('e', 720, 80, 'East Post');
  final t = b.start('t', 400, 980, 'Chapel Spare');
  final hall = b.shelter('hall', 160, 360, 'Ferry Hall', broken: true);
  final isle = b.node('isle', 520, 400, 'Pitch Island', NodeKind.pier);
  final east = b.node('east', 700, 400, 'East Bank');
  final tiny = b.shelter('tiny', 400, 600, 'Tiny Slip', capacity: 1);
  final chapel = b.shelter('chapel', 400, 820, 'Reed Chapel', openAt: 140);
  b
    ..lane(h, hall, 'Hall Drop')
    ..lane(s, isle, 'Slip Island', Block.none, Terrain.water)
    ..lane(e, east, 'East Drop')
    ..lane(t, chapel, 'Chapel Drop')
    ..lane(hall, isle, 'Hall Water', Block.none, Terrain.water)
    ..lane(isle, east, 'Island East', Block.none, Terrain.water)
    ..lane(east, tiny, 'East Tiny')
    ..lane(tiny, chapel, 'Tiny Chapel')
    ..lane(hall, tiny, 'Hall Tiny')
    ..lane(east, chapel, 'East Chapel');
  b.fire(isle);
  b.person(east);
  b.person(hall);
  b.hazards.add(
    const HazardEvent(220, HazardType.spread, from: 'isle', to: 'east'),
  );
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Two teams + inspect / one constrained vehicle.
SceneBuilder m086() {
  final b = SceneBuilder('M086', 3, 26)
    ..title = 'One Boat, Two Jobs'
    ..brief =
        'A hidden island caller and a land mill neighbour. Only Marco steps on water. The sled is on land for a spare sack at Island Clinic — one sack, one boat, two jobs that contend for Marco.'
    ..tutorial = [
      'Dependent: if Marco hauls first, the hidden caller waits. If he lights first, the sack waits.',
      'Sled can wait at the slip for him. Rosa cannot cross.',
    ]
    ..strategies = [
      'Marco island first with Floodlight. Sled on Rosa to the slip. Tomi mill. Bea spare.',
      'Marco sack first if the clinic clock feels tighter than the fog.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.cargoSled, Gear.floodlight]
    ..decor.addAll(['water:280,280,280,280', 'smoke:320,360,140,100']);
  final m = b.start('m', 80, 80, 'Mill Post');
  final s = b.start('s', 400, 80, 'South Slip', capacity: 2);
  final e = b.start('e', 720, 80, 'East Post');
  final millN = b.node('mn', 140, 360, 'Mill Neighbour');
  final depot = b.depot('dep', 140, 560, 'Mill Bay', 1);
  final isle = b.node('isle', 400, 480, 'Fog Island', NodeKind.pier);
  final clinic = b.need('clinic', 640, 480, 'Island Clinic', 1);
  final hall = b.shelter('hall', 400, 780, 'South Hall');
  b
    ..lane(m, millN, 'Mill Drop')
    ..lane(s, isle, 'South Fog', Block.dark)
    ..lane(e, 'clinic', 'East Clinic', Block.none, Terrain.water)
    ..lane(millN, depot, 'Neighbour Bay')
    ..lane(depot, isle, 'Bay Slip')
    ..lane(isle, 'clinic', 'Island Clinic Water', Block.none, Terrain.water)
    ..lane(millN, hall, 'Mill Hall')
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane('clinic', hall, 'Clinic Hall', Block.none, Terrain.water);
  b.person(millN);
  b.person(isle, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['s-isle']);
  b.goal(ObjectiveType.delivered, target: clinic, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Protect + two teams / shared resource.
SceneBuilder m087() {
  final b = SceneBuilder('M087', 3, 27)
    ..title = 'Shared Pump, Split Crews'
    ..brief =
        'Towpath must stay clear. Drum fire west. One Extinguisher. Boat crew can hit the drum from the water; bank crew holds the towpath neighbour. They share the pump, not a lane.'
    ..tutorial = [
      'Shared Extinguisher. Two crews. Do not send everyone onto the boat.',
      'Protect Towpath. Island water is the other approach.',
    ]
    ..strategies = [
      'Extinguisher on Rosa at Drum Post. Marco east water spare. Tomi towpath. Bea shutters.',
      'Extinguisher on Marco. Rosa holds land if the spread is late.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['water:480,300,220,280', 'pier:520,220,80,40']);
  final d = b.start('d', 80, 80, 'Drum Post');
  final t = b.start('t', 400, 80, 'Tow Post');
  final e = b.start('e', 720, 80, 'East Slip');
  final s = b.start('s', 400, 980, 'South Spare');
  final drum = b.node('drum', 140, 400, 'West Drum');
  final tow = b.node('tow', 400, 400, 'Towpath');
  final slip = b.node('slip', 680, 400, 'East Water', NodeKind.pier);
  final hall = b.shelter('hall', 400, 720, 'South Hall');
  b
    ..lane(d, drum, 'Drum Drop')
    ..lane(t, tow, 'Tow Drop')
    ..lane(e, slip, 'Slip Drop')
    ..lane(s, hall, 'South Hall Lane')
    ..lane(drum, tow, 'Drum Tow')
    ..lane(slip, drum, 'Water Drum', Block.none, Terrain.water)
    ..lane(tow, hall, 'Tow Hall')
    ..lane(slip, hall, 'Slip Hall', Block.none, Terrain.water);
  b.fire(drum);
  b.person(tow);
  b.hazards.add(
    const HazardEvent(200, HazardType.spread, from: 'drum', to: 'tow'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [tow]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Two distinct call pairs / responder fatigue.
SceneBuilder m088() {
  final b = SceneBuilder('M088', 3, 28)
    ..title = 'Four Calls, Tired Ferry'
    ..brief =
        'Two pairs: west miller and west loft neighbour (land care), east fog keeper and island reed (inspect plus water). After two jobs everyone rests. These are four people, not one objective written twice.'
    ..tutorial = [
      'Fatigue will punish anyone who tries all four cares.',
      'Tomi cannot be everywhere. First Aid lets a second person steady.',
    ]
    ..strategies = [
      'Tomi west mill. First Aid on Rosa west loft. Marco island. Floodlight on Bea east fog.',
      'Marco island and east. Tomi only the mill pair. Rosa escorts.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..rules = const Rules(fatigueJobs: 2, restTicks: 40)
    ..decor.addAll(['water:360,360,160,200', 'smoke:520,480,200,160']);
  final w = b.start('w', 80, 80, 'Mill Post');
  final n = b.start('n', 400, 80, 'North Spare');
  final e = b.start('e', 720, 80, 'Fog Post');
  final s = b.start('s', 400, 980, 'South Slip');
  final mill = b.node('mill', 140, 320, 'West Miller');
  final loft = b.node('loft', 140, 560, 'West Loft');
  final fog = b.node('fog', 680, 400, 'East Fog');
  final isle = b.node('isle', 400, 500, 'Island Reed', NodeKind.pier);
  final hall = b.shelter('hall', 400, 780, 'South Hall');
  b
    ..lane(w, mill, 'Mill Drop')
    ..lane(n, hall, 'North Hall', Block.debris)
    ..lane(e, fog, 'Fog Drop')
    ..lane(s, isle, 'Slip Island', Block.none, Terrain.water)
    ..lane(mill, loft, 'Miller Loft')
    ..lane(loft, hall, 'Loft Hall')
    ..lane(fog, hall, 'Fog Hall', Block.dark)
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(isle, fog, 'Island Fog', Block.none, Terrain.water)
    ..lane(mill, hall, 'Mill Hall');
  b.person(mill, care: true);
  b.person(loft, care: true);
  b.person(fog, care: true, hidden: true);
  b.person(isle);
  b.goal(ObjectiveType.civiliansSafe, count: 4);
  return b;
}

/// Evacuate + stabilize / delayed hazard.
SceneBuilder m089() {
  final b = SceneBuilder('M089', 3, 29)
    ..title = 'Levee Flood at Dusk'
    ..brief =
        'The island miller needs care. Two bank neighbours walk out. Levee Path floods at about twenty-two seconds and becomes water, cutting land access to Reed Hall from the west.'
    ..tutorial = [
      'Delayed flood on Levee Path. Beat it on foot or send Marco after it turns.',
      'Tomi must reach the miller on the fog plank or wait for Marco.',
    ]
    ..strategies = [
      'Tomi west plank to the miller before or after light. Rosa east neighbour. Marco ready for the flood. Bea hall.',
      'Ignore the levee; walk everyone east after Marco ferries the miller.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['water:300,360,200,160', 'smoke:280,280,140,80']);
  final w = b.start('w', 80, 80, 'West Post');
  final s = b.start('s', 400, 80, 'South Slip');
  final e = b.start('e', 720, 80, 'East Post');
  final h = b.start('h', 400, 980, 'Hall Post');
  final west = b.node('west', 140, 360, 'West Neighbour');
  final isle = b.node('isle', 400, 400, 'Island Miller', NodeKind.pier);
  final east = b.node('east', 680, 360, 'East Neighbour');
  final levee = b.node('levee', 140, 640, 'Levee Path');
  final hall = b.shelter('hall', 400, 720, 'Reed Hall');
  b
    ..lane(w, west, 'West Drop')
    ..lane(s, isle, 'Slip Water', Block.none, Terrain.water)
    ..lane(e, east, 'East Drop')
    ..lane(h, hall, 'Hall Drop')
    ..lane(west, isle, 'West Plank', Block.dark)
    ..lane(west, levee, 'West Levee')
    ..lane(levee, hall, 'Levee Path')
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(east, hall, 'East Hall');
  final miller = b.person(isle, care: true, critical: true);
  b.person(west);
  b.person(east);
  b.hazards.add(
    const HazardEvent(
      220,
      HazardType.flood,
      edge: 'levee-hall',
      note: 'Levee Path takes on water',
    ),
  );
  b.goal(ObjectiveType.stabilized, target: miller);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Finale: stabilize + contain / changing wind.
SceneBuilder m090() {
  final b = SceneBuilder('M090', 3, 30)
    ..title = 'Riverside Night'
    ..brief =
        'The miller on Fog Island needs care. Pitch there will follow two wind turns onto East Bank, which must stay clear, then onto Night Hall. Light the island, put the fire out, walk everyone home. This is the Riverside finale.'
    ..tutorial = [
      'Finale: fog, fire, care, two wind notes.',
      'Extinguisher and Floodlight belong on the boat or on the plank team.',
    ]
    ..strategies = [
      'Marco south with both tools. Tomi east keeper. Rosa west. Bea spare land.',
      'Rosa lights the plank; Marco water with the Extinguisher; Tomi only cares.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.extinguisher, Gear.floodlight, Gear.firstAid]
    ..decor.addAll([
      'water:240,280,320,280',
      'smoke:300,360,180,120',
      'pier:360,160,80,40',
    ]);
  final s = b.start('s', 400, 80, 'Night Slip', capacity: 2);
  final w = b.start('w', 80, 200, 'West Post');
  final e = b.start('e', 720, 200, 'East Post');
  final isle = b.node('isle', 400, 420, 'Fog Island', NodeKind.pier);
  final east = b.node('east', 680, 420, 'East Bank');
  final west = b.node('west', 140, 420, 'West Bank');
  final hall = b.shelter('hall', 400, 780, 'Night Hall');
  b
    ..lane(s, isle, 'Night Fog', Block.dark)
    ..lane(w, west, 'West Drop')
    ..lane(e, east, 'East Drop')
    ..lane(west, isle, 'West Water', Block.none, Terrain.water)
    ..lane(isle, east, 'Island East', Block.none, Terrain.water)
    ..lane(west, hall, 'West Hall')
    ..lane(east, hall, 'East Hall')
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water);
  b.fire(isle);
  final miller = b.person(isle, care: true, critical: true, hidden: true);
  b.person(east);
  b.person(west);
  b.hazards.addAll(const [
    HazardEvent(70, HazardType.wind, note: 'Wind turns onto East Bank'),
    HazardEvent(200, HazardType.spread, from: 'isle', to: 'east'),
    HazardEvent(250, HazardType.wind, note: 'Wind turns onto Night Hall'),
    HazardEvent(340, HazardType.spread, from: 'east', to: 'hall'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [east]);
  b.goal(ObjectiveType.stabilized, target: miller);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

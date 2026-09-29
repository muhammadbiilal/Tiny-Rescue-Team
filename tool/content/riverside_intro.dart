// Riverside M061-M070. Marco Reyes (Boat Pilot at 61) is the only water walker.
import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

import 'builder.dart';

const _boatCut = [Role.boatPilot, Role.rescuer];
const _boatCare = [Role.boatPilot, Role.medic];
const _boatFix = [Role.boatPilot, Role.engineer];
const _boatScan = [Role.boatPilot, Role.scout];

List<SceneBuilder> riversideIntro() => [
  m061(),
  m062(),
  m063(),
  m064(),
  m065(),
  m066(),
  m067(),
  m068(),
  m069(),
  m070(),
];

/// Open a safe route / timed shelter capacity.
SceneBuilder m061() {
  final b = SceneBuilder('M061', 3, 1)
    ..title = 'Ferry Cut at High Water'
    ..brief =
        'North Landing must be reachable from South Levee. The oxbow is water: only Marco Reyes can cross it. Tiny Boathouse seats one and is open; Reed Chapel opens at fifteen seconds.'
    ..tutorial = [
      'Marco Reyes joins the free team. He is the only responder who can travel water lanes.',
      'Tiny Boathouse holds one neighbour. The second waits for Reed Chapel.',
    ]
    ..strategies = [
      'Marco across the oxbow. Rosa clears Levee Shutters on the land road.',
      'Ignore shutters: Marco ferries both neighbours after the chapel opens.',
    ]
    ..roles = _boatCut
    ..decor.addAll(['water:340,200,120,640', 'pier:300,140,80,60']);
  final south = b.start('south', 160, 1000, 'South Levee');
  final east = b.start('east', 640, 1000, 'East Bank');
  final levee = b.node('levee', 160, 700, 'Levee Path');
  final ox = b.node('ox', 400, 560, 'Oxbow', NodeKind.pier);
  final land = b.node('land', 640, 700, 'Towpath');
  final north = b.node('north', 400, 160, 'North Landing', NodeKind.pier);
  final tiny = b.shelter('tiny', 160, 400, 'Tiny Boathouse', capacity: 1);
  final chapel = b.shelter('chapel', 640, 400, 'Reed Chapel', openAt: 150);
  b
    ..lane(south, levee, 'Levee Rise')
    ..lane(east, land, 'Bank Rise')
    ..lane(levee, ox, 'Levee Oxbow', Block.none, Terrain.water)
    ..lane(land, ox, 'Towpath Oxbow', Block.none, Terrain.water)
    ..lane(ox, north, 'Oxbow North', Block.none, Terrain.water)
    ..lane(levee, tiny, 'Levee Boat')
    ..lane(land, chapel, 'Towpath Chapel')
    ..lane(levee, land, 'Levee Shutters', Block.debris)
    ..lane(tiny, north, 'Boat North', Block.debris)
    ..lane(chapel, north, 'Chapel North');
  b.person(levee);
  b.person(land);
  b.goal(ObjectiveType.routeOpen, a: south, b: north);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Contain / one constrained vehicle (the boat).
SceneBuilder m062() {
  final b = SceneBuilder('M062', 3, 2)
    ..title = 'One Boat to the Pitch Fire'
    ..brief =
        'Pitch smolders on Reed Island. The only way onto the island is water. One Extinguisher. Marco is the constrained boat; Rosa cannot wet her boots.'
    ..tutorial = [
      'The boat is the constrained vehicle. Whoever does not ride still works the bank.',
      'Give the Extinguisher to Marco or he cannot put the pitch out.',
    ]
    ..strategies = [
      'Extinguisher on Marco at West Slip. Rosa holds the reed bank.',
      'If Marco starts east, he still has to reach a water lane.',
    ]
    ..roles = _boatCut
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['water:280,300,240,400', 'pier:360,240,80,50']);
  final w = b.start('w', 80, 1000, 'West Slip');
  final e = b.start('e', 720, 1000, 'East Slip');
  final bank = b.node('bank', 160, 640, 'Reed Bank');
  final island = b.node('isle', 400, 480, 'Reed Island', NodeKind.pier);
  final eastB = b.node('eb', 640, 640, 'East Bank');
  final hall = b.shelter('hall', 400, 200, 'Reed Hall');
  b
    ..lane(w, bank, 'West Rise')
    ..lane(e, eastB, 'East Rise')
    ..lane(bank, island, 'West Cut', Block.none, Terrain.water)
    ..lane(eastB, island, 'East Cut', Block.none, Terrain.water)
    ..lane(island, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(bank, hall, 'Bank Hall', Block.debris)
    ..lane(eastB, hall, 'East Hall');
  b.fire(island);
  b.person(eastB);
  b.hazards.add(
    const HazardEvent(240, HazardType.spread, from: 'isle', to: 'eb'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [eastB]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Deliver / shared resource.
SceneBuilder m063() {
  final b = SceneBuilder('M063', 3, 3)
    ..title = 'Shared Sled, Shared Boat'
    ..brief =
        'Two grain sacks in the mill must reach the island clinic. One Cargo Sled. The clinic sits across water, so the sled still needs Marco on the last cut.'
    ..tutorial = [
      'Shared sled on land. Shared boat on water. Rosa can haul to the slip; only Marco crosses.',
      'Marco can carry one sack without the sled. Two sacks need the sled plus a second trip, or Rosa to the slip and Marco across.',
    ]
    ..strategies = [
      'Sled on Rosa to the west slip. Marco waits on the water and takes both loads over.',
      'Sled on Marco: he hauls and crosses. Rosa clears the mill shutter.',
    ]
    ..roles = _boatCut
    ..gear = [Gear.cargoSled]
    ..decor.addAll(['water:360,200,140,560', 'pier:500,240,90,50']);
  final millG = b.start('mg', 80, 1000, 'Mill Gate');
  final slip = b.start('slip', 720, 980, 'Clinic Slip');
  final mill = b.depot('mill', 120, 680, 'River Mill', 2);
  final west = b.node('west', 200, 400, 'West Slip', NodeKind.pier);
  final clinic = b.need('clinic', 600, 360, 'Island Clinic', 2);
  final hall = b.shelter('hall', 400, 160, 'Mill Hall');
  b
    ..lane(millG, mill, 'Mill Rise')
    ..lane(slip, 'clinic', 'Slip Clinic', Block.none, Terrain.water)
    ..lane(mill, west, 'Mill Slip')
    ..lane(west, 'clinic', 'Slip Water', Block.none, Terrain.water)
    ..lane(mill, hall, 'Mill Hall Lane', Block.debris)
    ..lane(west, hall, 'Slip Hall', Block.none, Terrain.water)
    ..lane('clinic', hall, 'Clinic Hall', Block.none, Terrain.water);
  b.goal(ObjectiveType.delivered, target: clinic, count: 2);
  return b;
}

/// Inspect / responder fatigue.
SceneBuilder m064() {
  final b = SceneBuilder('M064', 3, 4)
    ..title = 'Fog on Both Banks'
    ..brief =
        'Callers are hidden in west reeds and east fog. Both banks are unlit. After two jobs a responder rests. Marco can cross; Juno lights.'
    ..tutorial = [
      'Inspect both banks. Lighting one does not light the other.',
      'Fatigue after two tasks. Split the banks.',
    ]
    ..strategies = [
      'Juno west reeds. Marco east across the water after she opens one side.',
      'Juno both banks; Marco only ferries.',
    ]
    ..roles = _boatScan
    ..rules = const Rules(fatigueJobs: 2, restTicks: 40)
    ..gear = [Gear.floodlight]
    ..decor.addAll(['water:340,240,120,520', 'smoke:80,400,180,160']);
  final w = b.start('w', 80, 1000, 'West Reed');
  final e = b.start('e', 720, 1000, 'East Fog');
  final reed = b.node('reed', 140, 640, 'West Reeds');
  final fog = b.node('fog', 660, 640, 'East Fog');
  final deepW = b.node('dw', 140, 360, 'Deep Reeds');
  final deepE = b.node('de', 660, 360, 'Deep Fog');
  final hall = b.shelter('hall', 400, 200, 'Reed Hall');
  final mid = b.node('mid', 400, 500, 'Mid Water', NodeKind.pier);
  b
    ..lane(w, reed, 'West Rise')
    ..lane(e, fog, 'East Rise')
    ..lane(reed, deepW, 'Reed Fog', Block.dark)
    ..lane(fog, deepE, 'Fog Bank', Block.dark)
    ..lane(reed, mid, 'Reed Water', Block.none, Terrain.water)
    ..lane(fog, mid, 'Fog Water', Block.none, Terrain.water)
    ..lane(mid, hall, 'Mid Hall', Block.none, Terrain.water)
    ..lane(deepW, hall, 'Deep West Hall', Block.dark)
    ..lane(deepE, hall, 'Deep East Hall', Block.dark);
  b.person(deepW, hidden: true);
  b.person(deepE, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['reed-dw', 'fog-de']);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Restore shelter / delayed hazard.
SceneBuilder m065() {
  final b = SceneBuilder('M065', 3, 5)
    ..title = 'Jammed Ferry Hall'
    ..brief =
        'Ferry Hall\'s door is jammed. The levee path is expected to flood at about twenty seconds, turning that road into water. Repair before the flood, or send Marco the long slip.'
    ..tutorial = [
      'Delayed flood: a land road becomes water. Marco can still use it. Bea cannot.',
      'Toolkit helps Rosa. Bea can repair without it.',
    ]
    ..strategies = [
      'Bea at Hall Gate. Marco on the slip in case the levee floods.',
      'Repair first, walk the levee before the water arrives.',
    ]
    ..roles = _boatFix
    ..gear = [Gear.toolkit]
    ..decor.addAll(['water:480,160,200,200', 'pier:80,200,80,50']);
  final hg = b.start('hg', 160, 1000, 'Hall Gate');
  final sg = b.start('sg', 640, 1000, 'Slip Gate');
  final levee = b.node('levee', 200, 640, 'Levee Path');
  final hall = b.shelter('hall', 200, 320, 'Ferry Hall', broken: true);
  final slip = b.node('slip', 640, 560, 'Back Slip', NodeKind.pier);
  b
    ..lane(hg, levee, 'Gate Levee')
    ..lane(sg, slip, 'Gate Slip')
    ..lane(levee, hall, 'Levee Hall')
    ..lane(slip, hall, 'Slip Hall', Block.none, Terrain.water)
    ..lane(levee, slip, 'Levee Slip', Block.debris);
  b.person(slip);
  b.hazards.add(
    const HazardEvent(
      200,
      HazardType.flood,
      edge: 'levee-hall',
      note: 'Levee path takes on water',
    ),
  );
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Two dependent teams / changing wind.
SceneBuilder m066() {
  final b = SceneBuilder('M066', 3, 6)
    ..title = 'Bank Crew and Boat Crew'
    ..brief =
        'Pitch on the island will follow the wind onto East Bank, which must stay clear. The island is water-only. Rosa works the bank; Marco works the boat. They do not share a lane until the fire is dead or the bank is held.'
    ..tutorial = [
      'Two jobs: island fire and bank escort. Marco cannot be in both places at tick zero.',
      'Wind then spread. Extinguisher belongs on the boat.',
    ]
    ..strategies = [
      'Extinguisher on Marco west slip. Rosa east bank with the neighbour.',
      'If Marco starts east he still has to reach water before the spread.',
    ]
    ..roles = _boatCut
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['water:300,280,200,360', 'pier:360,200,80,50']);
  final w = b.start('w', 80, 1000, 'West Slip');
  final e = b.start('e', 720, 980, 'East Bank Gate');
  final island = b.node('isle', 400, 520, 'Pitch Island', NodeKind.pier);
  final east = b.node('east', 680, 520, 'East Bank');
  final hall = b.shelter('hall', 400, 200, 'Bank Hall');
  b
    ..lane(w, island, 'West Water', Block.none, Terrain.water)
    ..lane(e, east, 'East Rise')
    ..lane(island, east, 'Island Bank', Block.none, Terrain.water)
    ..lane(island, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(east, hall, 'East Hall');
  b.fire(island);
  b.person(east);
  b.hazards.addAll(const [
    HazardEvent(80, HazardType.wind, note: 'Wind turns onto East Bank'),
    HazardEvent(210, HazardType.spread, from: 'isle', to: 'east'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [east]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Protect corridor / limited equipment.
SceneBuilder m067() {
  final b = SceneBuilder('M067', 3, 7)
    ..title = 'One Extinguisher on the Towpath'
    ..brief =
        'Towpath must stay open. A drum fire at the west slip will reach it. One Extinguisher. The short cut is water.'
    ..tutorial = [
      'Limited Extinguisher. Give it to Marco if he starts on the slip, or to Rosa if she starts on the drum.',
      'Protect Towpath. Fire there fails the mission.',
    ]
    ..strategies = [
      'Extinguisher on Rosa at Drum Gate. Marco holds the far bank.',
      'Extinguisher on Marco: he crosses and hits the drum from the water.',
    ]
    ..roles = _boatCut
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['water:80,420,640,90', 'pier:200,380,80,40']);
  final d = b.start('d', 80, 80, 'North Drum');
  final t = b.start('t', 720, 80, 'North Tow');
  final drum = b.node('drum', 200, 300, 'Drum Slip');
  final tow = b.node('tow', 500, 300, 'High Towpath');
  final far = b.node('far', 700, 560, 'South Bank');
  final bend = b.node('bend', 200, 560, 'River Bend', NodeKind.pier);
  final hall = b.shelter('hall', 450, 900, 'Tow Hall');
  b
    ..lane(d, drum, 'Drum Drop')
    ..lane(t, tow, 'Tow Drop')
    ..lane(drum, tow, 'Drum Tow')
    ..lane(drum, bend, 'Drum Bend', Block.none, Terrain.water)
    ..lane(tow, far, 'Tow Far', Block.none, Terrain.water)
    ..lane(bend, far, 'Bend Far', Block.none, Terrain.water)
    ..lane(tow, hall, 'Tow Hall Lane', Block.debris)
    ..lane(far, hall, 'Far Hall')
    ..lane(bend, hall, 'Bend Hall');
  b.fire(drum);
  b.person(far);
  b.hazards.add(
    const HazardEvent(200, HazardType.spread, from: 'drum', to: 'tow'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [tow]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Simultaneous calls / uncertain visibility.
SceneBuilder m068() {
  final b = SceneBuilder('M068', 3, 8)
    ..title = 'Reed Call and Fog Call'
    ..brief =
        'A reed keeper west needs care. A fog keeper east is hidden in unlit reeds. Two calls, two banks, water in the middle.'
    ..tutorial = [
      'Tomi steadies. Marco crosses. The east keeper does not appear until the fog lane is lit.',
      'Floodlight or Juno would help; here Marco still has to get close or carry the light.',
    ]
    ..strategies = [
      'Floodlight on Marco east. Tomi west with the reed keeper.',
      'Floodlight on Tomi if she starts east; Marco ferries the west keeper.',
    ]
    ..roles = _boatCare
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['water:340,300,120,400', 'smoke:520,400,200,160']);
  final w = b.start('w', 80, 1000, 'Reed Gate');
  final e = b.start('e', 720, 980, 'Fog Gate');
  final reed = b.node('reed', 140, 620, 'Reed Keeper');
  final fog = b.node('fog', 660, 500, 'Fog Keeper');
  final hall = b.shelter('hall', 400, 240, 'Reed Hall');
  final mid = b.node('mid', 400, 620, 'Mid Cut', NodeKind.pier);
  b
    ..lane(w, reed, 'Reed Rise')
    ..lane(e, fog, 'Fog Rise')
    ..lane(reed, mid, 'Reed Water', Block.none, Terrain.water)
    ..lane(fog, mid, 'Fog Water', Block.dark)
    ..lane(mid, hall, 'Mid Hall', Block.none, Terrain.water)
    ..lane(reed, hall, 'Reed Hall Lane')
    ..lane(fog, hall, 'Fog Hall', Block.dark);
  b.person(reed, care: true);
  b.person(fog, care: true, hidden: true);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Evacuate / split start positions.
SceneBuilder m069() {
  final b = SceneBuilder('M069', 3, 9)
    ..title = 'Split Banks at Dusk'
    ..brief =
        'Three neighbours: west mill, island reed, east towpath. Crews start one per bank. Marco must take the island; the others walk land.'
    ..tutorial = [
      'Split starts, three gates, two people. Someone sits out a gate.',
      'Island reed is water. Leave Marco a slip that touches water.',
    ]
    ..strategies = [
      'Marco west slip onto the island. Rosa east towpath, then mill if needed.',
      'Marco east; Rosa west mill. Island still needs a water start.',
    ]
    ..roles = _boatCut
    ..decor.addAll(['water:300,360,200,200', 'pier:360,300,80,40']);
  final w = b.start('w', 80, 1000, 'Mill Gate');
  final s = b.start('s', 400, 1000, 'South Slip');
  final e = b.start('e', 720, 980, 'Towpath Gate');
  final mill = b.node('mill', 140, 700, 'West Mill');
  final isle = b.node('isle', 400, 520, 'Island Reed', NodeKind.pier);
  final tow = b.node('tow', 680, 700, 'East Towpath');
  final hall = b.shelter('hall', 400, 240, 'Dusk Hall');
  b
    ..lane(w, mill, 'Mill Rise')
    ..lane(s, isle, 'Slip Island', Block.none, Terrain.water)
    ..lane(e, tow, 'Tow Rise')
    ..lane(mill, hall, 'Mill Hall')
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(tow, hall, 'Tow Hall')
    ..lane(mill, isle, 'Mill Water', Block.none, Terrain.water)
    ..lane(tow, isle, 'Tow Water', Block.none, Terrain.water);
  b.person(mill);
  b.person(isle);
  b.person(tow);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Stabilize / two viable routes.
SceneBuilder m070() {
  final b = SceneBuilder('M070', 3, 10)
    ..title = 'Two Ways to the Miller'
    ..brief =
        'The miller on Reed Island needs care before anyone can walk them out. West cut is water. East cut is fog on a plank. Either route works.'
    ..tutorial = [
      'Two viable routes to the miller. West is water (Marco). East is fog (Floodlight).',
      'Tomi steadies. Marco ferries or lights.',
    ]
    ..strategies = [
      'Marco west water. Tomi east with the Floodlight.',
      'Both west: Tomi waits at the hall for Marco to bring the miller.',
    ]
    ..roles = _boatCare
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['water:80,300,240,400', 'smoke:520,360,200,160']);
  final w = b.start('w', 80, 1000, 'West Slip');
  final e = b.start('e', 720, 1000, 'East Fog Gate');
  final isle = b.node('isle', 240, 500, 'Reed Island', NodeKind.pier);
  final fog = b.node('fog', 640, 500, 'East Fog');
  final hall = b.shelter('hall', 400, 220, 'Miller Hall');
  b
    ..lane(w, isle, 'West Water', Block.none, Terrain.water)
    ..lane(e, fog, 'East Rise')
    ..lane(fog, isle, 'Fog Plank', Block.dark)
    ..lane(isle, hall, 'Island Hall', Block.none, Terrain.water)
    ..lane(fog, hall, 'Fog Hall', Block.dark);
  final miller = b.person(isle, care: true, critical: true);
  b.goal(ObjectiveType.stabilized, target: miller);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

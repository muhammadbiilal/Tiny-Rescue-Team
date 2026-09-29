// Old Town M031-M040. Smoke, narrow lanes, and Juno Park (Scout at 31).
// Layouts are original alleys and eaves, not Harbor piers.
import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

import 'builder.dart';

const _scan = [Role.scout, Role.medic];
const _cut = [Role.scout, Role.rescuer];

List<SceneBuilder> oldTownIntro() => [
  m031(),
  m032(),
  m033(),
  m034(),
  m035(),
  m036(),
  m037(),
  m038(),
  m039(),
  m040(),
];

/// Stabilize and transport / uncertain visibility.
SceneBuilder m031() {
  final b = SceneBuilder('M031', 2, 1)
    ..title = 'Smoke in Baker Lane'
    ..brief =
        'The baker is still in the oven yard and cannot walk until steadied. Smoke hides a second caller under the eaves. '
        'Unlit lanes stay closed until Juno Park lights them.'
    ..tutorial = [
      'Juno Park joins the free team. She cannot guide people, but she opens dark lanes faster than a Floodlight.',
      'Tomi still steadies anyone with a care mark. Send Juno into the smoke first.',
    ]
    ..strategies = [
      'Juno at Eaves Stair lights Baker Smoke; Tomi starts at Baker Gate for the oven yard.',
      'Both at Baker Gate: Juno still has to climb to the eaves before Tomi can fetch the hidden caller.',
    ]
    ..roles = _scan
    ..decor.addAll([
      'cobble:40,700,720,280',
      'eaves:520,180,240,120',
      'smoke:80,400,200,160',
    ]);
  final gate = b.start('gate', 90, 1000, 'Baker Gate', capacity: 2);
  final stair = b.start('stair', 710, 980, 'Eaves Stair');
  final sq = b.node('sq', 360, 780, 'Well Square', NodeKind.junction);
  final oven = b.node('oven', 110, 540, 'Oven Yard');
  final eaves = b.node('eaves', 680, 480, 'Smoky Eaves');
  final well = b.shelter('well', 380, 320, 'Well Court');
  final clock = b.node('clock', 380, 120, 'Clock Face', NodeKind.lookout);
  b
    ..lane(gate, sq, 'Baker Street')
    ..lane(stair, eaves, 'Eaves Climb')
    ..lane(sq, oven, 'Oven Cut')
    ..lane(oven, eaves, 'Baker Smoke', Block.dark)
    ..lane(sq, well, 'Well Steps')
    ..lane(oven, well, 'Yard Walk')
    ..lane(eaves, well, 'Eaves Drop', Block.dark)
    ..lane(well, clock, 'Clock Stair');
  final baker = b.person(oven, care: true, critical: true);
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.stabilized, target: baker);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Open a safe route / split start positions.
SceneBuilder m032() {
  final b = SceneBuilder('M032', 2, 2)
    ..title = 'Split at the Clock'
    ..brief =
        'Bell Tower must be reachable from Clock Gate. Crews start on opposite alleys. Fallen shutters and smoke block every short cut.'
    ..tutorial = [
      'Split starts: each alley holds one responder. They meet only after someone opens a lane.',
      'Juno lights smoke. Rosa clears shutters.',
    ]
    ..strategies = [
      'Rosa west through Shutter Row. Juno east through Gable Smoke.',
      'Swap sides: Rosa still has to reach the shutters; the smoke side is Juno\'s job.',
    ]
    ..roles = _cut
    ..gear = [Gear.cutter]
    ..decor.addAll(['gable:300,80,200,100', 'cobble:60,820,680,180']);
  final w = b.start('w', 80, 1000, 'West Alley');
  final e = b.start('e', 720, 1000, 'East Alley');
  final west = b.node('west', 140, 720, 'Shutter Row');
  final mid = b.node('mid', 400, 620, 'Clock Crossing', NodeKind.junction);
  final east = b.node('east', 660, 720, 'Gable Walk');
  final bell = b.node('bell', 400, 180, 'Bell Tower', NodeKind.lookout);
  final well = b.node('well', 400, 400, 'Well Lip');
  b
    ..lane(w, west, 'West Rise')
    ..lane(e, east, 'East Rise')
    ..lane(west, mid, 'Shutter Row', Block.debris)
    ..lane(east, mid, 'Gable Smoke', Block.dark)
    ..lane(mid, well, 'Crossing Down')
    ..lane(well, bell, 'Bell Steps')
    ..lane(west, well, 'West Lip', Block.debris)
    ..lane(east, bell, 'Long Gable', Block.dark);
  b.goal(ObjectiveType.routeOpen, a: w, b: bell);
  return b;
}

/// Contain a spreading hazard / two viable routes.
SceneBuilder m033() {
  final b = SceneBuilder('M033', 2, 3)
    ..title = 'Two Ways off the Tannery'
    ..brief =
        'A vat fire sits in the tannery. It will run the Kiln Cut, then the Arcade. One Extinguisher. West yard is clear but long; the east cut is shorter and smoky.'
    ..tutorial = [
      'Two real routes to the fire. The smoky cut is faster once Juno opens it.',
      'Whoever carries the Extinguisher puts the vat out. Standing on a spread tile holds it back.',
    ]
    ..strategies = [
      'Juno east through Tannery Smoke. Rosa with the Extinguisher west around the yard.',
      'Both east: Rosa waits on Juno, then runs the vat.',
    ]
    ..roles = _cut
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['smoke:80,360,220,200', 'cobble:480,640,260,200']);
  final w = b.start('w', 100, 1000, 'Tan West');
  final e = b.start('e', 680, 1000, 'Tan East');
  final yard = b.node('yard', 140, 700, 'Tan Yard');
  final mouth = b.node('mouth', 640, 700, 'Smoke Mouth');
  final vat = b.node('vat', 400, 480, 'Tannery Vat');
  final kiln = b.node('kiln', 400, 280, 'Kiln Cut');
  final arcade = b.node('arc', 640, 280, 'Old Arcade');
  final hall = b.shelter('hall', 160, 260, 'Tan Hall');
  b
    ..lane(w, yard, 'West Rise')
    ..lane(e, mouth, 'East Rise')
    ..lane(yard, vat, 'Yard Vat')
    ..lane(mouth, vat, 'Tannery Smoke', Block.dark)
    ..lane(vat, kiln, 'Kiln Cut')
    ..lane(kiln, arcade, 'Arcade Link')
    ..lane(yard, hall, 'Yard Hall')
    ..lane(vat, hall, 'Vat Hall')
    ..lane(kiln, hall, 'Kiln Hall');
  b.fire(vat);
  b.person(arcade);
  b.hazards.addAll(const [
    HazardEvent(80, HazardType.wind, note: 'Draft pulls up the Kiln Cut'),
    HazardEvent(200, HazardType.spread, from: 'vat', to: 'kiln'),
    HazardEvent(320, HazardType.spread, from: 'kiln', to: 'arc'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [arcade]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Deliver essential supplies / blocked junction.
SceneBuilder m034() {
  final b = SceneBuilder('M034', 2, 4)
    ..title = 'Cart at the Blocked Well'
    ..brief =
        'Two oil tins sit in the mill loft. The clinic needs both. Well Crossing is packed with shutters, so the cart cannot turn until that junction is cleared.'
    ..tutorial = [
      'The blocked junction is the only short turn for the cart. Clear it or take the long gable.',
      'One Cargo Sled. Give it to Rosa; Juno cannot haul without it.',
    ]
    ..strategies = [
      'Sled on Rosa at Mill Gate. Juno at Clinic Stair lights Gable Smoke so the long way exists.',
      'Both at Mill Gate: Juno still has to reach the gable while Rosa waits on the shutters.',
    ]
    ..roles = _cut
    ..gear = [Gear.cargoSled, Gear.cutter]
    ..decor.addAll(['gable:80,200,160,140', 'cobble:280,700,240,160']);
  final mill = b.start('mill', 120, 1000, 'Mill Gate');
  final clinicS = b.start('cs', 680, 1000, 'Clinic Stair');
  final loft = b.depot('loft', 140, 720, 'Mill Loft', 2);
  final cross = b.node('cross', 400, 620, 'Well Crossing', NodeKind.junction);
  final gable = b.node('gable', 680, 720, 'Gable Turn');
  final clinic = b.need('clinic', 640, 280, 'Lane Clinic', 2);
  final well = b.shelter('well', 360, 300, 'Well Court');
  b
    ..lane(mill, loft, 'Mill Ramp')
    ..lane(clinicS, gable, 'Stair Gable')
    ..lane(loft, cross, 'Loft Crossing')
    ..lane(gable, cross, 'Gable Smoke', Block.dark)
    ..lane(cross, 'clinic', 'Clinic Cut', Block.debris)
    ..lane(gable, 'clinic', 'Long Gable')
    ..lane(cross, well, 'Cross Well');
  b.goal(ObjectiveType.delivered, target: clinic, count: 2);
  return b;
}

/// Inspect and then respond / branching access.
SceneBuilder m035() {
  final b = SceneBuilder('M035', 2, 5)
    ..title = 'Branching Eaves'
    ..brief =
        'Callers are split between the north eaves and the south gable. Both forks are unlit. Light them, then bring everyone to Well Court.'
    ..tutorial = [
      'Branching access: lighting one fork does not light the other.',
      'People in smoke appear only after that fork is opened.',
    ]
    ..strategies = [
      'Juno north, Tomi south. Meet at Well Court.',
      'Juno does both forks; Tomi waits at the well for escorts.',
    ]
    ..roles = _scan
    ..decor.addAll([
      'eaves:80,120,280,140',
      'gable:480,120,260,140',
      'smoke:200,400,400,120',
    ]);
  final gate = b.start('gate', 400, 1000, 'Fork Gate', capacity: 2);
  final fork = b.node('fork', 400, 760, 'Eaves Fork', NodeKind.junction);
  final north = b.node('north', 140, 480, 'North Eaves');
  final south = b.node('south', 660, 480, 'South Gable');
  final deepN = b.node('dn', 140, 220, 'High Eaves');
  final deepS = b.node('ds', 660, 220, 'High Gable');
  final well = b.shelter('well', 400, 420, 'Well Court');
  b
    ..lane(gate, fork, 'Fork Road')
    ..lane(fork, north, 'North Smoke', Block.dark)
    ..lane(fork, south, 'South Smoke', Block.dark)
    ..lane(north, deepN, 'High North', Block.dark)
    ..lane(south, deepS, 'High South', Block.dark)
    ..lane(fork, well, 'Fork Well')
    ..lane(north, well, 'North Drop')
    ..lane(south, well, 'South Drop');
  b.person(deepN, hidden: true);
  b.person(deepS, hidden: true);
  b.person(fork);
  b.goal(ObjectiveType.revealed, nodes: ['fork-north', 'fork-south']);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Restore access to a shelter / timed shelter capacity.
SceneBuilder m036() {
  final b = SceneBuilder('M036', 2, 6)
    ..title = 'Chapel Door and the Tiny Well'
    ..brief =
        'Chapel doors are jammed. The Tiny Well holds only one person and is already open. A second caller waits in the smoke. Repair the chapel before the well fills and leaves them outside.'
    ..tutorial = [
      'A number on a shelter is its seats. Tiny Well seats one.',
      'Rosa with a Toolkit can repair. Juno opens the smoky path to the second caller.',
    ]
    ..strategies = [
      'Toolkit on Rosa at Chapel Gate. Juno at Smoke Stair.',
      'Repair first, then both escort. The well is only a spare seat.',
    ]
    ..roles = _cut
    ..gear = [Gear.toolkit]
    ..decor.addAll(['gable:280,80,240,120', 'smoke:520,400,220,180']);
  final cg = b.start('cg', 160, 1000, 'Chapel Gate');
  final ss = b.start('ss', 680, 980, 'Smoke Stair');
  final square = b.node('sq', 400, 760, 'Chapel Square', NodeKind.junction);
  final chapel = b.shelter('chapel', 400, 420, 'Lane Chapel', broken: true);
  final tiny = b.shelter('tiny', 160, 420, 'Tiny Well', capacity: 1);
  final smoke = b.node('smoke', 680, 500, 'Smoke Court');
  b
    ..lane(cg, square, 'Chapel Road')
    ..lane(ss, smoke, 'Stair Court')
    ..lane(square, chapel, 'Chapel Steps')
    ..lane(square, tiny, 'Well Cut')
    ..lane(smoke, chapel, 'Smoke Chapel', Block.dark)
    ..lane(smoke, tiny, 'Smoke Well', Block.dark)
    ..lane(tiny, chapel, 'Well Chapel');
  b.person(square);
  b.person(smoke, hidden: true);
  b.goal(ObjectiveType.shelterOpen, target: chapel);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Coordinate two dependent teams / one constrained vehicle.
SceneBuilder m037() {
  final b = SceneBuilder('M037', 2, 7)
    ..title = 'One Cart, Two Alleys'
    ..brief =
        'The mill tin has to reach Lane Clinic. The cart cannot enter Mill Smoke until that alley is lit. Juno and Rosa start on opposite alleys: one opens, one hauls.'
    ..tutorial = [
      'Dependent jobs: the sled is useless until the smoke alley is open.',
      'One Cargo Sled. Rosa hauls. Juno lights.',
    ]
    ..strategies = [
      'Juno at Smoke Alley. Sled on Rosa at Mill Alley.',
      'Swap: Juno still has to cross to the smoke before Rosa can roll.',
    ]
    ..roles = _cut
    ..gear = [Gear.cargoSled]
    ..decor.addAll(['smoke:80,360,240,200', 'cobble:480,700,260,180']);
  final millA = b.start('ma', 120, 1000, 'Mill Alley');
  final smokeA = b.start('sa', 680, 1000, 'Smoke Alley');
  final mill = b.depot('mill', 140, 680, 'Mill Door', 1);
  final mist = b.node('mist', 400, 620, 'Mill Smoke');
  final clinic = b.need('clinic', 660, 360, 'Lane Clinic', 1);
  final well = b.shelter('well', 360, 280, 'Well Court');
  b
    ..lane(millA, mill, 'Mill In')
    ..lane(smokeA, mist, 'Alley Mist')
    ..lane(mill, mist, 'Mill Smoke', Block.dark)
    ..lane(mist, 'clinic', 'Mist Clinic', Block.dark)
    ..lane(mill, well, 'Mill Well', Block.debris)
    ..lane('clinic', well, 'Clinic Well')
    ..lane(mist, well, 'Mist Well');
  b.goal(ObjectiveType.delivered, target: clinic, count: 1);
  return b;
}

/// Protect a critical corridor / shared resource.
SceneBuilder m038() {
  final b = SceneBuilder('M038', 2, 8)
    ..title = 'Shared Pump on the Arcade'
    ..brief =
        'The kiln fire will reach Clock Arcade, which must stay open. One Extinguisher is on the truck. A shutter pile sits on the other approach.'
    ..tutorial = [
      'Shared Extinguisher. Give it to whoever starts nearer the kiln.',
      'Protect Clock Arcade. If fire sits there, the corridor is lost.',
    ]
    ..strategies = [
      'Extinguisher on Rosa at Kiln Gate. Juno at Arcade Gate lights the back cut.',
      'Extinguisher on Juno only works if she reaches the kiln after the smoke opens.',
    ]
    ..roles = _cut
    ..gear = [Gear.extinguisher, Gear.cutter]
    ..decor.addAll(['cobble:200,240,400,80', 'smoke:80,480,180,160']);
  final kg = b.start('kg', 120, 1000, 'Kiln Gate');
  final ag = b.start('ag', 680, 1000, 'Arcade Gate');
  final kiln = b.node('kiln', 160, 620, 'Kiln Mouth');
  final arcade = b.node('arc', 400, 420, 'Clock Arcade');
  final back = b.node('back', 680, 620, 'Back Cut');
  final hall = b.shelter('hall', 400, 200, 'Arcade Hall');
  b
    ..lane(kg, kiln, 'Kiln Road')
    ..lane(ag, back, 'Arcade Road')
    ..lane(kiln, arcade, 'Kiln Arcade')
    ..lane(back, arcade, 'Back Smoke', Block.dark)
    ..lane(arcade, hall, 'Arcade Hall Lane')
    ..lane(kiln, hall, 'Kiln Hall', Block.debris)
    ..lane(back, hall, 'Back Hall');
  b.fire(kiln);
  b.person(back, hidden: true);
  b.hazards.add(
    const HazardEvent(210, HazardType.spread, from: 'kiln', to: 'arc'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [arcade]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Resolve simultaneous calls / responder fatigue.
SceneBuilder m039() {
  final b = SceneBuilder('M039', 2, 9)
    ..title = 'Two Calls, Tired Legs'
    ..brief =
        'A gable keeper and a well keeper both need care, on opposite sides of town. Long climbs tire the team: after two jobs a responder rests.'
    ..tutorial = [
      'Two calls at once. Tomi is the only one who can steady them without a kit.',
      'Fatigue after two finished tasks. Juno can only open smoke and wait.',
    ]
    ..strategies = [
      'Tomi at Well Gate, Juno at Gable Gate. Tomi cares both; Juno lights the gable.',
      'Both at Well Gate: the gable wait is longer because of the rest.',
    ]
    ..roles = _scan
    ..rules = const Rules(fatigueJobs: 2, restTicks: 40)
    ..decor.addAll(['gable:520,160,220,140', 'cobble:80,700,240,180']);
  final wg = b.start('wg', 120, 1000, 'Well Gate');
  final gg = b.start('gg', 680, 1000, 'Gable Gate');
  final wellK = b.node('wk', 140, 640, 'Well Keeper');
  final mid = b.node('mid', 400, 640, 'Lane Mid', NodeKind.junction);
  final gableK = b.node('gk', 660, 480, 'Gable Keeper');
  final hall = b.shelter('hall', 400, 280, 'Lane Hall');
  b
    ..lane(wg, wellK, 'Well Rise')
    ..lane(gg, gableK, 'Gable Rise')
    ..lane(wellK, mid, 'Keeper Mid')
    ..lane(gableK, mid, 'Gable Smoke', Block.dark)
    ..lane(mid, hall, 'Mid Hall')
    ..lane(wellK, hall, 'Well Hall')
    ..lane(gableK, hall, 'Gable Hall', Block.dark);
  b.person(wellK, care: true);
  b.person(gableK, care: true, hidden: true);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Evacuate civilians / delayed hazard.
SceneBuilder m040() {
  final b = SceneBuilder('M040', 2, 10)
    ..title = 'Chimney Fall at Dusk'
    ..brief =
        'Three neighbours are still in the lanes. The chimney over Clock Street is expected to shed bricks at about twenty seconds. Get them to Well Court before that street closes, or use the back eaves.'
    ..tutorial = [
      'The forecast names when Clock Street sheds. Beat it, or send people the long eaves way.',
      'Juno opens eaves. Rosa guides.',
    ]
    ..strategies = [
      'Rosa down Clock Street with the first two. Juno opens Back Eaves for the third.',
      'Ignore Clock Street and walk everyone the eaves way after Juno lights it.',
    ]
    ..roles = _cut
    ..decor.addAll([
      'eaves:520,200,240,200',
      'cobble:80,700,280,200',
      'smoke:300,360,160,80',
    ]);
  final gate = b.start('gate', 400, 1000, 'Dusk Gate', capacity: 2);
  final street = b.node('st', 400, 720, 'Clock Street');
  final baker = b.node('baker', 140, 560, 'Baker Door');
  final eaves = b.node('eaves', 660, 560, 'Back Eaves');
  final well = b.shelter('well', 400, 280, 'Well Court');
  final loft = b.node('loft', 140, 280, 'Loft Stair');
  b
    ..lane(gate, street, 'Dusk Road')
    ..lane(street, baker, 'Street Baker')
    ..lane(street, eaves, 'Street Eaves')
    ..lane(street, well, 'Clock Street')
    ..lane(baker, well, 'Baker Well')
    ..lane(eaves, well, 'Back Eaves', Block.dark)
    ..lane(baker, loft, 'Baker Loft')
    ..lane(loft, well, 'Loft Well');
  b.person(baker);
  b.person(eaves, hidden: true);
  b.person(street);
  b.hazards.add(
    const HazardEvent(
      200,
      HazardType.collapse,
      edge: 'st-well',
      note: 'Chimney sheds onto Clock Street',
    ),
  );
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

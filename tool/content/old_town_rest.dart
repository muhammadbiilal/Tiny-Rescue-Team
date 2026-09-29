// Old Town M041-M060. Scout is on the free roster; advanced slots use all four.
import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

import 'builder.dart';

const _syn = [Role.rescuer, Role.medic, Role.scout];
const _fix = [Role.rescuer, Role.engineer, Role.scout];
const _careFix = [Role.medic, Role.engineer, Role.scout];
const _quad = [Role.rescuer, Role.medic, Role.engineer, Role.scout];

List<SceneBuilder> oldTownRest() => [
  m041(),
  m042(),
  m043(),
  m044(),
  m045(),
  m046(),
  m047(),
  m048(),
  m049(),
  m050(),
  m051(),
  m052(),
  m053(),
  m054(),
  m055(),
  m056(),
  m057(),
  m058(),
  m059(),
  m060(),
];

/// Stabilize + deliver / changing wind.
SceneBuilder m041() {
  final b = SceneBuilder('M041', 2, 11)
    ..title = 'Flour and the Kiln Draft'
    ..brief =
        'The miller needs care in the loft. Two flour sacks must reach Lane Clinic. The kiln fire will drift with the wind onto Flour Walk if it is not put out.'
    ..tutorial = [
      'Three on the team now. Juno lights, Tomi cares, Rosa hauls.',
      'Wind is a forecast, not a blocker. The spread after it is the real clock.',
    ]
    ..strategies = [
      'Sled and Extinguisher split: Rosa hauls, whoever is nearest the kiln carries water.',
      'Tomi stays with the miller until the loft smoke is open.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.cargoSled, Gear.extinguisher, Gear.firstAid]
    ..decor.addAll(['smoke:80,200,200,180', 'cobble:400,700,320,200']);
  final millG = b.start('mg', 100, 1000, 'Mill Gate');
  final kilnG = b.start('kg', 400, 1000, 'Kiln Gate');
  final clinicG = b.start('cg', 720, 980, 'Clinic Gate');
  final loft = b.node('loft', 120, 680, 'Mill Loft');
  final depot = b.depot('dep', 120, 480, 'Flour Bay', 2);
  final kiln = b.node('kiln', 400, 620, 'Kiln Mouth');
  final walk = b.node('walk', 400, 400, 'Flour Walk');
  final clinic = b.need('clinic', 700, 400, 'Lane Clinic', 2);
  final hall = b.shelter('hall', 400, 200, 'Mill Hall');
  b
    ..lane(millG, loft, 'Mill Rise')
    ..lane(kilnG, kiln, 'Kiln Rise')
    ..lane(clinicG, 'clinic', 'Clinic Rise')
    ..lane(loft, depot, 'Loft Bay', Block.dark)
    ..lane(loft, kiln, 'Loft Kiln')
    ..lane(kiln, walk, 'Kiln Walk')
    ..lane(walk, 'clinic', 'Walk Clinic')
    ..lane(depot, walk, 'Bay Walk')
    ..lane(walk, hall, 'Walk Hall')
    ..lane('clinic', hall, 'Clinic Hall')
    ..lane(kiln, hall, 'Kiln Hall', Block.debris);
  final miller = b.person(loft, care: true, critical: true);
  b.fire(kiln);
  b.hazards.addAll(const [
    HazardEvent(90, HazardType.wind, note: 'Draft turns onto Flour Walk'),
    HazardEvent(220, HazardType.spread, from: 'kiln', to: 'walk'),
  ]);
  b.goal(ObjectiveType.stabilized, target: miller);
  b.goal(ObjectiveType.delivered, target: clinic, count: 2);
  b.goal(ObjectiveType.contained);
  return b;
}

/// Open a safe route + restore shelter / limited equipment.
SceneBuilder m042() {
  final b = SceneBuilder('M042', 2, 12)
    ..title = 'One Toolkit on Bell Road'
    ..brief =
        'Bell Tower must be reachable from North Gate, and Lane Chapel\'s door is jammed. Only one Toolkit is in the van.'
    ..tutorial = [
      'Bea can repair without the Toolkit, slowly. Rosa needs it.',
      'One tool, two jobs if you spend it on the door and Rapid Access on debris.',
    ]
    ..strategies = [
      'Toolkit on Bea at Chapel Side. Rosa and Juno open Bell Road.',
      'Toolkit on Rosa for the door. Bea clears Bell Shutters.',
    ]
    ..teamSize = 3
    ..roles = _fix
    ..gear = [Gear.toolkit, Gear.cutter]
    ..decor.addAll(['gable:300,60,200,90', 'cobble:60,800,680,180']);
  final ng = b.start('ng', 400, 1000, 'North Gate', capacity: 2);
  final cs = b.start('cs', 120, 820, 'Chapel Side');
  final es = b.start('es', 680, 820, 'Eaves Side');
  final shut = b.node('shut', 400, 760, 'Bell Shutters');
  final mid = b.node('mid', 400, 520, 'Bell Road', NodeKind.junction);
  final bell = b.node('bell', 400, 160, 'Bell Tower', NodeKind.lookout);
  final chapel = b.shelter('chapel', 160, 400, 'Lane Chapel', broken: true);
  final eaves = b.node('eaves', 660, 400, 'Eaves Cut');
  b
    ..lane(ng, shut, 'Gate Shutters')
    ..lane(cs, chapel, 'Side Chapel')
    ..lane(es, eaves, 'Side Eaves')
    ..lane(shut, mid, 'Bell Shutters', Block.debris)
    ..lane(mid, bell, 'Bell Rise')
    ..lane(cs, mid, 'Chapel Bell')
    ..lane(eaves, mid, 'Eaves Smoke', Block.dark)
    ..lane(chapel, mid, 'Chapel Mid')
    ..lane(eaves, bell, 'Eaves Bell', Block.dark);
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.routeOpen, a: ng, b: bell);
  b.goal(ObjectiveType.shelterOpen, target: chapel);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Contain + protect / uncertain visibility.
SceneBuilder m043() {
  final b = SceneBuilder('M043', 2, 13)
    ..title = 'Smoke on the Arcade'
    ..brief =
        'A hearth fire in Gable House will reach Clock Arcade, which must stay clear. The house lanes are unlit. Someone is still inside.'
    ..tutorial = [
      'You cannot put the hearth out until Juno or a Floodlight opens Gable Smoke.',
      'Protect Clock Arcade. The hidden caller appears once the house is lit.',
    ]
    ..strategies = [
      'Juno into the house. Extinguisher on Rosa. Tomi waits on the arcade.',
      'Floodlight on Tomi as backup if Juno starts on the wrong gate.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.extinguisher, Gear.floodlight]
    ..decor.addAll([
      'gable:80,200,240,180',
      'smoke:80,200,240,180',
      'cobble:360,360,280,80',
    ]);
  final w = b.start('w', 80, 1000, 'Gable West');
  final m = b.start('m', 400, 1000, 'Arcade Mouth');
  final e = b.start('e', 720, 1000, 'East Post');
  final door = b.node('door', 140, 700, 'Gable Door');
  final hearth = b.node('hearth', 140, 440, 'Hearth');
  final arcade = b.node('arc', 400, 440, 'Clock Arcade');
  final hall = b.shelter('hall', 400, 220, 'Arcade Hall');
  final east = b.node('east', 700, 700, 'East Lane');
  b
    ..lane(w, door, 'West Door')
    ..lane(m, arcade, 'Mouth Arcade')
    ..lane(e, east, 'East Rise')
    ..lane(door, hearth, 'Gable Smoke', Block.dark)
    ..lane(hearth, arcade, 'Hearth Arcade')
    ..lane(arcade, hall, 'Arcade Hall Lane')
    ..lane(east, arcade, 'East Arcade')
    ..lane(east, hall, 'East Hall')
    ..lane(door, hall, 'Door Hall', Block.debris);
  b.fire(hearth);
  b.person(hearth, hidden: true);
  b.hazards.add(
    const HazardEvent(230, HazardType.spread, from: 'hearth', to: 'arc'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [arcade]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Deliver + evacuate / split start positions.
SceneBuilder m044() {
  final b = SceneBuilder('M044', 2, 14)
    ..title = 'Split Loads on Lane Street'
    ..brief =
        'One flour tin for the clinic, two neighbours to walk out. Crews start one per gate: mill, well, and gable. Smoke hides the gable neighbour.'
    ..tutorial = [
      'Three gates, one person each. Nobody starts together.',
      'Sled on the mill starter. Juno belongs on the gable.',
    ]
    ..strategies = [
      'Rosa mill, Tomi well, Juno gable.',
      'Sled on Tomi at well if Rosa is needed to clear Gable Shutters.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.cargoSled, Gear.cutter]
    ..decor.addAll(['gable:560,200,200,160', 'cobble:80,780,240,160']);
  final mill = b.start('mill', 80, 1000, 'Mill Gate');
  final wellG = b.start('wg', 400, 1000, 'Well Gate');
  final gableG = b.start('gg', 720, 980, 'Gable Gate');
  final depot = b.depot('dep', 100, 700, 'Mill Store', 1);
  final wellN = b.node('wn', 400, 700, 'Well Neighbour');
  final gable = b.node('gable', 700, 560, 'Gable Neighbour');
  final clinic = b.need('clinic', 200, 320, 'Lane Clinic', 1);
  final hall = b.shelter('hall', 500, 280, 'Lane Hall');
  b
    ..lane(mill, depot, 'Mill Store Lane')
    ..lane(wellG, wellN, 'Well Rise')
    ..lane(gableG, gable, 'Gable Rise')
    ..lane(depot, wellN, 'Store Well')
    ..lane(wellN, gable, 'Well Gable', Block.dark)
    ..lane(depot, 'clinic', 'Store Clinic')
    ..lane(wellN, hall, 'Well Hall')
    ..lane(gable, hall, 'Gable Hall', Block.dark)
    ..lane('clinic', hall, 'Clinic Hall')
    ..lane(gable, 'clinic', 'Gable Shutters', Block.debris);
  b.person(wellN);
  b.person(gable, hidden: true);
  b.goal(ObjectiveType.delivered, target: clinic, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Inspect then respond + open a safe route / two viable routes.
SceneBuilder m045() {
  final b = SceneBuilder('M045', 2, 15)
    ..title = 'Look, Then Cut'
    ..brief =
        'Bell Tower must be reachable from South Gate. Callers are hidden on both the west eaves and the east gable. West is shutters; east is smoke. Either road works once opened.'
    ..tutorial = [
      'Inspect first: the hidden callers are the reason to open a road, not a side job.',
      'Two viable routes to the tower. You do not need both.',
    ]
    ..strategies = [
      'Juno east, Rosa west. Tomi escorts whoever appears first.',
      'All east: ignore shutters and walk the smoke road.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.cutter]
    ..decor.addAll(['eaves:40,200,200,200', 'gable:560,200,200,200']);
  final sg = b.start('sg', 400, 1000, 'South Gate', capacity: 2);
  final wg = b.start('wg', 80, 880, 'West Post');
  final eg = b.start('eg', 720, 880, 'East Post');
  final fork = b.node('fork', 400, 760, 'Look Fork', NodeKind.junction);
  final west = b.node('west', 140, 480, 'West Eaves');
  final east = b.node('east', 660, 480, 'East Gable');
  final bell = b.node('bell', 400, 160, 'Bell Tower', NodeKind.lookout);
  final hall = b.shelter('hall', 400, 400, 'Look Hall');
  b
    ..lane(sg, fork, 'South Fork')
    ..lane(wg, west, 'West Post Lane')
    ..lane(eg, east, 'East Post Lane')
    ..lane(fork, west, 'West Shutters', Block.debris)
    ..lane(fork, east, 'East Smoke', Block.dark)
    ..lane(west, bell, 'West Bell', Block.debris)
    ..lane(east, bell, 'East Bell', Block.dark)
    ..lane(fork, hall, 'Fork Hall')
    ..lane(west, hall, 'West Hall')
    ..lane(east, hall, 'East Hall')
    ..lane(hall, bell, 'Hall Bell');
  b.person(west, hidden: true);
  b.person(east, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['fork-west', 'fork-east']);
  b.goal(ObjectiveType.routeOpen, a: sg, b: bell);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Restore shelter + deliver / blocked junction.
SceneBuilder m046() {
  final b = SceneBuilder('M046', 2, 16)
    ..title = 'Gable Door and the Oil Crate'
    ..brief =
        'Gable Hall\'s door is jammed and an oil crate must reach the Clock Lamp. Well Crossing is shuttered, so the crate cannot turn until that junction is cleared.'
    ..tutorial = [
      'Bea repairs the hall. Rosa or the sled clears and hauls.',
      'Blocked junction: the lamp is on the far side of Well Crossing.',
    ]
    ..strategies = [
      'Bea at Gable Side. Sled on Rosa through the crossing. Juno lights the back eaves.',
      'Clear the crossing first; the back eaves is only a people path.',
    ]
    ..teamSize = 3
    ..roles = _fix
    ..gear = [Gear.toolkit, Gear.cargoSled]
    ..decor.addAll(['gable:80,180,200,160', 'cobble:300,560,200,100']);
  final gs = b.start('gs', 80, 1000, 'Gable Side');
  final ms = b.start('ms', 400, 1000, 'Mill Side');
  final es = b.start('es', 720, 980, 'Eaves Side');
  final hall = b.shelter('hall', 140, 560, 'Gable Hall', broken: true);
  final mill = b.depot('mill', 400, 720, 'Oil Mill', 1);
  final cross = b.node('cross', 400, 480, 'Well Crossing', NodeKind.junction);
  final lamp = b.need('lamp', 640, 280, 'Clock Lamp', 1);
  final eaves = b.node('eaves', 700, 640, 'Back Eaves');
  b
    ..lane(gs, hall, 'Side Hall')
    ..lane(ms, mill, 'Side Mill')
    ..lane(es, eaves, 'Side Eaves')
    ..lane(hall, mill, 'Hall Mill')
    ..lane(mill, cross, 'Mill Crossing')
    ..lane(cross, 'lamp', 'Crossing Lamp', Block.debris)
    ..lane(eaves, cross, 'Eaves Smoke', Block.dark)
    ..lane(eaves, 'lamp', 'Eaves Lamp', Block.dark)
    ..lane(hall, cross, 'Hall Cross');
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.delivered, target: lamp, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Two dependent teams + restore shelter / branching access.
SceneBuilder m047() {
  final b = SceneBuilder('M047', 2, 17)
    ..title = 'Loft Crew and Street Crew'
    ..brief =
        'The loft door is jammed, and a caller is hidden up the unlit stair. The street crew must keep Well Street open for the walk out. Branching: loft work does not open the street, and the street does not open the loft.'
    ..tutorial = [
      'Two jobs that do not share a lane. Send at least one responder up and one along the street.',
      'Bea belongs on the loft door. Juno belongs on the stair.',
    ]
    ..strategies = [
      'Bea and Juno loft. Rosa street.',
      'Bea loft, Rosa and Juno street after the stair is lit.',
    ]
    ..teamSize = 3
    ..roles = _careFix
    ..gear = [Gear.toolkit, Gear.floodlight]
    ..decor.addAll(['eaves:80,80,240,200', 'cobble:400,700,280,180']);
  final loftG = b.start('lg', 120, 200, 'Loft Dock', capacity: 2);
  final stG = b.start('sg', 640, 1000, 'Street Gate');
  final door = b.shelter('door', 160, 420, 'Loft Hall', broken: true);
  final stair = b.node('stair', 160, 640, 'Loft Stair');
  final street = b.node('st', 500, 640, 'Well Street');
  final well = b.shelter('well', 500, 360, 'Well Court');
  b
    ..lane(loftG, door, 'Dock Door')
    ..lane(door, stair, 'Door Stair', Block.dark)
    ..lane(stG, street, 'Gate Street')
    ..lane(stair, street, 'Stair Street')
    ..lane(street, well, 'Street Well')
    ..lane(door, well, 'Door Well', Block.debris)
    ..lane(stair, well, 'Stair Well', Block.dark);
  b.person(stair, hidden: true, care: true);
  b.person(street);
  b.goal(ObjectiveType.shelterOpen, target: door);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Protect two corridors / timed shelter capacity.
SceneBuilder m048() {
  final b = SceneBuilder('M048', 2, 18)
    ..title = 'Two Arcades, One Bench'
    ..brief =
        'Clock Arcade and Bell Walk must both stay clear of fire. Tiny Well seats one person and is open now; Lane Chapel opens at eighteen seconds. A hearth in Gable House feeds both corridors if it is not put out.'
    ..tutorial = [
      'Two corridors, not one copied job. Fire on either arcade fails the mission.',
      'Tiny Well holds one. The second neighbour waits for the chapel clock.',
    ]
    ..strategies = [
      'Extinguisher on the gable starter. Tomi escorts the first neighbour to the well. Juno lights the house.',
      'Put the fire out before walking anyone past the arcades.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['cobble:200,300,400,60', 'gable:80,400,160,160']);
  final gg = b.start('gg', 80, 1000, 'Gable Gate');
  final ag = b.start('ag', 400, 1000, 'Arcade Gate');
  final bg = b.start('bg', 720, 980, 'Bell Gate');
  final hearth = b.node('hearth', 140, 640, 'Gable Hearth');
  final arcade = b.node('arc', 400, 480, 'Clock Arcade');
  final bellW = b.node('bw', 680, 480, 'Bell Walk');
  final tiny = b.shelter('tiny', 400, 280, 'Tiny Well', capacity: 1);
  final chapel = b.shelter('chapel', 680, 220, 'Lane Chapel', openAt: 180);
  b
    ..lane(gg, hearth, 'Gable Rise')
    ..lane(ag, arcade, 'Arcade Rise')
    ..lane(bg, bellW, 'Bell Rise')
    ..lane(hearth, arcade, 'Hearth Arcade')
    ..lane(arcade, bellW, 'Arcade Bell')
    ..lane(arcade, tiny, 'Arcade Well')
    ..lane(bellW, chapel, 'Walk Chapel')
    ..lane(tiny, chapel, 'Well Chapel')
    ..lane(hearth, tiny, 'Hearth Well', Block.dark);
  b.fire(hearth);
  b.person(arcade);
  b.person(bellW);
  b.hazards.addAll(const [
    HazardEvent(200, HazardType.spread, from: 'hearth', to: 'arc'),
    HazardEvent(280, HazardType.spread, from: 'arc', to: 'bw'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [arcade, bellW]);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Simultaneous calls + evacuate / one constrained vehicle.
SceneBuilder m049() {
  final b = SceneBuilder('M049', 2, 19)
    ..title = 'One Cart for Two Streets'
    ..brief =
        'A crate is due at the Clock Lamp, a baker needs care, and a hidden eaves neighbour must walk out. One Cargo Sled is the only cart.'
    ..tutorial = [
      'One sled. Whoever does not haul it handles care and smoke.',
      'Two streets: lamp east, eaves west. Do not send the sled both ways first.',
    ]
    ..strategies = [
      'Sled on Rosa east. Tomi baker. Juno eaves.',
      'Sled on Juno only if Rosa is clearing shutters on the lamp road.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.cargoSled, Gear.firstAid]
    ..decor.addAll(['eaves:40,240,200,180', 'cobble:480,700,260,160']);
  final w = b.start('w', 80, 1000, 'Baker Gate');
  final m = b.start('m', 400, 1000, 'Mid Gate');
  final e = b.start('e', 720, 980, 'Lamp Gate');
  final baker = b.node('baker', 120, 680, 'Baker Door');
  final depot = b.depot('dep', 400, 720, 'Lane Store', 1);
  final eaves = b.node('eaves', 120, 400, 'West Eaves');
  final lamp = b.need('lamp', 700, 400, 'Clock Lamp', 1);
  final hall = b.shelter('hall', 400, 280, 'Lane Hall');
  b
    ..lane(w, baker, 'Baker Rise')
    ..lane(m, depot, 'Mid Store')
    ..lane(e, 'lamp', 'Lamp Rise')
    ..lane(baker, eaves, 'Baker Eaves', Block.dark)
    ..lane(baker, depot, 'Baker Store')
    ..lane(depot, 'lamp', 'Store Lamp')
    ..lane(depot, hall, 'Store Hall')
    ..lane(eaves, hall, 'Eaves Hall', Block.dark)
    ..lane('lamp', hall, 'Lamp Hall')
    ..lane(baker, hall, 'Baker Hall');
  final bake = b.person(baker, care: true);
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.stabilized, target: bake);
  b.goal(ObjectiveType.delivered, target: lamp, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Evacuate + open a safe route / shared resource.
SceneBuilder m050() {
  final b = SceneBuilder('M050', 2, 20)
    ..title = 'One Cutter on Wind Street'
    ..brief =
        'Bell Tower must be reachable from Wind Gate, and three neighbours still need Well Court. Only one Cutter is in the van. Shutters sit on the short tower road; smoke sits on the eaves road.'
    ..tutorial = [
      'Shared Cutter. Juno does not need it for smoke. Rosa does for shutters.',
      'Give the Cutter to Rosa unless you plan to ignore Bell Shutters.',
    ]
    ..strategies = [
      'Cutter on Rosa up Wind Street. Juno eaves. Tomi escorts.',
      'Ignore shutters: Juno opens eaves all the way to the tower.',
    ]
    ..teamSize = 3
    ..roles = _syn
    ..gear = [Gear.cutter]
    ..decor.addAll(['eaves:520,160,240,220', 'cobble:80,760,280,180']);
  final wg = b.start('wg', 400, 1000, 'Wind Gate', capacity: 2);
  final eg = b.start('eg', 720, 860, 'Eaves Gate');
  final street = b.node('st', 400, 740, 'Wind Street');
  final shut = b.node('shut', 400, 500, 'Bell Shutters');
  final eaves = b.node('eaves', 680, 500, 'Wind Eaves');
  final bell = b.node('bell', 400, 160, 'Bell Tower', NodeKind.lookout);
  final hall = b.shelter('hall', 200, 360, 'Well Court');
  b
    ..lane(wg, street, 'Wind Rise')
    ..lane(eg, eaves, 'Eaves Rise')
    ..lane(street, shut, 'Street Shutters')
    ..lane(shut, bell, 'Bell Shutters', Block.debris)
    ..lane(street, eaves, 'Street Eaves')
    ..lane(eaves, bell, 'Eaves Bell', Block.dark)
    ..lane(street, hall, 'Street Well')
    ..lane(eaves, hall, 'Eaves Well', Block.dark)
    ..lane(hall, bell, 'Well Bell', Block.debris);
  b.person(street);
  b.person(shut);
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.routeOpen, a: wg, b: bell);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Stabilize + deliver / responder fatigue. Team 4.
SceneBuilder m051() {
  final b = SceneBuilder('M051', 2, 21)
    ..title = 'Tired Stretch to the Clinic'
    ..brief =
        'The miller and a loft neighbour both need care. Two tins must reach Lane Clinic. After two jobs everyone rests. Smoke hides the loft.'
    ..tutorial = [
      'Four on the team: Rosa, Tomi, Bea, Juno.',
      'Fatigue will catch whoever tries to do every job. Split mill, loft, and clinic.',
    ]
    ..strategies = [
      'Tomi miller, Juno loft, sled on Rosa, Bea spare on shutters.',
      'Sled on Bea; Rosa clears; Tomi only cares.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.cargoSled, Gear.firstAid]
    ..rules = const Rules(fatigueJobs: 2, restTicks: 40)
    ..decor.addAll(['smoke:80,180,200,160', 'cobble:400,780,280,160']);
  final a = b.start('a', 80, 80, 'North Mill');
  final c = b.start('c', 400, 80, 'North Mid', capacity: 2);
  final e = b.start('e', 720, 80, 'North Clinic');
  final millerN = b.node('mn', 120, 300, 'Miller');
  final loft = b.node('loft', 120, 560, 'Loft Neighbour');
  final depot = b.depot('dep', 400, 300, 'Tin Bay', 2);
  final clinic = b.need('clinic', 700, 400, 'Lane Clinic', 2);
  final hall = b.shelter('hall', 400, 720, 'South Hall');
  b
    ..lane(a, millerN, 'Mill Drop')
    ..lane(c, depot, 'Mid Bay')
    ..lane(e, 'clinic', 'Clinic Drop')
    ..lane(millerN, loft, 'Miller Loft', Block.dark)
    ..lane(millerN, depot, 'Miller Bay')
    ..lane(depot, 'clinic', 'Bay Clinic')
    ..lane(loft, hall, 'Loft Hall', Block.dark)
    ..lane(depot, hall, 'Bay Hall')
    ..lane('clinic', hall, 'Clinic Hall');
  final miller = b.person(millerN, care: true, critical: true);
  b.person(loft, care: true, hidden: true);
  b.goal(ObjectiveType.stabilized, target: miller);
  b.goal(ObjectiveType.delivered, target: clinic, count: 2);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Open route + restore shelter / delayed hazard.
SceneBuilder m052() {
  final b = SceneBuilder('M052', 2, 22)
    ..title = 'Late Door on Bell Street'
    ..brief =
        'Bell Tower must be reachable from North Post, and Chapel door is jammed. Bell Street sheds bricks at about twenty-two seconds. Open a second road or beat the fall.'
    ..tutorial = [
      'Delayed chimney on Bell Street. Bea on the chapel door.',
      'Juno\'s eaves road is the backup if the street closes.',
    ]
    ..strategies = [
      'Bea chapel. Rosa Bell Street. Juno eaves.',
      'Ignore Bell Street; open eaves all the way, repair, walk.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.toolkit, Gear.cutter]
    ..decor.addAll(['gable:280,860,240,100', 'eaves:520,300,240,200']);
  final np = b.start('np', 400, 80, 'North Post', capacity: 2);
  final cp = b.start('cp', 80, 200, 'Chapel Post');
  final ep = b.start('ep', 720, 200, 'Eaves Post');
  final street = b.node('st', 400, 320, 'Bell Street');
  final bell = b.node('bell', 400, 860, 'Bell Tower', NodeKind.lookout);
  final chapel = b.shelter('chapel', 140, 560, 'Lane Chapel', broken: true);
  final eaves = b.node('eaves', 680, 560, 'Late Eaves');
  b
    ..lane(np, street, 'Post Street')
    ..lane(cp, chapel, 'Post Chapel')
    ..lane(ep, eaves, 'Post Eaves')
    ..lane(street, bell, 'Bell Street')
    ..lane(chapel, street, 'Chapel Street')
    ..lane(eaves, street, 'Eaves Smoke', Block.dark)
    ..lane(eaves, bell, 'Eaves Bell', Block.dark)
    ..lane(chapel, bell, 'Chapel Bell', Block.debris);
  b.person(eaves, hidden: true);
  b.hazards.add(
    const HazardEvent(
      220,
      HazardType.collapse,
      edge: 'st-bell',
      note: 'Bell Street chimney sheds',
    ),
  );
  b.goal(ObjectiveType.routeOpen, a: np, b: bell);
  b.goal(ObjectiveType.shelterOpen, target: chapel);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Contain + protect / changing wind.
SceneBuilder m053() {
  final b = SceneBuilder('M053', 2, 23)
    ..title = 'Changing Wind on Kiln Row'
    ..brief =
        'Kiln fire will follow the wind onto Kiln Row, which must stay open, then onto Well Court. The wind turns twice. One Extinguisher.'
    ..tutorial = [
      'Two wind notes, two spreads. Put the kiln out before the first or stand on Kiln Row.',
      'Juno is here for the smoke cut behind the kiln.',
    ]
    ..strategies = [
      'Extinguisher on Bea or Rosa at Kiln Post. Tomi escorts. Juno opens the back cut.',
      'If the first spread lands, stand on Kiln Row with the Extinguisher.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['smoke:80,240,200,200', 'cobble:360,480,280,80']);
  final kp = b.start('kp', 80, 80, 'Kiln Post');
  final mp = b.start('mp', 400, 80, 'Row Post', capacity: 2);
  final bp = b.start('bp', 720, 80, 'Back Post');
  final kiln = b.node('kiln', 140, 360, 'Kiln');
  final row = b.node('row', 400, 360, 'Kiln Row');
  final back = b.node('back', 680, 360, 'Back Cut');
  final hall = b.shelter('hall', 400, 720, 'Well Court');
  b
    ..lane(kp, kiln, 'Kiln Drop')
    ..lane(mp, row, 'Row Drop')
    ..lane(bp, back, 'Back Drop')
    ..lane(kiln, row, 'Kiln to Row')
    ..lane(row, back, 'Row Smoke', Block.dark)
    ..lane(kiln, hall, 'Kiln Hall')
    ..lane(row, hall, 'Row Hall')
    ..lane(back, hall, 'Back Hall');
  b.fire(kiln);
  b.person(back, hidden: true);
  b.person(row);
  b.hazards.addAll(const [
    HazardEvent(70, HazardType.wind, note: 'Wind turns onto Kiln Row'),
    HazardEvent(180, HazardType.spread, from: 'kiln', to: 'row'),
    HazardEvent(240, HazardType.wind, note: 'Wind turns onto Well Court'),
    HazardEvent(320, HazardType.spread, from: 'row', to: 'hall'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [row]);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Deliver + evacuate / limited equipment.
SceneBuilder m054() {
  final b = SceneBuilder('M054', 2, 24)
    ..title = 'One Toolkit, Two Jobs'
    ..brief =
        'Gable Hall is jammed and two oil tins must reach Clock Lamp. Neighbours wait on both the mill and the eaves. Only one Toolkit.'
    ..tutorial = [
      'Limited Toolkit. Bea can still repair without it.',
      'Sled hauls. Juno lights eaves. Rosa or Bea takes the door.',
    ]
    ..strategies = [
      'Toolkit unused: Bea repairs, Rosa sleds, Juno eaves, Tomi mill neighbour.',
      'Toolkit on Rosa if Bea is needed on heavy shutters.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.toolkit, Gear.cargoSled]
    ..decor.addAll(['gable:520,200,240,180', 'cobble:80,700,240,160']);
  final n = b.start('n', 80, 80, 'Mill Post');
  final m = b.start('m', 400, 80, 'Hall Post', capacity: 2);
  final e = b.start('e', 720, 80, 'Eaves Post');
  final millN = b.node('mn', 120, 300, 'Mill Neighbour');
  final hall = b.shelter('hall', 400, 360, 'Gable Hall', broken: true);
  final depot = b.depot('dep', 200, 520, 'Oil Bay', 2);
  final eaves = b.node('eaves', 680, 400, 'East Eaves');
  final lamp = b.need('lamp', 680, 720, 'Clock Lamp', 2);
  b
    ..lane(n, millN, 'Mill Drop')
    ..lane(m, hall, 'Hall Drop')
    ..lane(e, eaves, 'Eaves Drop')
    ..lane(millN, hall, 'Mill Hall')
    ..lane(hall, depot, 'Hall Bay')
    ..lane(hall, eaves, 'Hall Smoke', Block.dark)
    ..lane(depot, 'lamp', 'Bay Lamp')
    ..lane(eaves, 'lamp', 'Eaves Lamp', Block.dark)
    ..lane(millN, depot, 'Mill Bay');
  b.person(millN);
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.delivered, target: lamp, count: 2);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Inspect then respond + open a safe route / uncertain visibility.
SceneBuilder m055() {
  final b = SceneBuilder('M055', 2, 25)
    ..title = 'Fog Forks'
    ..brief =
        'South Bell must be reachable from North Fork. Both west eaves and east gable are unlit, and callers are hidden on both. Light them, then open a tower road.'
    ..tutorial = [
      'Uncertain visibility on both forks. Juno or Floodlight.',
      'Revealing both forks is the inspect job. The tower road can use either.',
    ]
    ..strategies = [
      'Juno west, Floodlight on Bea east, Rosa and Tomi escort.',
      'Juno both forks; others wait at the fork.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.floodlight, Gear.cutter]
    ..decor.addAll([
      'eaves:40,360,200,200',
      'gable:560,360,200,200',
      'smoke:240,200,320,80',
    ]);
  final nf = b.start('nf', 400, 80, 'North Fork', capacity: 2);
  final wp = b.start('wp', 80, 200, 'West Post');
  final ep = b.start('ep', 720, 200, 'East Post');
  final fork = b.node('fork', 400, 280, 'Fog Fork', NodeKind.junction);
  final west = b.node('west', 140, 560, 'Fog Eaves');
  final east = b.node('east', 660, 560, 'Fog Gable');
  final bell = b.node('bell', 400, 900, 'South Bell', NodeKind.lookout);
  final hall = b.shelter('hall', 400, 700, 'Fork Hall');
  b
    ..lane(nf, fork, 'North to Fork')
    ..lane(wp, west, 'West Drop')
    ..lane(ep, east, 'East Drop')
    ..lane(fork, west, 'West Fog', Block.dark)
    ..lane(fork, east, 'East Fog', Block.dark)
    ..lane(west, hall, 'West Hall', Block.dark)
    ..lane(east, hall, 'East Hall', Block.dark)
    ..lane(fork, hall, 'Fork Hall Lane')
    ..lane(hall, bell, 'Hall Bell')
    ..lane(west, bell, 'West Bell', Block.debris)
    ..lane(east, bell, 'East Bell', Block.debris);
  b.person(west, hidden: true);
  b.person(east, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['fork-west', 'fork-east']);
  b.goal(ObjectiveType.routeOpen, a: nf, b: bell);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Restore shelter + deliver / split start positions.
SceneBuilder m056() {
  final b = SceneBuilder('M056', 2, 26)
    ..title = 'Split Keys'
    ..brief =
        'Chapel door is jammed and one tin must reach Clock Lamp. Four posts, one responder each: chapel, mill, lamp, and eaves. The eaves caller is hidden.'
    ..tutorial = [
      'Split starts, four posts. Nobody shares a gate.',
      'Bea belongs on chapel. Sled on mill. Juno eaves. The lamp post is a finish, not a start job.',
    ]
    ..strategies = [
      'Bea chapel, Rosa mill with sled, Juno eaves, Tomi lamp to receive and escort.',
      'Tomi chapel if Bea is sent mill; slower door.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.toolkit, Gear.cargoSled]
    ..decor.addAll(['gable:40,400,180,160', 'eaves:580,400,180,160']);
  final cp = b.start('cp', 80, 80, 'Chapel Post');
  final mp = b.start('mp', 280, 80, 'Mill Post');
  final lp = b.start('lp', 520, 80, 'Lamp Post');
  final ep = b.start('ep', 720, 80, 'Eaves Post');
  final chapel = b.shelter('chapel', 120, 360, 'Lane Chapel', broken: true);
  final mill = b.depot('mill', 300, 400, 'Mill Bay', 1);
  final lamp = b.need('lamp', 520, 520, 'Clock Lamp', 1);
  final eaves = b.node('eaves', 700, 400, 'Key Eaves');
  final hall = b.shelter('hall', 400, 780, 'South Hall');
  b
    ..lane(cp, chapel, 'Chapel Drop')
    ..lane(mp, mill, 'Mill Drop')
    ..lane(lp, 'lamp', 'Lamp Drop')
    ..lane(ep, eaves, 'Eaves Drop')
    ..lane(chapel, mill, 'Chapel Mill')
    ..lane(mill, 'lamp', 'Mill Lamp')
    ..lane(eaves, 'lamp', 'Eaves Lamp', Block.dark)
    ..lane(chapel, hall, 'Chapel Hall')
    ..lane('lamp', hall, 'Lamp Hall')
    ..lane(eaves, hall, 'Eaves Hall', Block.dark);
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.shelterOpen, target: chapel);
  b.goal(ObjectiveType.delivered, target: lamp, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Two dependent teams + restore shelter / two viable routes.
SceneBuilder m057() {
  final b = SceneBuilder('M057', 2, 27)
    ..title = 'Two Roads to the Chapel'
    ..brief =
        'Chapel door is jammed. A loft caller is hidden up a dark stair. West shutters and east smoke are two real roads to the chapel. Loft work does not open those roads by itself.'
    ..tutorial = [
      'Dependent: loft stair is a separate job from the chapel roads.',
      'Two viable roads. You only need one plus the loft.',
    ]
    ..strategies = [
      'Bea chapel via west. Juno loft. Rosa and Tomi east or west.',
      'All east through smoke; Bea still has to reach the door.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.toolkit, Gear.cutter]
    ..decor.addAll(['eaves:40,200,180,200', 'smoke:560,200,200,200']);
  final wp = b.start('wp', 80, 80, 'West Post');
  final lp = b.start('lp', 280, 80, 'Loft Post');
  final mp = b.start('mp', 520, 80, 'Mid Post');
  final ep = b.start('ep', 720, 80, 'East Post');
  final west = b.node('west', 120, 320, 'West Shutters');
  final loft = b.node('loft', 280, 360, 'Loft Stair');
  final east = b.node('east', 680, 320, 'East Smoke');
  final chapel = b.shelter('chapel', 400, 620, 'Lane Chapel', broken: true);
  final hall = b.shelter('hall', 400, 900, 'South Hall');
  b
    ..lane(wp, west, 'West Drop')
    ..lane(lp, loft, 'Loft Drop')
    ..lane(mp, chapel, 'Mid Chapel', Block.debris)
    ..lane(ep, east, 'East Drop')
    ..lane(west, chapel, 'West Chapel', Block.debris)
    ..lane(east, chapel, 'East Chapel', Block.dark)
    ..lane(loft, chapel, 'Loft Chapel', Block.dark)
    ..lane(chapel, hall, 'Chapel Hall')
    ..lane(west, hall, 'West Hall')
    ..lane(east, hall, 'East Hall', Block.dark);
  b.person(loft, hidden: true);
  b.person(west);
  b.goal(ObjectiveType.shelterOpen, target: chapel);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Protect two corridors / blocked junction.
SceneBuilder m058() {
  final b = SceneBuilder('M058', 2, 28)
    ..title = 'Blocked Cross, Two Lanes'
    ..brief =
        'Market Arcade and Bell Lane must both stay clear. Well Cross is packed with shutters, so crews cannot turn between the two lanes until that junction is cleared. A hearth south of the cross feeds both.'
    ..tutorial = [
      'Two lanes to protect, one blocked turn between them.',
      'Clear Well Cross or fight each fire from its own gate.',
    ]
    ..strategies = [
      'Extinguisher on the south starter next to the hearth. Rosa on the cross. Juno Market smoke. Tomi Bell Lane.',
      'If the cross stays shut, each lane is its own fight.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.extinguisher, Gear.cutter]
    ..decor.addAll(['cobble:200,480,400,80', 'smoke:320,700,160,140']);
  final mp = b.start('mp', 80, 80, 'Market Post');
  final cp = b.start('cp', 400, 80, 'Cross Post');
  final bp = b.start('bp', 720, 80, 'Bell Post');
  final sp = b.start('sp', 400, 980, 'South Hearth');
  final market = b.node('mkt', 140, 360, 'Market Arcade');
  final cross = b.node('cross', 400, 360, 'Well Cross', NodeKind.junction);
  final bell = b.node('bell', 680, 360, 'Bell Lane');
  final hearth = b.node('hearth', 400, 720, 'South Hearth');
  final hall = b.shelter('hall', 400, 200, 'North Hall');
  b
    ..lane(mp, market, 'Market Drop')
    ..lane(cp, cross, 'Cross Drop')
    ..lane(bp, bell, 'Bell Drop')
    ..lane(sp, hearth, 'Hearth Rise')
    ..lane(market, cross, 'Market Cross', Block.debris)
    ..lane(cross, bell, 'Cross Bell', Block.debris)
    ..lane(hearth, cross, 'Hearth Cross')
    ..lane(hearth, market, 'Hearth Market', Block.dark)
    ..lane(hearth, bell, 'Hearth Bell')
    ..lane(market, hall, 'Market Hall')
    ..lane(bell, hall, 'Bell Hall')
    ..lane(cross, hall, 'Cross Hall');
  b.fire(hearth);
  b.person(market);
  b.person(bell);
  b.hazards.addAll(const [
    HazardEvent(200, HazardType.spread, from: 'hearth', to: 'mkt'),
    HazardEvent(200, HazardType.spread, from: 'hearth', to: 'bell'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [market, bell]);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Simultaneous calls + evacuate / branching access.
SceneBuilder m059() {
  final b = SceneBuilder('M059', 2, 29)
    ..title = 'Bell and Baker at Once'
    ..brief =
        'A baker needs care in the west yard and a bell keeper needs care in the east loft. Branching smoke: lighting one side does not light the other. Walk both to North Hall.'
    ..tutorial = [
      'Two calls, two smokes. Juno cannot be on both forks at tick zero.',
      'Tomi still has to steady both. Send her after each fork opens, or split first aid.',
    ]
    ..strategies = [
      'Juno west, Floodlight on Bea east, Tomi follows the first open fork, Rosa escorts the other.',
      'First aid on Rosa so two people can care.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['eaves:40,400,200,200', 'gable:560,400,200,200']);
  final np = b.start('np', 400, 80, 'North Hall Gate', capacity: 2);
  final wp = b.start('wp', 80, 200, 'Baker Post');
  final ep = b.start('ep', 720, 200, 'Bell Post');
  final hall = b.shelter('hall', 400, 280, 'North Hall');
  final baker = b.node('baker', 140, 560, 'Baker Yard');
  final loft = b.node('loft', 660, 560, 'Bell Loft');
  final deepB = b.node('db', 140, 840, 'Deep Baker');
  final deepL = b.node('dl', 660, 840, 'Deep Loft');
  b
    ..lane(np, hall, 'Gate Hall')
    ..lane(wp, baker, 'Baker Drop')
    ..lane(ep, loft, 'Loft Drop')
    ..lane(hall, baker, 'Hall Baker', Block.dark)
    ..lane(hall, loft, 'Hall Loft', Block.dark)
    ..lane(baker, deepB, 'Deep Baker Smoke', Block.dark)
    ..lane(loft, deepL, 'Deep Loft Smoke', Block.dark)
    ..lane(baker, loft, 'Yard Cut', Block.debris);
  final bake = b.person(baker, care: true);
  final keep = b.person(loft, care: true, hidden: true);
  b.person(deepB, hidden: true);
  b.person(deepL, hidden: true);
  b.goal(ObjectiveType.stabilized, target: bake);
  b.goal(ObjectiveType.stabilized, target: keep);
  b.goal(ObjectiveType.civiliansSafe, count: 4);
  return b;
}

/// District finale: evacuate + open a safe route / timed shelter capacity.
SceneBuilder m060() {
  final b = SceneBuilder('M060', 2, 30)
    ..title = 'Old Town Night'
    ..brief =
        'Bell Tower must be reachable from Night Gate. Three neighbours are still in the lanes. Tiny Well seats one; Lane Chapel opens at twelve seconds. Smoke hides the east eaves caller. This is the Old Town finale.'
    ..tutorial = [
      'Finale: tower road, three people, two shelters with a clock.',
      'Seat one at the well, wait for chapel, or repair nothing — the chapel only waits on time.',
    ]
    ..strategies = [
      'Juno east eaves. Rosa Bell Shutters. Tomi first neighbour to the well. Bea spare on any leftover lane.',
      'Ignore shutters and walk the eaves road to the tower after Juno opens it.',
    ]
    ..teamSize = 4
    ..roles = _quad
    ..gear = [Gear.cutter, Gear.floodlight]
    ..decor.addAll([
      'eaves:520,360,240,200',
      'cobble:80,80,280,120',
      'gable:280,860,240,100',
      'smoke:360,400,120,80',
    ]);
  final ng = b.start('ng', 400, 80, 'Night Gate', capacity: 2);
  final wg = b.start('wg', 80, 200, 'Well Gate');
  final eg = b.start('eg', 720, 200, 'Eaves Gate');
  final street = b.node('st', 400, 280, 'Night Street');
  final wellN = b.node('wn', 160, 480, 'Well Neighbour');
  final eaves = b.node('eaves', 660, 480, 'Night Eaves');
  final tiny = b.shelter('tiny', 400, 520, 'Tiny Well', capacity: 1);
  final chapel = b.shelter('chapel', 400, 780, 'Lane Chapel', openAt: 120);
  final bell = b.node('bell', 400, 980, 'Bell Tower', NodeKind.lookout);
  b
    ..lane(ng, street, 'Night Drop')
    ..lane(wg, wellN, 'Well Drop')
    ..lane(eg, eaves, 'Eaves Drop')
    ..lane(street, wellN, 'Street Well')
    ..lane(street, eaves, 'Street Eaves', Block.dark)
    ..lane(street, tiny, 'Street Tiny')
    ..lane(wellN, tiny, 'Neighbour Tiny')
    ..lane(eaves, tiny, 'Eaves Tiny', Block.dark)
    ..lane(tiny, chapel, 'Tiny Chapel')
    ..lane(chapel, bell, 'Chapel Bell')
    ..lane(street, bell, 'Bell Shutters', Block.debris)
    ..lane(eaves, bell, 'Eaves Bell', Block.dark);
  b.person(wellN);
  b.person(street);
  b.person(eaves, hidden: true);
  b.goal(ObjectiveType.routeOpen, a: ng, b: bell);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

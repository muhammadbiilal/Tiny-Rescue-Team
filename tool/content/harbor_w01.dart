// Harbor District M011-M030. Original layouts; briefs are the production queue.
// Free roster is three roles until Old Town (Scout at 31), so teamSize is 3
// even where the CSV asked for 4.
import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

import 'builder.dart';

const _trio = [Role.rescuer, Role.medic, Role.engineer];

List<SceneBuilder> harborRest() => [
  m011(),
  m012(),
  m013(),
  m014(),
  m015(),
  m016(),
  m017(),
  m018(),
  m019(),
  m020(),
  m021(),
  m022(),
  m023(),
  m024(),
  m025(),
  m026(),
  m027(),
  m028(),
  m029(),
  m030(),
];

/// Evac + contain / timed shelter capacity.
SceneBuilder m011() {
  final b = SceneBuilder('M011', 1, 11)
    ..title = 'Ice House Queue'
    ..brief =
        'Three workers wait along the ice quay. The Ice House holds only one person. The Salt Chapel opens at 12 seconds. '
        'A tar pot fire at the Cooperage will reach Ice House if it is not put out.'
    ..tutorial = [
      'Bea Kowal joins the free team. She clears debris faster than Rosa and can repair doors.',
      'A shelter with a number on it fills up. Send later people to the chapel after it opens.',
    ]
    ..strategies = [
      'Extinguisher on whoever starts at Cooper Yard. Tomi escorts the critical worker first.',
      'Bea clears the crate lane so the chapel path is ready when the door opens.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.extinguisher, Gear.cutter]
    ..decor.addAll(['water:0,0,800,160', 'ice:80,480,180,160']);
  final south = b.start('south', 400, 980, 'Salt Gate', capacity: 2);
  final coop = b.start('coop', 120, 820, 'Cooper Yard');
  final fork = b.node('fork', 400, 780, 'Ice Fork', NodeKind.junction);
  final ice = b.shelter('ice', 400, 520, 'Ice House', capacity: 1);
  final chapel = b.shelter('chapel', 680, 280, 'Salt Chapel', openAt: 120);
  final coopN = b.node('cn', 140, 560, 'Cooperage');
  final quay = b.node('quay', 220, 300, 'Ice Quay', NodeKind.pier);
  final nets = b.node('nets', 560, 700, 'Net Loft');
  b
    ..lane(south, fork, 'Salt Road')
    ..lane(coop, coopN, 'Cooper Path')
    ..lane(coop, fork, 'Yard Fence')
    ..lane(fork, ice, 'Ice Steps')
    ..lane(fork, nets, 'Loft Lane')
    ..lane(ice, chapel, 'Chapel Walk', Block.debris)
    ..lane(nets, chapel, 'Loft Hill')
    ..lane(coopN, quay, 'Quay Steps')
    ..lane(quay, ice, 'Ice Ramp')
    ..lane(coopN, ice, 'Tar Alley');
  b.fire(coopN);
  b.person(quay, critical: true);
  b.person(nets);
  b.person(coopN, care: true);
  b.hazards.add(
    const HazardEvent(200, HazardType.spread, from: 'cn', to: 'ice'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Stabilize + inspect / one constrained vehicle (single cargo sled).
SceneBuilder m012() {
  final b = SceneBuilder('M012', 1, 12)
    ..title = 'One Cart on the Mole'
    ..brief =
        'Fog hides a caller on the Outer Mole. The mole keeper needs care. One cargo sled is the only cart that '
        'can haul the two lamp-oil crates to the Beacon.'
    ..tutorial = [
      'One sled: only the carrier of the Cargo Sled can move crates. Everyone else must light, clear, or care.',
      'Dark lanes hide the mole until they are lit or someone stands next to them.',
    ]
    ..strategies = [
      'Sled on Rosa from the Store. Floodlight on Bea toward the mole. Tomi cares for the keeper.',
      'Sled on Bea; Rosa lights; Tomi stays with the keeper until the mole is found.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.cargoSled, Gear.floodlight, Gear.firstAid]
    ..decor.addAll(['water:0,0,800,200', 'mole:500,80,220,80']);
  final gate = b.start('gate', 200, 980, 'Mole Gate', capacity: 2);
  final store = b.start('storeS', 620, 960, 'Oil Store');
  final yard = b.node('yard', 300, 760, 'Cart Yard', NodeKind.junction);
  final keep = b.node('keep', 160, 480, 'Keeper Hut');
  final depot = b.depot('depot', 620, 760, 'Oil Shed', 2);
  final mid = b.node('mid', 400, 480, 'Mole Root');
  final dark = b.node('dark', 560, 280, 'Outer Mole', NodeKind.pier);
  final beacon = b.need('beacon', 700, 180, 'Beacon', 2);
  final hall = b.shelter('hall', 300, 300, 'Mole Hall');
  b
    ..lane(gate, yard, 'Gate Road')
    ..lane(store, depot, 'Store Ramp')
    ..lane(depot, yard, 'Shed Lane')
    ..lane(yard, keep, 'Hut Path')
    ..lane(yard, mid, 'Mole Road')
    ..lane(mid, hall, 'Hall Cut')
    ..lane(keep, hall, 'Hut Terrace')
    ..lane(mid, dark, 'Fog Mole', Block.dark)
    ..lane(dark, 'beacon', 'Beacon Walk', Block.dark)
    ..lane(hall, 'beacon', 'Hall Beacon', Block.debris);
  b.person(keep, care: true, critical: true);
  b.person(dark, hidden: true);
  b.goal(ObjectiveType.stabilized, target: 'c1');
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  b.goal(ObjectiveType.delivered, target: beacon, count: 2);
  return b;
}

/// Route + two teams / shared cutter.
SceneBuilder m013() {
  final b = SceneBuilder('M013', 1, 13)
    ..title = 'Twin Spills'
    ..brief =
        'The Fish Market must stay linked to the Ferry Slip. Two crate spills sit on different streets. '
        'The team shares one Cutter; Bea can still shift debris with her own tools.'
    ..tutorial = [
      'Shared gear: only one Cutter. Bea clears without it. Rosa is much faster with it.',
      'The route is open only when a walker can go from Market Gate to Ferry Slip.',
    ]
    ..strategies = [
      'Cutter on Rosa for the east spill; Bea takes the west spill; Tomi waits to escort.',
      'Bea and Rosa swap sides if Tomi starts nearer the west civilian.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.cutter]
    ..decor.addAll(['water:620,0,180,1040', 'market:80,400,200,160']);
  final gate = b.start('gate', 200, 980, 'Market Gate', capacity: 2);
  final west = b.start('west', 80, 700, 'Barrel Court');
  final mkt = b.node('mkt', 220, 720, 'Fish Market', NodeKind.junction);
  final wspill = b.node('ws', 80, 440, 'West Spill');
  final espill = b.node('es', 400, 500, 'East Spill');
  final slip = b.node('slip', 520, 180, 'Ferry Slip', NodeKind.pier);
  final hall = b.shelter('hall', 280, 280, 'Market Hall');
  final jetty = b.node('jet', 80, 200, 'Old Jetty');
  b
    ..lane(gate, mkt, 'Market Road')
    ..lane(west, wspill, 'Court Lane')
    ..lane(west, mkt, 'Court Cross')
    ..lane(mkt, wspill, 'West Street', Block.debris)
    ..lane(mkt, espill, 'East Street', Block.debris)
    ..lane(wspill, hall, 'West Hall')
    ..lane(espill, hall, 'East Hall')
    ..lane(hall, slip, 'Hall Slip')
    ..lane(wspill, jetty, 'Jetty Path')
    ..lane(jetty, slip, 'Jetty Slip');
  b.person(wspill);
  b.person(espill);
  b.goal(ObjectiveType.routeOpen, a: gate, b: slip);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Contain + simultaneous / fatigue.
SceneBuilder m014() {
  final b = SceneBuilder('M014', 1, 14)
    ..title = 'Long Shift at the Tar Works'
    ..brief =
        'A pot fire at the Tar Works will reach the Drying Racks. A crate is due at the Pump, and two people need guiding. '
        'After two finished tasks each responder must rest.'
    ..tutorial = [
      'Fatigue: after two finished jobs a responder rests. Spread the work.',
      'Three calls: fire, pump crates, and people. Priorities decide the order.',
    ]
    ..strategies = [
      'Extinguisher on Bea at the works. Tomi people-first. Rosa takes the sled.',
      'Rosa holds the fire; Bea clears the pump lane; Tomi escorts.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.extinguisher, Gear.cargoSled]
    ..rules = const Rules(fatigueJobs: 2, restTicks: 30)
    ..decor.addAll(['water:0,0,800,100', 'works:480,200,220,180']);
  final gate = b.start('gate', 360, 980, 'Works Gate', capacity: 2);
  final side = b.start('side', 700, 860, 'Rack Lane');
  final yard = b.node('yard', 360, 760, 'Tar Yard', NodeKind.junction);
  final works = b.node('works', 560, 520, 'Tar Works');
  final racks = b.node('racks', 700, 400, 'Drying Racks');
  final depot = b.depot('depot', 200, 760, 'Pitch Store', 2);
  final pump = b.need('pump', 120, 400, 'Pitch Pump', 2);
  final loft = b.node('loft', 360, 400, 'Coil Loft');
  final hall = b.shelter('hall', 360, 220, 'Works Hall');
  b
    ..lane(gate, yard, 'Works Road')
    ..lane(side, racks, 'Rack Path')
    ..lane(yard, works, 'Tar Lane')
    ..lane(works, racks, 'Rack Cut')
    ..lane(yard, depot, 'Store Cut')
    ..lane(depot, 'pump', 'Pump Lane', Block.debris)
    ..lane(yard, loft, 'Loft Steps')
    ..lane(loft, hall, 'Hall Stair')
    ..lane(works, loft, 'Coil Walk')
    ..lane(racks, hall, 'Rack Hall')
    ..lane('pump', hall, 'Pump Hall');
  b.fire(works);
  b.person(racks);
  b.person(loft, care: true);
  b.hazards.add(
    const HazardEvent(220, HazardType.spread, from: 'works', to: 'racks'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.delivered, target: pump, count: 2);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Deliver + stabilize / delayed collapse.
SceneBuilder m015() {
  final b = SceneBuilder('M015', 1, 15)
    ..title = 'Clinic Before the Arch Falls'
    ..brief =
        'The night nurse at the Old Clinic needs care. Three crates must reach the New Clinic. '
        'Lantern Arch is forecast to shed debris at 28 seconds. Get through before it closes, or take the seawall.'
    ..tutorial = [
      'The forecast names the lane that may close. Plan who uses it before that time.',
      'Care and crates are different jobs. Tomi should not be the only crate carrier.',
    ]
    ..strategies = [
      'Sled on Rosa through the arch early. Tomi to the Old Clinic. Bea holds the seawall as backup.',
      'All three take the seawall if nobody can beat the arch time.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.cargoSled, Gear.firstAid]
    ..decor.addAll(['water:0,0,200,1040', 'clinic:500,120,220,140']);
  final gate = b.start('gate', 400, 980, 'Hospital Gate', capacity: 2);
  final sea = b.start('sea', 160, 860, 'Seawall Stair');
  final cross = b.node('cross', 400, 760, 'Lamp Cross', NodeKind.junction);
  final depot = b.depot('depot', 560, 760, 'Linen Store', 3);
  final oldc = b.node('old', 640, 500, 'Old Clinic');
  final arch = b.node('arch', 400, 500, 'Lantern Arch');
  final neu = b.need('neu', 400, 180, 'New Clinic', 3);
  final wall = b.node('wall', 160, 400, 'Seawall');
  final hall = b.shelter('hall', 240, 180, 'Nurses Hall');
  b
    ..lane(gate, cross, 'Hospital Road')
    ..lane(sea, wall, 'Stair Path')
    ..lane(cross, depot, 'Linen Lane')
    ..lane(cross, arch, 'Arch Approach')
    ..lane(arch, 'neu', 'Lantern Arch')
    ..lane(depot, oldc, 'Clinic Row')
    ..lane(oldc, 'neu', 'Clinic Link', Block.debris)
    ..lane(sea, cross, 'Stair Cross')
    ..lane(wall, hall, 'Wall Hall')
    ..lane(hall, 'neu', 'Hall Clinic')
    ..lane(oldc, hall, 'Nurse Walk');
  final nurse = b.person(oldc, care: true, critical: true);
  b.hazards.add(
    const HazardEvent(
      280,
      HazardType.collapse,
      edge: 'arch-neu',
      note: 'Lantern Arch may fall',
    ),
  );
  b.goal(ObjectiveType.stabilized, target: nurse);
  b.goal(ObjectiveType.delivered, target: neu, count: 3);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Inspect + contain / changing wind.
SceneBuilder m016() {
  final b = SceneBuilder('M016', 1, 16)
    ..title = 'Wind Over the Smokehouse'
    ..brief =
        'Callers cannot see who is in the smokehouse lane. A small fire there will follow the wind onto the Net Walk '
        'at 18 seconds, then toward Harbor Hall if it is still burning.'
    ..tutorial = [
      'Wind lines in the forecast tell you where fire wants to go next.',
      'Light the dark lane first, then put the fire out before the second spread.',
    ]
    ..strategies = [
      'Floodlight and Extinguisher on the same starter at Smoke Gate if you want one person to find and kill the fire.',
      'Split: Bea lights, Rosa carries the Extinguisher, Tomi waits at the hall for anyone found.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.floodlight, Gear.extinguisher]
    ..decor.addAll(['water:0,0,800,120', 'smoke:200,300,200,160']);
  final g1 = b.start('g1', 200, 980, 'Smoke Gate');
  final g2 = b.start('g2', 600, 980, 'Net Gate', capacity: 2);
  final sq = b.node('sq', 400, 780, 'Smoke Square', NodeKind.junction);
  final smoke = b.node('smoke', 240, 500, 'Smokehouse');
  final nets = b.node('nets', 400, 500, 'Net Walk');
  final hall = b.shelter('hall', 560, 320, 'Harbor Hall');
  final dark = b.node('dark', 120, 320, 'Ash Lane');
  b
    ..lane(g1, sq, 'Smoke Road')
    ..lane(g2, sq, 'Net Road')
    ..lane(sq, smoke, 'House Lane')
    ..lane(sq, nets, 'Walk Approach')
    ..lane(smoke, nets, 'Smoke Walk')
    ..lane(nets, hall, 'Hall Walk')
    ..lane(smoke, dark, 'Ash Dark', Block.dark)
    ..lane(dark, hall, 'Ash Hall', Block.dark)
    ..lane(g2, hall, 'East Bypass');
  b.fire(smoke);
  b.person(dark, hidden: true);
  b.person(nets);
  b.hazards.addAll([
    const HazardEvent(80, HazardType.wind, note: 'Wind turns toward Net Walk'),
    const HazardEvent(180, HazardType.spread, from: 'smoke', to: 'nets'),
    const HazardEvent(280, HazardType.spread, from: 'nets', to: 'hall'),
  ]);
  b.goal(ObjectiveType.revealed, nodes: ['smoke-dark', 'dark-hall']);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Shelter repair + inspect / limited equipment.
SceneBuilder m017() {
  final b = SceneBuilder('M017', 1, 17)
    ..title = 'One Toolkit'
    ..brief =
        "Storm doors on both Harbor Hall and the Watch Loft are jammed. Only one Toolkit is in the van. "
        'Someone is still unaccounted for behind the unlit Watch Stair.'
    ..tutorial = [
      'One Toolkit. Bea can repair without it, but slowly. Use her on one door.',
      'The hidden caller appears when the dark stair is lit or a responder reaches the loft.',
    ]
    ..strategies = [
      'Toolkit on Rosa for Harbor Hall. Bea repairs the loft. Tomi carries the Floodlight.',
      'Bea does both doors if the others only escort. Slower, still possible.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.toolkit, Gear.floodlight]
    ..decor.addAll(['water:0,0,800,90', 'loft:80,160,160,140']);
  final a = b.start('a', 120, 960, 'West Post');
  final c = b.start('c', 400, 960, 'Center Post');
  final e = b.start('e', 680, 960, 'East Post');
  final mid = b.node('mid', 400, 740, 'Post Square', NodeKind.junction);
  final hall = b.shelter('hall', 400, 480, 'Harbor Hall', broken: true);
  final loft = b.shelter('loft', 160, 240, 'Watch Loft', broken: true);
  final stair = b.node('stair', 160, 480, 'Watch Stair');
  final cafe = b.node('cafe', 640, 480, 'Night Café');
  b
    ..lane(a, mid, 'West Road')
    ..lane(c, mid, 'Center Road')
    ..lane(e, mid, 'East Road')
    ..lane(mid, hall, 'Hall Approach')
    ..lane(mid, stair, 'Stair Lane')
    ..lane(stair, loft, 'Watch Stair', Block.dark)
    ..lane(mid, cafe, 'Café Row')
    ..lane(cafe, hall, 'Café Hall')
    ..lane(hall, loft, 'Hall Loft', Block.debris)
    ..lane(cafe, loft, 'Café Loft');
  b.person(cafe, care: true);
  b.person(loft, hidden: true);
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Two real teams (not a duplicate phrase) / uncertain visibility.
SceneBuilder m018() {
  final b = SceneBuilder('M018', 1, 18)
    ..title = 'Warehouse and the Night Pier'
    ..brief =
        'Two separate jobs must finish: light and empty the Dark Warehouse, and bring the night-pier watch in. '
        'The warehouse lanes stay dark until someone lights them. The pier is a different street.'
    ..tutorial = [
      'Do not send everyone into the warehouse. One responder can work the lit pier.',
      'Hidden people in the warehouse count only after the dark lanes are opened.',
    ]
    ..strategies = [
      'Floodlight on Bea into the warehouse. Tomi and Rosa take the pier watch.',
      'Rosa lights; Bea clears the inner crate; Tomi stays with the pier.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.floodlight, Gear.cutter]
    ..decor.addAll(['water:0,620,800,420', 'shed:80,80,280,220']);
  final north = b.start('north', 200, 200, 'Warehouse Dock', capacity: 2);
  final south = b.start('south', 600, 200, 'Pier Stair');
  final wh = b.node('wh', 200, 400, 'Warehouse Door');
  final inner = b.node('inner', 200, 620, 'Inner Aisle');
  final crate = b.node('crate', 80, 620, 'Crate Bay');
  final pier = b.node('pier', 600, 500, 'Night Pier', NodeKind.pier);
  final hall = b.shelter('hall', 400, 400, 'Night Hall');
  b
    ..lane(north, wh, 'Dock Door')
    ..lane(wh, inner, 'Dark Aisle', Block.dark)
    ..lane(inner, crate, 'Crate Dark', Block.dark)
    ..lane(wh, hall, 'Door Hall')
    ..lane(south, pier, 'Pier Steps')
    ..lane(pier, hall, 'Pier Hall')
    ..lane(inner, hall, 'Aisle Hall', Block.debris)
    ..lane(south, hall, 'Stair Hall');
  b.person(crate, hidden: true);
  b.person(inner, hidden: true);
  b.person(pier);
  b.goal(ObjectiveType.revealed, nodes: ['wh-inner', 'inner-crate']);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Protect corridor + two calls / split starts.
SceneBuilder m019() {
  final b = SceneBuilder('M019', 1, 19)
    ..title = 'Three Corners, One Lane'
    ..brief =
        'Ferry Lane must stay free of fire. The Paint Loft will try to spread onto it. A crate is due at the Ticket Hut, '
        'and a stall keeper needs care. Each starter stands in a different corner of the harbor.'
    ..tutorial = [
      'Split starts: one person per glowing corner. Plan who is nearest the fire.',
      'Protect fails if fire ever sits on Ferry Lane.',
    ]
    ..strategies = [
      'Extinguisher on the loft starter. Sled on the hut starter. Tomi from the stall corner.',
      'Bea from the loft if you want a fast clear after the fire is dead.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.extinguisher, Gear.cargoSled, Gear.firstAid]
    ..decor.addAll(['water:0,0,800,130', 'lane:360,300,80,280']);
  final a = b.start('a', 120, 960, 'Loft Corner');
  final c = b.start('c', 400, 960, 'Lane Corner');
  final e = b.start('e', 680, 960, 'Hut Corner');
  final loft = b.node('loft', 140, 560, 'Paint Loft');
  final lane = b.node('lane', 400, 560, 'Ferry Lane');
  final hut = b.need('hut', 660, 560, 'Ticket Hut', 1);
  final depot = b.depot('depot', 660, 780, 'Ticket Store', 1);
  final stall = b.node('stall', 400, 780, 'Fish Stall');
  final slip = b.node('slip', 400, 280, 'Ferry Slip', NodeKind.pier);
  final hall = b.shelter('hall', 220, 280, 'Lane Hall');
  b
    ..lane(a, loft, 'Loft Road')
    ..lane(c, stall, 'Lane Road')
    ..lane(e, depot, 'Hut Road')
    ..lane(loft, lane, 'Paint Cut')
    ..lane(stall, lane, 'Stall Lane')
    ..lane(depot, 'hut', 'Hut Steps')
    ..lane('hut', lane, 'Hut Lane')
    ..lane(lane, slip, 'Ferry Lane')
    ..lane(slip, hall, 'Slip Hall')
    ..lane(loft, hall, 'Loft Hall', Block.debris)
    ..lane(stall, hall, 'Stall Hall');
  b.fire(loft);
  b.person(stall, care: true);
  b.hazards.add(
    const HazardEvent(200, HazardType.spread, from: 'loft', to: 'lane'),
  );
  b.goal(ObjectiveType.protect, nodes: [lane]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.delivered, target: hut, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Two calls + stabilize / two viable routes.
SceneBuilder m020() {
  final b = SceneBuilder('M020', 1, 20)
    ..title = 'North Cut or the Long Quay'
    ..brief =
        'The chandler needs care. A small fire sits in the North Cut. You can reach both jobs by the short North Cut '
        '(blocked once) or the long quay that stays open.'
    ..tutorial = [
      'Two routes to the same pair of jobs. The short one needs a clearer.',
      'Set Tomi to people-first if the chandler is your worry.',
    ]
    ..strategies = [
      'Bea clears North Cut; Rosa takes Extinguisher through it; Tomi walks the long quay.',
      'Everyone takes the long quay. Slower, no debris.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.extinguisher, Gear.cutter]
    ..decor.addAll(['water:0,0,800,180', 'cut:80,300,120,200']);
  final g = b.start('g', 400, 980, 'Quay Gate', capacity: 3);
  final fork = b.node('fork', 400, 760, 'Quay Fork', NodeKind.junction);
  final cut = b.node('cut', 180, 500, 'North Cut');
  final chand = b.node('chand', 180, 280, 'Chandler');
  final long1 = b.node('l1', 620, 560, 'Long Quay');
  final long2 = b.node('l2', 620, 280, 'Far Quay');
  final hall = b.shelter('hall', 400, 280, 'Quay Hall');
  b
    ..lane(g, fork, 'Gate Walk')
    ..lane(fork, cut, 'Cut Mouth', Block.debris)
    ..lane(cut, chand, 'Cut Fire')
    ..lane(chand, hall, 'Chandler Hall')
    ..lane(fork, long1, 'Long Start')
    ..lane(long1, long2, 'Long Mid')
    ..lane(long2, hall, 'Long End')
    ..lane(cut, hall, 'Cut Hall');
  b.fire(cut);
  final ch = b.person(chand, care: true, critical: true);
  b.person(long2);
  b.goal(ObjectiveType.stabilized, target: ch);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Evac + contain / blocked junction.
SceneBuilder m021() {
  final b = SceneBuilder('M021', 1, 21)
    ..title = 'Five Ways is Packed'
    ..brief =
        'Five Ways is buried under crates. Three people wait on three arms of the junction. A coil fire at the Rope Walk '
        'will spread into Five Ways if the spill is still there as a wall of fuel.'
    ..tutorial = [
      'The junction is the problem. Until it is clear, most arms cannot meet.',
      'There is no fourth free responder in Harbor. Use Rosa, Tomi, and Bea.',
    ]
    ..strategies = [
      'Bea and Rosa both clear toward Five Ways. Tomi waits on the arm with the critical caller.',
      'Extinguisher first if you fear the spread more than the wait.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.extinguisher, Gear.cutter, Gear.toolkit]
    ..decor.addAll(['water:0,0,800,100', 'five:300,500,200,200']);
  final n = b.start('n', 400, 160, 'North Arm');
  final s = b.start('s', 400, 980, 'South Arm', capacity: 2);
  final five = b.node('five', 400, 560, 'Five Ways', NodeKind.junction);
  final rope = b.node('rope', 160, 560, 'Rope Walk');
  final east = b.node('east', 640, 560, 'East Arm');
  final hall = b.shelter('hall', 400, 360, 'Junction Hall');
  b
    ..lane(s, five, 'South Approach', Block.debris)
    ..lane(n, hall, 'North Hall')
    ..lane(hall, five, 'Hall Five', Block.debris)
    ..lane(five, rope, 'West Five', Block.debris)
    ..lane(five, east, 'East Five')
    ..lane(rope, hall, 'Rope Hall')
    ..lane(east, hall, 'East Hall')
    ..lane(n, east, 'North East');
  b.fire(rope);
  b.person(rope, critical: true);
  b.person(east);
  b.person(s);
  b.hazards.add(
    const HazardEvent(240, HazardType.spread, from: 'rope', to: 'five'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Stabilize + inspect / branching access.
SceneBuilder m022() {
  final b = SceneBuilder('M022', 1, 22)
    ..title = 'Three Branches of the Creek'
    ..brief =
        'West Creek hides a caller in the reeds. East Creek has a boat-builder who needs care. '
        'The middle creek is the only dry walk to Creek Hall unless a branch is cleared.'
    ..tutorial = [
      'Three branches. You do not need all three open, but the hidden caller is on the dark west branch.',
      'Care is on the east branch. Do not make Tomi walk the long way twice.',
    ]
    ..strategies = [
      'Floodlight west, Tomi east, Bea middle if crates of debris block the hall.',
      'Open only west and east; leave the middle blocked if the hall is already reached.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.floodlight, Gear.firstAid, Gear.cutter]
    ..decor.addAll(['water:0,200,800,200', 'creek:0,400,800,80']);
  final g = b.start('g', 400, 980, 'Creek Gate', capacity: 3);
  final split = b.node('split', 400, 760, 'Creek Split', NodeKind.junction);
  final w = b.node('w', 140, 520, 'West Creek');
  final reed = b.node('reed', 80, 280, 'Reed Hide', NodeKind.pier);
  final m = b.node('m', 400, 520, 'Middle Creek');
  final e = b.node('e', 660, 520, 'East Creek');
  final boat = b.node('boat', 700, 280, 'Boat Shed');
  final hall = b.shelter('hall', 400, 280, 'Creek Hall');
  b
    ..lane(g, split, 'Gate Creek')
    ..lane(split, w, 'West Mouth')
    ..lane(w, reed, 'Reed Dark', Block.dark)
    ..lane(split, m, 'Middle Mouth', Block.debris)
    ..lane(m, hall, 'Middle Hall')
    ..lane(split, e, 'East Mouth')
    ..lane(e, boat, 'Boat Path')
    ..lane(boat, hall, 'Boat Hall')
    ..lane(reed, hall, 'Reed Hall', Block.dark)
    ..lane(w, hall, 'West Hall');
  final builder = b.person(boat, care: true, critical: true);
  b.person(reed, hidden: true);
  b.goal(ObjectiveType.stabilized, target: builder);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Route + two jobs / timed shelter capacity.
SceneBuilder m023() {
  final b = SceneBuilder('M023', 1, 23)
    ..title = 'Hall Holds Two'
    ..brief =
        'Keep a walking route from South Gate to the Signal Mast. Harbor Hall holds only two people and is already '
        'the goal shelter. A third person must wait for the Signal Hut to open at 20 seconds.'
    ..tutorial = [
      'Capacity two. The third person needs the hut after it opens.',
      'The mast route is a separate objective from the people.',
    ]
    ..strategies = [
      'Bea opens the mast road. Tomi and Rosa fill the hall first, then the hut.',
      'Send the farthest person toward the hut early so they arrive as it opens.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.cutter]
    ..decor.addAll(['water:0,0,800,110', 'mast:600,80,120,120']);
  final gate = b.start('gate', 200, 980, 'South Gate', capacity: 2);
  final east = b.start('east', 640, 900, 'East Stair');
  final sq = b.node('sq', 320, 740, 'South Square', NodeKind.junction);
  final hall = b.shelter('hall', 320, 480, 'Harbor Hall', capacity: 2);
  final hut = b.shelter('hut', 640, 280, 'Signal Hut', openAt: 200);
  final mast = b.node('mast', 640, 120, 'Signal Mast', NodeKind.lookout);
  final west = b.node('west', 120, 400, 'West Cottages');
  final mid = b.node('mid', 480, 400, 'Mast Road');
  b
    ..lane(gate, sq, 'South Road')
    ..lane(east, mid, 'Stair Road')
    ..lane(sq, hall, 'Hall Steps')
    ..lane(sq, west, 'Cottage Lane')
    ..lane(west, hall, 'Cottage Hall')
    ..lane(hall, mid, 'Hall Mast', Block.debris)
    ..lane(mid, hut, 'Hut Road')
    ..lane(hut, mast, 'Mast Steps')
    ..lane(east, hut, 'East Hut')
    ..lane(west, mast, 'Long Mast', Block.debris);
  b.person(west);
  b.person(mid);
  b.person(east);
  b.goal(ObjectiveType.routeOpen, a: gate, b: mast);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Contain + two calls / one sled.
SceneBuilder m024() {
  final b = SceneBuilder('M024', 1, 24)
    ..title = 'The Only Sled'
    ..brief =
        'A lamp fire at the Chandlery will reach the Sail Loft. Two crates must still go to the Pump House. '
        'There is only one Cargo Sled. Two people also need a walk to Sail Hall.'
    ..tutorial = [
      'One sled. Do not put it on Tomi if you also need him for care.',
      'Kill the fire before it reaches the loft, or the loft caller is lost to the protect rule? No: just contain.',
    ]
    ..strategies = [
      'Sled on Rosa. Extinguisher on Bea. Tomi people-first.',
      'Sled on Bea after she kills the fire, if you accept a later delivery.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.cargoSled, Gear.extinguisher]
    ..decor.addAll(['water:0,0,800,100', 'loft:80,160,180,160']);
  final g = b.start('g', 400, 980, 'Sail Gate', capacity: 3);
  final sq = b.node('sq', 400, 760, 'Sail Square', NodeKind.junction);
  final chand = b.node('chand', 240, 520, 'Chandlery');
  final loft = b.node('loft', 160, 280, 'Sail Loft');
  final depot = b.depot('depot', 560, 760, 'Sail Store', 2);
  final pump = b.need('pump', 680, 400, 'Pump House', 2);
  final hall = b.shelter('hall', 400, 320, 'Sail Hall');
  b
    ..lane(g, sq, 'Sail Road')
    ..lane(sq, chand, 'Chandler Lane')
    ..lane(chand, loft, 'Loft Fire')
    ..lane(sq, depot, 'Store Cut')
    ..lane(depot, 'pump', 'Pump Road')
    ..lane(sq, hall, 'Hall Walk')
    ..lane(loft, hall, 'Loft Hall')
    ..lane('pump', hall, 'Pump Hall')
    ..lane(chand, hall, 'Chandler Hall');
  b.fire(chand);
  b.person(loft);
  b.person(sq, care: true);
  b.hazards.add(
    const HazardEvent(210, HazardType.spread, from: 'chand', to: 'loft'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.delivered, target: pump, count: 2);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Deliver + stabilize / shared depot.
SceneBuilder m025() {
  final b = SceneBuilder('M025', 1, 25)
    ..title = 'One Shelf of Bandages'
    ..brief =
        'The only depot holds three crates for two sites: the Field Tent (2) and a spare for nobody if you waste it. '
        'The tent nurse needs care. Share the shelf; do not empty it on the wrong walk.'
    ..tutorial = [
      'Shared stock: three crates, two required at the tent. A wasted trip still spends stock.',
      'The nurse is at the tent. Care and delivery can happen on the same visit.',
    ]
    ..strategies = [
      'Sled on Rosa, First-Aid on Tomi, both to the tent. Bea clears the inner debris.',
      'One sled run of two crates is enough. The third crate is slack.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.cargoSled, Gear.firstAid]
    ..decor.addAll(['water:0,0,800,90', 'tent:500,140,200,140']);
  final g = b.start('g', 280, 980, 'Camp Gate', capacity: 2);
  final side = b.start('side', 640, 860, 'Side Path');
  final depot = b.depot('depot', 280, 720, 'Bandage Shelf', 3);
  final mid = b.node('mid', 400, 520, 'Camp Mid', NodeKind.junction);
  final tent = b.need('tent', 560, 260, 'Field Tent', 2);
  final hall = b.shelter('hall', 240, 260, 'Camp Hall');
  b
    ..lane(g, depot, 'Gate Shelf')
    ..lane(side, mid, 'Side Mid')
    ..lane(depot, mid, 'Shelf Mid')
    ..lane(mid, 'tent', 'Tent Lane', Block.debris)
    ..lane(mid, hall, 'Hall Lane')
    ..lane('tent', hall, 'Tent Hall');
  final nurse = b.person('tent', care: true, critical: true);
  b.goal(ObjectiveType.delivered, target: tent, count: 2);
  b.goal(ObjectiveType.stabilized, target: nurse);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Inspect + contain / fatigue.
SceneBuilder m026() {
  final b = SceneBuilder('M026', 1, 26)
    ..title = 'Tired Eyes in the Fog'
    ..brief =
        'Fog again, and a drum fire on the hidden Drum Pier. After two jobs everyone rests. '
        'Light the pier, put the fire out, and walk anyone you find to Drum Hall.'
    ..tutorial = [
      'Fatigue plus fog: do not give one person light, fire, and escort.',
      'The fire is on a hidden node. You must find it before you can fight it from an adjacent lit lane.',
    ]
    ..strategies = [
      'Floodlight on Bea, Extinguisher on Rosa, Tomi reserved for escort after rest.',
      'Rosa lights and fights if you accept her rest in the middle.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.floodlight, Gear.extinguisher]
    ..rules = const Rules(fatigueJobs: 2, restTicks: 35)
    ..decor.addAll(['water:0,0,800,220', 'fog:100,240,600,280']);
  final g = b.start('g', 400, 980, 'Drum Gate', capacity: 3);
  final sq = b.node('sq', 400, 740, 'Drum Square', NodeKind.junction);
  final fog = b.node('fog', 240, 460, 'Fog Walk');
  final drum = b.node('drum', 240, 240, 'Drum Pier', NodeKind.pier);
  final hall = b.shelter('hall', 560, 360, 'Drum Hall');
  b
    ..lane(g, sq, 'Drum Road')
    ..lane(sq, fog, 'Fog Mouth', Block.dark)
    ..lane(fog, drum, 'Drum Dark', Block.dark)
    ..lane(sq, hall, 'Hall Road')
    ..lane(drum, hall, 'Pier Hall', Block.dark)
    ..lane(fog, hall, 'Fog Hall');
  b.fire(drum);
  b.person(drum, hidden: true);
  b.person(fog, hidden: true);
  b.goal(ObjectiveType.revealed, nodes: ['sq-fog', 'fog-drum']);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Shelter + inspect / delayed collapse.
SceneBuilder m027() {
  final b = SceneBuilder('M027', 1, 27)
    ..title = 'Door, then the Dark Stair'
    ..brief =
        'Harbor Hall is jammed. Behind the unlit Clock Stair someone is waiting. '
        'Clock Arch is forecast to fall at 32 seconds. Repair the door, light the stair, and get people in.'
    ..tutorial = [
      'Repair first or light first, but do not stand under Clock Arch after the forecast time.',
      'Bea can repair without a Toolkit. The Toolkit is faster for Rosa.',
    ]
    ..strategies = [
      'Toolkit on Rosa at the hall. Floodlight on Bea toward the stair. Tomi escorts.',
      'Bea repairs; Rosa lights; ignore the arch and use the back lane.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.toolkit, Gear.floodlight]
    ..decor.addAll(['water:0,0,800,80', 'clock:300,300,200,160']);
  final g = b.start('g', 200, 980, 'Clock Gate', capacity: 2);
  final back = b.start('back', 680, 900, 'Back Lane');
  final sq = b.node('sq', 320, 740, 'Clock Square', NodeKind.junction);
  final hall = b.shelter('hall', 320, 460, 'Harbor Hall', broken: true);
  final arch = b.node('arch', 500, 460, 'Clock Arch');
  final stair = b.node('stair', 500, 240, 'Clock Stair');
  final loft = b.node('loft', 680, 240, 'Clock Loft');
  b
    ..lane(g, sq, 'Clock Road')
    ..lane(back, loft, 'Back Loft')
    ..lane(sq, hall, 'Hall Door')
    ..lane(sq, arch, 'Arch Walk')
    ..lane(arch, stair, 'Clock Arch')
    ..lane(stair, loft, 'Stair Dark', Block.dark)
    ..lane(hall, stair, 'Hall Stair', Block.dark)
    ..lane(back, arch, 'Back Arch')
    ..lane(loft, hall, 'Loft Hall');
  b.person(loft, hidden: true);
  b.person(sq, care: true);
  b.hazards.add(
    const HazardEvent(
      320,
      HazardType.collapse,
      edge: 'arch-stair',
      note: 'Clock Arch may fall',
    ),
  );
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Fire team vs escort team / changing wind (not a duplicate phrase).
SceneBuilder m028() {
  final b = SceneBuilder('M028', 1, 28)
    ..title = 'Wind Splits the Crew'
    ..brief =
        'One job is the Pitch Fire that the wind will push onto the Boardwalk, then toward Pitch Hall. '
        'The other job is walking two fishers from the far boardwalk. The wind change is the reason you cannot treat this as one pile of work.'
    ..tutorial = [
      'Assign a fire person and an escort person before dispatch. The third covers the leftover debris.',
      'If the boardwalk burns, the fishers cannot walk it.',
    ]
    ..strategies = [
      'Extinguisher on Rosa at Pitch Gate. Tomi and Bea start on the boardwalk side.',
      'Bea holds the fire; Rosa clears; Tomi escorts only.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.extinguisher, Gear.cutter]
    ..decor.addAll(['water:0,0,800,200', 'pitch:80,300,200,180']);
  final pg = b.start('pg', 160, 980, 'Pitch Gate');
  final bg = b.start('bg', 640, 980, 'Boardwalk Gate', capacity: 2);
  final pitch = b.node('pitch', 180, 620, 'Pitch Fire');
  final walk = b.node('walk', 400, 500, 'Boardwalk');
  final far = b.node('far', 640, 360, 'Far Walk', NodeKind.pier);
  final hall = b.shelter('hall', 400, 220, 'Pitch Hall');
  b
    ..lane(pg, pitch, 'Pitch Road')
    ..lane(bg, far, 'Far Road')
    ..lane(pitch, walk, 'Fire Walk')
    ..lane(walk, far, 'Long Walk', Block.debris)
    ..lane(walk, hall, 'Walk Hall')
    ..lane(far, hall, 'Far Hall')
    ..lane(pitch, hall, 'Pitch Hall Lane');
  b.fire(pitch);
  b.person(far);
  b.person(walk);
  b.hazards.addAll([
    const HazardEvent(
      70,
      HazardType.wind,
      note: 'Wind turns onto the Boardwalk',
    ),
    const HazardEvent(180, HazardType.spread, from: 'pitch', to: 'walk'),
    const HazardEvent(280, HazardType.spread, from: 'walk', to: 'hall'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [walk]);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Protect + two calls / limited equipment.
SceneBuilder m029() {
  final b = SceneBuilder('M029', 1, 29)
    ..title = 'One Extinguisher Left'
    ..brief =
        'The last Extinguisher is in the van. The Coil Fire will reach Coil Lane, which must stay clear. '
        'A crate is due at the Coil Pump, and a winder needs care.'
    ..tutorial = [
      'One Extinguisher. Bea cannot put out fire without it. Give it to whoever starts nearest the coil.',
      'Protect Coil Lane. Delivery and care are the other two calls.',
    ]
    ..strategies = [
      'Extinguisher on the west starter. Sled on the east starter. Tomi in the middle.',
      'If the fire dies first, the sled can wait. If not, the lane is lost.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.extinguisher, Gear.cargoSled]
    ..decor.addAll(['water:0,0,800,100', 'coil:80,400,160,160']);
  final w = b.start('w', 120, 960, 'Coil West');
  final m = b.start('m', 400, 960, 'Coil Mid');
  final e = b.start('e', 680, 960, 'Coil East');
  final fireN = b.node('fn', 160, 560, 'Coil Fire');
  final lane = b.node('lane', 400, 560, 'Coil Lane');
  final depot = b.depot('depot', 680, 720, 'Coil Store', 1);
  final pump = b.need('pump', 680, 400, 'Coil Pump', 1);
  final winder = b.node('win', 400, 720, 'Winder');
  final hall = b.shelter('hall', 400, 280, 'Coil Hall');
  b
    ..lane(w, fireN, 'West Fire')
    ..lane(m, winder, 'Mid Winder')
    ..lane(e, depot, 'East Store')
    ..lane(fireN, lane, 'Fire Lane')
    ..lane(winder, lane, 'Winder Lane')
    ..lane(depot, 'pump', 'Pump Cut')
    ..lane('pump', lane, 'Pump Lane')
    ..lane(lane, hall, 'Lane Hall')
    ..lane(fireN, hall, 'Fire Hall', Block.debris)
    ..lane(winder, hall, 'Winder Hall');
  b.fire(fireN);
  b.person(winder, care: true);
  b.hazards.add(
    const HazardEvent(190, HazardType.spread, from: 'fn', to: 'lane'),
  );
  b.goal(ObjectiveType.protect, nodes: [lane]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.delivered, target: pump, count: 1);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Finale: two calls + stabilize / uncertain visibility.
SceneBuilder m030() {
  final b = SceneBuilder('M030', 1, 30)
    ..title = 'Harbor Night Finale'
    ..brief =
        'The district closes on a double call: a hidden pair in the unlit East Vault, and the night clerk at West Desk who needs care. '
        'Light the vault, steady the clerk, and walk everyone to Finale Hall. This is the Harbor finale; there is still no fourth free responder.'
    ..tutorial = [
      'Finale: two places, three people, fog on one side only.',
      'If the vault stays dark, those two callers never appear.',
    ]
    ..strategies = [
      'Floodlight on Bea into the vault. Tomi to the desk. Rosa clears the inner crate if needed.',
      'Rosa lights; Bea clears; Tomi only cares and escorts.',
    ]
    ..teamSize = 3
    ..roles = _trio
    ..gear = [Gear.floodlight, Gear.firstAid, Gear.cutter]
    ..decor.addAll(['water:0,0,800,140', 'vault:480,200,260,220']);
  final west = b.start('west', 160, 980, 'West Desk Gate', capacity: 2);
  final east = b.start('east', 640, 980, 'Vault Gate');
  final desk = b.node('desk', 180, 640, 'West Desk');
  final hub = b.node('hub', 400, 640, 'Night Hub', NodeKind.junction);
  final vault = b.node('vault', 640, 480, 'Vault Door');
  final inner = b.node('inner', 640, 260, 'East Vault');
  final hall = b.shelter('hall', 400, 360, 'Finale Hall');
  b
    ..lane(west, desk, 'Desk Road')
    ..lane(east, vault, 'Vault Road')
    ..lane(desk, hub, 'Desk Hub')
    ..lane(vault, hub, 'Vault Hub')
    ..lane(vault, inner, 'Vault Dark', Block.dark)
    ..lane(hub, hall, 'Hub Hall')
    ..lane(desk, hall, 'Desk Hall')
    ..lane(inner, hall, 'Vault Hall', Block.dark)
    ..lane(east, hall, 'East Bypass', Block.debris);
  final clerk = b.person(desk, care: true, critical: true);
  b.person(inner, hidden: true);
  b.person(vault, hidden: true);
  b.goal(ObjectiveType.stabilized, target: clerk);
  b.goal(ObjectiveType.revealed, nodes: ['vault-inner']);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

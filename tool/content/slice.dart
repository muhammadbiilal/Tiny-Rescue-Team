// Hand-authored vertical slice: Harbor District M001-M010.
// Each scene answers its manifest brief (objective + twist) with an original
// layout. Timings marked "tuned" were set from solver measurements.
import 'package:tiny_rescue_team/simulation/roles.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';

import 'builder.dart';
import 'harbor_w01.dart';

const _duo = [Role.rescuer, Role.medic];

List<SceneBuilder> harborWorld() => [...harborSlice(), ...harborRest()];

List<SceneBuilder> harborSlice() => [
  m001(),
  m002(),
  m003(),
  m004(),
  m005(),
  m006(),
  m007(),
  m008(),
  m009(),
  m010(),
];

/// Brief: evacuate civilians / shared resource. Teaches placement + dispatch.
SceneBuilder m001() {
  final b = SceneBuilder('M001', 1, 1)
    ..title = 'First Shift at the Pier'
    ..brief =
        'Two fishers are waiting at the ends of the piers. Both responders share one shelter, Harbor Hall, '
        'and one narrow boardwalk is covered by a crate spill.'
    ..tutorial = [
      'Drag Rosa and Tomi onto the glowing start zones, or tap a responder then tap a zone.',
      'Press Dispatch. Responders choose their own tasks: you plan, they act.',
      'Only Rosa can clear the Crate Spill. Tomi guides people but cannot move debris.',
    ]
    ..strategies = [
      'Rosa at East Gate clears the Crate Spill while Tomi walks the West Pier.',
      'Both at West Gate: safe, but the East Pier takes the long Salt Path.',
    ]
    ..roles = _duo
    ..decor.addAll([
      'water:0,0,800,250',
      'pier:125,130,90,210',
      'pier:585,130,90,210',
    ]);
  final gw = b.start('gw', 160, 940, 'West Gate', capacity: 2);
  final ge = b.start('ge', 640, 940, 'East Gate', capacity: 2);
  final rope = b.node('rope', 160, 720, 'Rope Walk');
  final cross = b.node('cross', 400, 750, 'Market Cross', NodeKind.junction);
  final net = b.node('net', 640, 720, 'Net Lane');
  final hall = b.shelter('hall', 400, 500, 'Harbor Hall');
  final wp = b.node('wp', 170, 290, 'West Pier', NodeKind.pier);
  final ep = b.node('ep', 630, 290, 'East Pier', NodeKind.pier);
  b
    ..lane(gw, rope, 'West Gate Road')
    ..lane(ge, net, 'East Gate Road')
    ..lane(rope, cross, 'Rope Walk')
    ..lane(cross, net, 'Net Row')
    ..lane(cross, hall, 'Hall Steps')
    ..lane(rope, wp, 'West Boardwalk')
    ..lane(net, ep, 'East Boardwalk', Block.debris)
    ..lane(wp, hall, 'Pier Path')
    ..lane(hall, ep, 'Salt Path');
  b.person(wp);
  b.person(ep);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Brief: stabilize and transport / responder fatigue.
SceneBuilder m002() {
  final b = SceneBuilder('M002', 1, 2)
    ..title = 'Steady Hands'
    ..brief =
        'A boat builder and a stall keeper both need care before they can walk to Harbor Hall. '
        'Long shifts are tiring: every responder takes a breather after two tasks.'
    ..tutorial = [
      'People marked with a care cross must be steadied by Tomi before anyone can guide them.',
      'Fatigue: after two finished tasks a responder rests for four seconds. Plan who does what.',
      'Give Rosa "People first" priority if you want her waiting to escort.',
    ]
    ..strategies = [
      'Tomi starts at Crane Yard, next to the Boat Shed; Rosa at Dock Gate clears the Net Tangle.',
      'Both at Dock Gate: Rosa escorts while Tomi rests between calls.',
    ]
    ..roles = _duo
    ..rules = const Rules(fatigueJobs: 2, restTicks: 40)
    ..decor.addAll(['water:0,0,800,190', 'pier:560,90,120,160']);
  final g1 = b.start('g1', 420, 960, 'Dock Gate', capacity: 2);
  final g2 = b.start('g2', 120, 820, 'Crane Yard');
  final yard = b.node('yard', 420, 780, 'Fish Yard', NodeKind.junction);
  final shed = b.node('shed', 130, 560, 'Boat Shed');
  final stall = b.node('stall', 660, 610, 'Fish Stall');
  final hall = b.shelter('hall', 420, 400, 'Harbor Hall');
  final slip = b.node('slip', 640, 250, 'Slipway', NodeKind.pier);
  final tide = b.node('tide', 150, 260, 'Tide Steps');
  b
    ..lane(g1, yard, 'Dock Road')
    ..lane(g2, shed, 'Crane Path')
    ..lane(g2, yard, 'Yard Fence')
    ..lane(yard, stall, 'Stall Row')
    ..lane(stall, hall, 'Market Stair')
    ..lane(shed, hall, 'Shed Path', Block.debris)
    ..lane(shed, tide, 'Old Seawall')
    ..lane(tide, hall, 'Tide Walk')
    ..lane(hall, slip, 'Slip Road')
    ..lane(slip, stall, 'Quay Walk');
  final c1 = b.person(shed, care: true, critical: true);
  b.person(slip, care: true);
  b.goal(ObjectiveType.stabilized, target: c1);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Brief: open a safe route / delayed hazard. Teaches the first ability.
SceneBuilder m003() {
  final b = SceneBuilder('M003', 1, 3)
    ..title = 'Crane Road'
    ..brief =
        'The ferry needs a clear road from the Dock Gate to the Ferry Terminal. Every way is blocked, and the '
        'old Customs Arch is expected to shed stones at about 18 seconds.'
    ..tutorial = [
      'The forecast shows when the Customs Arch sheds debris. Beat it, or plan another road.',
      'New: Rosa\'s Rapid Access. During the mission tap her ability, then tap a debris lane near her.',
      'New gear: the Cutter clears debris faster. You have one.',
    ]
    ..strategies = [
      'Rosa with the Cutter goes west and clears the Fallen Crane Arm before the arch sheds.',
      'Use Rapid Access on Tipped Containers to open the east road through Bollard Walk.',
    ]
    ..roles = _duo
    ..gear = [Gear.cutter]
    ..decor.addAll(['water:0,0,800,120', 'yard:260,420,280,300']);
  final gate = b.start('gate', 400, 960, 'Dock Gate', capacity: 2);
  final hoist = b.start('hoist', 680, 880, 'East Hoist');
  final base = b.node('base', 400, 790, 'Crane Base', NodeKind.junction);
  final row = b.node('row', 400, 590, 'Container Row');
  final end = b.node('end', 400, 390, 'Crane Road End');
  final term = b.node('term', 400, 190, 'Ferry Terminal', NodeKind.pier);
  final tar = b.node('tar', 150, 650, 'Tar Lane');
  final customs = b.node('customs', 150, 360, 'Old Customs');
  final bollard = b.node('bollard', 660, 620, 'Bollard Walk');
  final tally = b.node('tally', 650, 360, 'Tally House');
  b
    ..lane(gate, base, 'Gate Road')
    ..lane(base, row, 'Tipped Containers', Block.debris)
    ..lane(row, end, 'Loose Pallets', Block.debris)
    ..lane(end, term, 'Terminal Ramp')
    ..lane(base, tar, 'Tar Cut', Block.debris)
    ..lane(tar, customs, 'Fallen Crane Arm', Block.debris)
    ..lane(customs, term, 'Customs Arch')
    ..lane(hoist, bollard, 'Hoist Lane')
    ..lane(row, bollard, 'Bollard Link')
    ..lane(bollard, tally, 'Tally Walk', Block.debris)
    ..lane(tally, term, 'Tally Quay');
  b.hazards.add(
    const HazardEvent(
      180,
      HazardType.collapse,
      edge: 'customs-term',
      note: 'Customs Arch sheds stones',
    ),
  );
  b.goal(ObjectiveType.routeOpen, a: gate, b: term);
  return b;
}

/// Brief: contain a spreading hazard / changing wind.
SceneBuilder m004() {
  final b = SceneBuilder('M004', 1, 4)
    ..title = 'Net Loft Smolder'
    ..brief =
        'A small fire smolders in the Net Loft. The wind will turn toward the Rope Store, where a sail maker is '
        'still packing, then toward the Fish Market. One Extinguisher is on the truck.'
    ..tutorial = [
      'Fire spreads only at the forecast times, and only if the source is still burning.',
      'Whoever carries the Extinguisher can put out small (level 1) fires.',
      'A responder with an Extinguisher standing where fire would spread holds it back.',
    ]
    ..strategies = [
      'Extinguisher on Rosa at West Gate: she reaches the loft first; Tomi escorts the sail maker.',
      'Extinguisher on Tomi at Harbor Office, Rosa escorts: tighter, but it works.',
    ]
    ..roles = _duo
    ..gear = [Gear.extinguisher]
    ..decor.addAll(['water:0,0,800,90', 'plaza:320,640,160,120']);
  final g1 = b.start('g1', 170, 950, 'West Gate');
  final g2 = b.start('g2', 630, 950, 'East Gate');
  final g3 = b.start('g3', 400, 960, 'Harbor Office');
  final tar = b.node('tar', 170, 700, 'Tar Yard');
  final sq = b.node('sq', 400, 700, 'Harbor Square', NodeKind.junction);
  final ice = b.node('ice', 630, 700, 'Ice House');
  final loft = b.node('loft', 170, 420, 'Net Loft');
  final rope = b.node('rope', 400, 330, 'Rope Store');
  final market = b.node('market', 630, 420, 'Fish Market');
  final hall = b.shelter('hall', 620, 180, 'Harbor Hall');
  b
    ..lane(g1, tar, 'Tar Road')
    ..lane(g3, sq, 'Office Steps')
    ..lane(g2, ice, 'Ice Road')
    ..lane(tar, sq, 'Barrel Row')
    ..lane(sq, ice, 'Square East')
    ..lane(tar, loft, 'Loft Stair')
    ..lane(sq, rope, 'Rope Lane')
    ..lane(ice, market, 'Market Road')
    ..lane(loft, rope, 'Sail Alley')
    ..lane(rope, market, 'Market Arcade')
    ..lane(market, hall, 'Hall Quay')
    ..lane(rope, hall, 'Upper Rope Lane');
  b.fire(loft);
  b.person(rope);
  b.hazards.addAll(const [
    HazardEvent(
      120,
      HazardType.wind,
      note: 'Wind turns east, toward the Rope Store',
    ),
    HazardEvent(150, HazardType.spread, from: 'loft', to: 'rope'),
    HazardEvent(300, HazardType.spread, from: 'rope', to: 'market'),
  ]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.protect, nodes: [market]);
  b.goal(ObjectiveType.civiliansSafe, count: 1);
  return b;
}

/// Brief: deliver essential supplies / limited equipment.
SceneBuilder m005() {
  final b = SceneBuilder('M005', 1, 5)
    ..title = 'Cold Store Run'
    ..brief =
        'The Harbor Clinic needs three crates of supplies from the Cold Store before the ferry leaves at 54 seconds. '
        'There is one Cargo Sled, and Lantern Arch may shed debris at about 25 seconds.'
    ..tutorial = [
      'Rosa carries one crate. The Cargo Sled lets anyone carry one more.',
      'Deadline: the clinic objective shows its time limit. Plan trips before you dispatch.',
    ]
    ..strategies = [
      'Sled on Rosa: two trips instead of three.',
      'Sled on Tomi so both carry: two runners, one crate each per trip.',
    ]
    ..roles = _duo
    ..gear = [Gear.cargoSled]
    ..decor.addAll(['water:0,0,800,110', 'yard:40,470,240,180']);
  final g1 = b.start('g1', 150, 950, 'Dock Gate', capacity: 2);
  final g2 = b.start('g2', 650, 950, 'Ice Wharf');
  final x = b.node('x', 400, 760, "Chandler's Cross", NodeKind.junction);
  final store = b.depot('store', 150, 560, 'Cold Store', 4);
  final mid = b.node('mid', 400, 440, 'Lantern Row');
  final east = b.node('east', 650, 640, 'Bait Street');
  final clinic = b.need('clinic', 640, 280, 'Harbor Clinic', 3);
  final steps = b.node('steps', 160, 250, 'Tide Steps');
  b
    ..lane(g1, x, 'Dock Road')
    ..lane(g2, east, 'Wharf Road')
    ..lane(x, store, 'Store Lane')
    ..lane(x, mid, 'Lantern Walk')
    ..lane(x, east, 'Bait Cross')
    ..lane(store, mid, 'Barrel Lane', Block.debris)
    ..lane(mid, 'clinic', 'Lantern Arch')
    ..lane(east, 'clinic', 'Bait Hill')
    ..lane(store, steps, 'Sea Steps')
    ..lane(steps, 'clinic', 'Sea Wall');
  b.hazards.add(
    const HazardEvent(
      250,
      HazardType.collapse,
      edge: 'mid-clinic',
      note: 'Lantern Arch sheds debris',
    ),
  );
  b.goal(ObjectiveType.delivered, target: clinic, count: 3, by: 540); // tuned
  return b;
}

/// Brief: inspect and then respond / uncertain visibility.
SceneBuilder m006() {
  final b = SceneBuilder('M006', 1, 6)
    ..title = 'Fog on the Quay'
    ..brief =
        'Sea fog has rolled over the quay. Someone is at the Boat Ramp, and callers say more people may be out '
        'in the fog. Unlit lanes must be lit before anyone can use them.'
    ..tutorial = [
      'Dark lanes hide what is beyond them. The Floodlight lets its carrier light an adjacent dark lane.',
      'People in the fog appear once a lane next to them is lit or a responder gets close.',
    ]
    ..strategies = [
      'Floodlight on Tomi toward the Foggy Boardwalk while Rosa handles the Boat Ramp.',
      'Floodlight on Rosa: she lights and guides, Tomi takes the Harbor Light side.',
    ]
    ..roles = _duo
    ..gear = [Gear.floodlight]
    ..decor.addAll(['water:0,0,800,150', 'fog:60,180,700,360']);
  final g1 = b.start('g1', 400, 960, 'Quay Gate', capacity: 2);
  final g2 = b.start('g2', 130, 880, 'Net Sheds');
  final sq = b.node('sq', 400, 760, 'Quay Square', NodeKind.junction);
  final hall = b.shelter('hall', 400, 560, "Seafarers' Hall");
  final lq = b.node('lq', 160, 560, 'Lower Quay');
  final bait = b.node('bait', 160, 290, 'Bait Shop');
  final ramp = b.node('ramp', 400, 300, 'Boat Ramp', NodeKind.pier);
  final fog = b.node('fog', 650, 420, 'Fog Bank Pier', NodeKind.pier);
  final light = b.node('light', 650, 700, 'Harbor Light', NodeKind.lookout);
  b
    ..lane(g1, sq, 'Gate Walk')
    ..lane(g2, lq, 'Shed Path')
    ..lane(sq, hall, 'Hall Walk')
    ..lane(sq, lq, 'Quay Row')
    ..lane(sq, light, 'Light Road')
    ..lane(hall, ramp, 'Ramp Lane')
    ..lane(lq, bait, 'Foggy Boardwalk', Block.dark)
    ..lane(ramp, bait, 'Mist Lane', Block.dark)
    ..lane(hall, fog, 'Grey Jetty', Block.dark)
    ..lane(light, fog, 'Light Pier')
    ..lane(ramp, fog, 'Ramp Jetty', Block.dark);
  b.person(ramp);
  b.person(bait, hidden: true);
  b.person(fog, hidden: true);
  b.goal(ObjectiveType.civiliansSafe, count: 3);
  return b;
}

/// Brief: restore access to a shelter / split start positions.
SceneBuilder m007() {
  final b = SceneBuilder('M007', 1, 7)
    ..title = 'Harbor Hall Door'
    ..brief =
        "Harbor Hall's storm door is jammed, and the Sailors' Chapel opens only at 30 seconds. Crews are spread "
        'across the harbor, one per start zone. A Toolkit can get the door working.'
    ..tutorial = [
      'Split starts: each start zone holds one responder.',
      'A damaged shelter accepts nobody until it is repaired. The Toolkit lets its carrier repair slowly.',
    ]
    ..strategies = [
      'Toolkit on Rosa at Clock Corner, next to the hall; Tomi starts near the café.',
      'Ignore the door at first and walk people to the chapel, then repair.',
    ]
    ..roles = _duo
    ..gear = [Gear.toolkit]
    ..decor.addAll(['water:0,0,800,100', 'plaza:330,300,140,120']);
  final z1 = b.start('z1', 120, 940, 'Net Sheds');
  final z2 = b.start('z2', 680, 940, 'Boat Hoist');
  final z3 = b.start('z3', 400, 640, 'Clock Corner');
  final low = b.node('low', 400, 860, 'Low Street', NodeKind.junction);
  final hall = b.shelter('hall', 400, 400, 'Harbor Hall', broken: true);
  final chapel = b.shelter('chapel', 680, 160, "Sailors' Chapel", openAt: 300);
  final loft = b.node('loft', 130, 500, 'Rope Loft');
  final cafe = b.node('cafe', 680, 560, 'Pier Café');
  final up = b.node('up', 150, 200, 'Upper Quay');
  b
    ..lane(z1, low, 'Shed Lane')
    ..lane(z2, low, 'Hoist Lane')
    ..lane(low, z3, 'Clock Street')
    ..lane(z1, loft, 'Loft Steps')
    ..lane(z2, cafe, 'Café Walk')
    ..lane(z3, hall, 'Hall Approach')
    ..lane(loft, hall, 'Rope Alley')
    ..lane(cafe, hall, 'Market Alley')
    ..lane(cafe, chapel, 'Chapel Hill')
    ..lane(loft, up, 'West Stair')
    ..lane(up, chapel, 'Chapel Walk', Block.debris)
    ..lane(hall, up, 'Hall Terrace');
  b.person(loft);
  b.person(cafe, care: true);
  b.goal(ObjectiveType.shelterOpen, target: hall);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Brief: coordinate two dependent teams / two viable routes.
SceneBuilder m008() {
  final b = SceneBuilder('M008', 1, 8)
    ..title = 'Lighthouse Point'
    ..brief =
        "The lighthouse keeper needs care before 25 seconds. The Keeper's Cottage is on the same point. "
        'The north road is short but blocked twice; the south road is longer and the Seawall Bend may slip.'
    ..tutorial = [
      'Deadline: the keeper needs care before 25 seconds. Whoever brings care must get there; the other can open the way.',
      'Two routes lead to the point. The forecast shows when the south road may close.',
    ]
    ..strategies = [
      'Rosa clears the north road with the Cutter while Tomi waits one lane behind her.',
      'Tomi takes the south road early before the Seawall Bend slips; Rosa follows for the cottage.',
    ]
    ..roles = _duo
    ..gear = [Gear.cutter, Gear.firstAid]
    ..decor.addAll([
      'water:0,0,260,1040',
      'water:0,0,800,120',
      'rocks:120,120,200,220',
    ]);
  final g1 = b.start('g1', 420, 960, 'Harbor Gate', capacity: 2);
  final g2 = b.start('g2', 700, 900, 'Lifeboat House');
  final fork = b.node('fork', 450, 780, 'Tar Fork', NodeKind.junction);
  final n1 = b.node('n1', 430, 560, 'Gull Lane');
  final n2 = b.node('n2', 400, 360, 'Cliff Steps');
  final light = b.node('light', 330, 190, 'Lighthouse', NodeKind.lookout);
  final cottage = b.node('cottage', 560, 220, "Keeper's Cottage");
  final s1 = b.node('s1', 700, 640, 'Seawall');
  final s2 = b.node('s2', 700, 400, 'Seawall Bend');
  final hall = b.shelter('hall', 620, 800, 'Lifeboat Hall');
  b
    ..lane(g1, fork, 'Gate Road')
    ..lane(g2, hall, 'Boat Ramp')
    ..lane(fork, hall, 'Hall Lane')
    ..lane(fork, n1, 'Net Tangle', Block.debris)
    ..lane(n1, n2, 'Gull Steps')
    ..lane(n2, light, 'Rockfall Path', Block.debris)
    ..lane(n2, cottage, 'Cottage Lane')
    ..lane(light, cottage, 'Point Path')
    ..lane(hall, s1, 'Seawall Road')
    ..lane(s1, s2, 'Seawall Bend')
    ..lane(s2, cottage, 'Cottage Hill')
    ..lane(n1, s1, 'Gull Cut');
  final keeper = b.person(light, care: true, critical: true);
  b.person(cottage);
  b.hazards.add(
    const HazardEvent(
      220,
      HazardType.collapse,
      edge: 's1-s2',
      note: 'Seawall Bend may slip',
    ),
  );
  b.goal(ObjectiveType.stabilized, target: keeper, by: 250); // tuned
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  return b;
}

/// Brief: protect a critical corridor / blocked junction.
SceneBuilder m009() {
  final b = SceneBuilder('M009', 1, 9)
    ..title = 'Keep the Ferry Lane Clear'
    ..brief =
        'Ferry Lane is the only way the evening ferry can load. A fire in the Paint Shed will spread onto the lane '
        'at about 24 seconds, and Five Ways junction is choked with debris.'
    ..tutorial = [
      'Protect: if fire ever reaches Ferry Lane, the mission fails.',
      'You also need an open road from the Market Gate to the Ferry Slip at the end.',
    ]
    ..strategies = [
      'Extinguisher on the responder starting at Sail Yard, who reaches the Paint Shed first.',
      'Stand the Extinguisher carrier on Ferry Lane to hold the fire, then clear Five Ways.',
    ]
    ..roles = _duo
    ..gear = [Gear.extinguisher, Gear.cutter]
    ..decor.addAll(['water:0,0,800,140', 'water:680,0,120,1040']);
  final gate = b.start('gate', 380, 960, 'Market Gate', capacity: 2);
  final sail = b.start('sail', 120, 700, 'Sail Yard');
  final five = b.node('five', 380, 720, 'Five Ways', NodeKind.junction);
  final shed = b.node('shed', 150, 420, 'Paint Shed');
  final lane = b.node('lane', 380, 430, 'Ferry Lane');
  final slip = b.node('slip', 380, 200, 'Ferry Slip', NodeKind.pier);
  final kiosk = b.node('kiosk', 600, 600, 'Ticket Kiosk');
  final wall = b.node('wall', 600, 300, 'Harbor Wall');
  b
    ..lane(gate, five, 'Market Road')
    ..lane(sail, five, 'Sail Cut', Block.debris)
    ..lane(five, lane, 'Five Ways North', Block.debris)
    ..lane(five, kiosk, 'Kiosk Row')
    ..lane(shed, lane, 'Paint Alley')
    ..lane(lane, slip, 'Ferry Lane')
    ..lane(kiosk, wall, 'Wall Walk')
    ..lane(wall, slip, 'Slip Steps', Block.debris)
    ..lane(shed, slip, 'Shed Pier');
  b.fire(shed);
  b.hazards.add(
    const HazardEvent(240, HazardType.spread, from: 'shed', to: 'lane'),
  );
  b.goal(ObjectiveType.protect, nodes: [lane]);
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.routeOpen, a: gate, b: slip);
  return b;
}

/// Brief: resolve simultaneous calls / branching access. Slice capstone.
SceneBuilder m010() {
  final b = SceneBuilder('M010', 1, 10)
    ..title = 'Busy Morning'
    ..brief =
        'Three calls at once from three branches of the harbor: a small fire in the Boat Yard beside the Chandlery, '
        'a tea house owner who needs care, and a pump house that needs two crates. Only two responders are free.'
    ..tutorial = [
      'Three gear items, two hands: each responder carries one item. Choose which calls get gear.',
      'Priorities decide who goes where first. Set them before dispatch.',
    ]
    ..strategies = [
      'Rosa with the Extinguisher on "Hazards first", Tomi on "People first" steadies the owner, then crates.',
      'Tomi with the Extinguisher; Rosa handles crates and escorts.',
    ]
    ..roles = _duo
    ..gear = [Gear.extinguisher, Gear.cargoSled, Gear.firstAid]
    ..decor.addAll([
      'water:0,0,800,120',
      'yard:560,160,200,220',
      'plaza:330,560,140,140',
    ]);
  final hub = b.start('hub', 400, 640, 'Harbor Office', capacity: 2);
  final south = b.start('south', 400, 960, 'South Gate');
  final depot = b.depot('depot', 400, 820, 'Supply Hut', 3);
  final yardJ = b.node('yj', 620, 520, 'Yard Gate');
  final boat = b.node('boat', 660, 300, 'Boat Yard');
  final chand = b.node('chand', 480, 250, 'Chandlery');
  final tea = b.node('tea', 140, 360, 'Tea House');
  final teaJ = b.node('tj', 170, 600, 'Willow Lane');
  final hall = b.shelter('hall', 400, 420, 'Harbor Hall');
  final pumpJ = b.node('pj', 660, 820, 'Pump Road');
  final pump = b.need('pump', 680, 960, 'Pump House', 2);
  b
    ..lane(hub, depot, 'Office Steps')
    ..lane(south, depot, 'South Road')
    ..lane(hub, yardJ, 'Yard Road')
    ..lane(yardJ, boat, 'Slip Lane')
    ..lane(boat, chand, 'Chandlers Row')
    ..lane(chand, hall, 'Rope Stair')
    ..lane(hub, hall, 'Hall Walk')
    ..lane(hub, teaJ, 'Willow Walk')
    ..lane(teaJ, tea, 'Tea Garden Path', Block.debris)
    ..lane(tea, hall, 'Garden Terrace')
    ..lane(depot, pumpJ, 'Pump Lane')
    ..lane(pumpJ, 'pump', 'Pump Yard');
  b.fire(boat);
  b.person(chand);
  b.person(tea, care: true);
  b.hazards.add(
    const HazardEvent(260, HazardType.spread, from: 'boat', to: 'chand'),
  );
  b.goal(ObjectiveType.contained);
  b.goal(ObjectiveType.civiliansSafe, count: 2);
  b.goal(ObjectiveType.delivered, target: pump, count: 2);
  return b;
}

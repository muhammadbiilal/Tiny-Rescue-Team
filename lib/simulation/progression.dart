/// What a free player owns at each point of the campaign. Nothing here can
/// be bought: responders join by district, gear by mission milestones.
library;

import 'roles.dart';

int missionNumber(String id) => int.parse(id.substring(1));

/// Campaign world (1-13) for a mission number.
int worldOf(int number) => number > 360 ? 13 : (number - 1) ~/ 30 + 1;

List<Role> rolesUnlockedAt(int missionNo) => [
  for (final r in Role.values)
    if (r.def.unlockMission <= missionNo) r,
];

/// Mission number whose first completion awards each gear item.
/// The item is usable from the mission after, and in the award mission itself.
const Map<Gear, int> gearUnlockMission = {
  Gear.cutter: 3,
  Gear.extinguisher: 4,
  Gear.cargoSled: 5,
  Gear.floodlight: 6,
  Gear.toolkit: 7,
  Gear.firstAid: 8,
  Gear.spreader: 151,
  Gear.radio: 211,
};

List<Gear> gearUnlockedAt(int missionNo) => [
  for (final g in Gear.values)
    if (gearUnlockMission[g]! <= missionNo) g,
];

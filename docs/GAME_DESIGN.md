# Tiny Rescue Team — Game Design v2

## Fantasy and loop
The player runs a fictional rescue team across a colorful city. Each 2–4 minute mission: read a clear objective and hazard forecast → choose 2–4 responders and equipment → place them in valid deployment zones and set priorities → press Dispatch → watch autonomous responders execute deterministic behavior → optionally trigger 1–2 available tactical abilities at meaningful moments → see outcome, replay, upgrade, select next mission. There is no combat, enemy or real-world emergency instruction. Characters and readable animation are central, not decorative board tokens.

## Core interaction
Pre-mission planning is the main skill. Positions affect reach, speed, safe routes and ability synergy. During action, player can pause/slow, inspect, redirect a unit once when allowed, and trigger a limited tactical ability. AI policy is explicit and predictable: priorities, capability compatibility, path cost, capacity and hazard forecast. Failed missions explain the unmet dependency. No hidden unfair randomness, forced waiting, lives or ad-based retries.

## Encounter simulation
Phases: deploy → observation → enable access → stabilize/contain → transport/evacuate → verify safe completion. Actions have time, capability, equipment, resource and access prerequisites. Responders occupy lanes, share vehicle/equipment capacity, and react to scheduled hazard states. The engine advances in fixed simulation ticks. An action event log explains causes and outcomes; visuals interpolate, not drive logic. Missions can be completed using multiple viable team setups. One scripted cutscene cannot count as a mission.

## Win/fail and scoring
Mission objectives are explicit predicates such as `civilians_safe >= N`, `route_open`, `hazard_contained`, `critical_civilian_stabilized`, with deadline only when tutorialed. Fail when an objective becomes unreachable; immediate retry with no energy cost. Completion unlocks next mission. Optional 1–3 stars depend on transparent, achievable criteria; upgrades are earned from play, not required purchases. No score represents a person's worth or real emergency outcomes.

## Year-scale content
12 districts × 30 missions plus 5 finale missions. Campaign is 365 missions, playable at any pace and offline. World 1 teaches two responders; later worlds unlock a new unit and mechanic, with recurring older skills. Every fifth mission adds a distinct tactical constraint; every thirtieth is a district finale. Build an original city narrative told by short illustrated briefs and results; no claim of realistic operational simulation.

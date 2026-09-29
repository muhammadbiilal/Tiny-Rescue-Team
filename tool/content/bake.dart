import 'package:tiny_rescue_team/simulation/scene.dart';
import 'package:tiny_rescue_team/simulation/solver.dart';

MissionScene bake(MissionScene raw) {
  final r = solve(raw);
  final best = r.bestTicks;
  final median = r.medianWinTicks;
  final gold = best;
  var par = median;
  if (par < gold) par = gold;
  if (par == gold && gold > 0) par = (gold * 12) ~/ 10;
  return raw.copyWith(
    parTicks: par,
    goldTicks: gold,
    witness: r.best,
    review: Review(
      authoring: raw.review.authoring,
      solver: r.best == null ? 'unsolved' : 'solver_validated',
      setupsTried: r.tried,
      setupsWon: r.won,
      difficulty: r.difficulty,
      editorial: r.best == null ? 'pending' : 'approved_slice',
      human: 'not_played',
    ),
  );
}

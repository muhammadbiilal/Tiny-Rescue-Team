// ignore_for_file: avoid_print
// Prints solver measurements for hand-authored slice missions.
//   dart run tool/slice_report.dart [M004] [--log]
import 'package:tiny_rescue_team/simulation/describe.dart';
import 'package:tiny_rescue_team/simulation/run.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';
import 'package:tiny_rescue_team/simulation/solver.dart';
import 'package:tiny_rescue_team/simulation/validator.dart';

import 'content/slice.dart';

void printLog(MissionScene s, List<UnitSetup> team, List<Command> cmds) {
  final run = runMission(s, team, commands: cmds);
  for (final e in run.events) {
    final t = describe(e, s, team);
    if (t != null)
      print('   ${(e.tick / 10).toStringAsFixed(1).padLeft(5)}s  $t');
  }
  if (!run.won) print('   hints: ${run.hints}');
}

void main(List<String> args) {
  final only = args.where((a) => a.startsWith('M')).toSet();
  final log = args.contains('--log');
  for (final b in harborSlice()) {
    if (only.isNotEmpty && !only.contains(b.id)) continue;
    final s = b.build();
    for (final i in staticCheck(s)) {
      print('  $i');
    }
    final sw = Stopwatch()..start();
    final r = solve(s);
    print(
      '${s.id} tried=${r.tried} won=${r.won} rate=${(r.winRate * 100).toStringAsFixed(0)}% '
      'best=${r.bestTicks} median=${r.medianWinTicks} teams=${r.winningTeams} '
      'focus=${r.needsFocus} ability=${r.needsAbility} ${r.difficulty} (${sw.elapsedMilliseconds} ms)',
    );
    final w = r.best;
    if (w == null) {
      final team = [
        for (var i = 0; i < s.teamSize && i < s.allowedRoles.length; i++)
          UnitSetup(s.allowedRoles[i], s.deploy[i % s.deploy.length].node),
      ];
      print('  no witness; sample run:');
      printLog(s, team, const []);
      continue;
    }
    print(
      '  witness: ${w.loadout.map((u) => '${u.role.name}@${u.node}${u.gear == null ? '' : '+${u.gear!.name}'}').join(', ')} '
      'cmds=${w.commands.map((c) => c.toJson()).toList()}',
    );
    if (log) printLog(s, w.loadout, w.commands);
    if (args.contains('--fails')) {
      for (final f in r.failures.take(1)) {
        print(
          '  FAIL setup: ${f.map((u) => '${u.role.name}@${u.node}${u.gear == null ? '' : '+${u.gear!.name}'}').join(', ')}',
        );
        printLog(s, f, const []);
      }
    }
  }
}

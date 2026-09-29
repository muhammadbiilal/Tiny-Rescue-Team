import 'package:flutter_test/flutter_test.dart';
import 'package:tiny_rescue_team/simulation/run.dart';
import 'package:tiny_rescue_team/simulation/scene.dart';
import 'package:tiny_rescue_team/simulation/validator.dart';

import '../tool/content/bake.dart';
import '../tool/content/campaign.dart';
import '../tool/content/slice.dart';

void main() {
  test(
    'Harbor M001-M030 each have a free-player witness',
    () {
      final scenes = [for (final b in harborWorld()) bake(b.build())];
      expect(scenes.length, 30);
      for (final s in scenes) {
        final static = staticCheck(s).where((i) => i.error);
        expect(static, isEmpty, reason: '${s.id} ${static.join('; ')}');
        final witness = verifyWitness(s);
        expect(
          witness.where((i) => i.error),
          isEmpty,
          reason: '${s.id} ${witness.join('; ')}',
        );
        expect(s.review.solver, 'solver_validated');
      }
      final dups = duplicateCheck(scenes).where((i) => i.error);
      expect(dups, isEmpty, reason: dups.join('; '));
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );

  test(
    'Old Town M031-M060 each have a free-player witness',
    () {
      final scenes = [
        for (final b in authoredCampaign())
          if (b.world == 2) bake(b.build()),
      ];
      expect(scenes.length, 30);
      for (final s in scenes) {
        final static = staticCheck(s).where((i) => i.error);
        expect(static, isEmpty, reason: '${s.id} ${static.join('; ')}');
        final witness = verifyWitness(s);
        expect(
          witness.where((i) => i.error),
          isEmpty,
          reason: '${s.id} ${witness.join('; ')}',
        );
        expect(s.review.solver, 'solver_validated');
      }
      final all = [for (final b in authoredCampaign()) b.build()];
      final dups = duplicateCheck(all).where((i) => i.error);
      expect(dups, isEmpty, reason: dups.join('; '));
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );

  test('default Harbor pair is a valid loadout on M001', () {
    final s = harborSlice().first.build();
    final team = [
      for (var i = 0; i < s.teamSize; i++)
        UnitSetup(s.allowedRoles[i], s.deploy[i % s.deploy.length].node),
    ];
    expect(validateLoadout(s, team), isNull);
  });
}

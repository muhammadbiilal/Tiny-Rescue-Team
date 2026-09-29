// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:tiny_rescue_team/simulation/scene.dart';
import 'package:tiny_rescue_team/simulation/validator.dart';

void main() {
  final briefs = File('docs/MISSIONS_001_365.json');
  if (!briefs.existsSync()) {
    print('ERROR missing docs/MISSIONS_001_365.json');
    exit(1);
  }
  final manifest =
      jsonDecode(briefs.readAsStringSync()) as Map<String, Object?>;
  final rows = (manifest['missions'] as List).cast<Map>();
  final briefIds = {for (final r in rows) r['id'] as String};
  var errors = 0;
  var warnings = 0;
  void hit(Issue i) {
    print(i);
    if (i.error) {
      errors++;
    } else {
      warnings++;
    }
  }

  if (briefIds.length != 365) {
    print('ERROR manifest has ${briefIds.length} rows, expected 365');
    errors++;
  }
  for (var i = 1; i <= 365; i++) {
    final id = 'M${i.toString().padLeft(3, '0')}';
    if (!briefIds.contains(id)) {
      print('ERROR missing brief $id');
      errors++;
    }
  }

  final dir = Directory('assets/missions');
  final scenes = <MissionScene>[];
  if (dir.existsSync()) {
    for (final f in dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json'),
    )) {
      try {
        scenes.add(
          MissionScene.fromJson(
            (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>(),
          ),
        );
      } catch (e) {
        print('ERROR ${f.path}: $e');
        errors++;
      }
    }
  }
  scenes.sort((a, b) => a.id.compareTo(b.id));
  for (final s in scenes) {
    for (final i in staticCheck(s)) {
      hit(i);
    }
    for (final i in verifyWitness(s)) {
      hit(i);
    }
  }
  for (final i in duplicateCheck(scenes)) {
    hit(i);
  }

  final authored = scenes.length;
  final validated = scenes
      .where((s) => s.review.solver == 'solver_validated' && s.witness != null)
      .length;
  print(
    'briefs=365 authored=$authored solver_validated=$validated warnings=$warnings errors=$errors',
  );
  if (errors > 0) exitCode = 1;
}

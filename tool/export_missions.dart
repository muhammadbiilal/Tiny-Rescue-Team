// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'content/bake.dart';
import 'content/slice.dart';

void main() {
  final dir = Directory('assets/missions')..createSync(recursive: true);
  var ok = 0;
  for (final b in harborWorld()) {
    final baked = bake(b.build());
    File('${dir.path}/${baked.id}.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(baked.toJson()),
    );
    print(
      '${baked.id} solver=${baked.review.solver} ticks=${baked.witness?.ticks} '
      'par=${baked.parTicks} gold=${baked.goldTicks} ${baked.review.difficulty}',
    );
    if (baked.witness != null) ok++;
  }
  print('exported $ok/${harborWorld().length}');
  if (ok != harborWorld().length) exitCode = 1;
}

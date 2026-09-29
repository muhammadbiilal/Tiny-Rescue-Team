import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../simulation/progression.dart';
import '../simulation/scene.dart';

class WorldInfo {
  final int number;
  final String name;
  final String theme;
  final Color color;
  const WorldInfo(this.number, this.name, this.theme, this.color);
}

/// Original district names from the v2 brief. Colors are unique to this game.
const List<WorldInfo> worlds = [
  WorldInfo(
    1,
    'Harbor District',
    'Piers, shared halls, and simple extraction.',
    Color(0xFF1D6A7A),
  ),
  WorldInfo(
    2,
    'Old Town',
    'Narrow lanes and smoke in the eaves.',
    Color(0xFF8B5A2B),
  ),
  WorldInfo(3, 'Riverside', 'Rising water and boat access.', Color(0xFF2E6B9E)),
  WorldInfo(
    4,
    'Industrial Zone',
    'Power, machinery, and locked yards.',
    Color(0xFF5C5F6B),
  ),
  WorldInfo(
    5,
    'Pine Ridge',
    'Spreading fire and shifting wind.',
    Color(0xFFB4532A),
  ),
  WorldInfo(
    6,
    'Hill Settlement',
    'Unstable paths and landslides.',
    Color(0xFF6B7D3A),
  ),
  WorldInfo(
    7,
    'Coastal Quarter',
    'Storm surge and long evacuations.',
    Color(0xFF0E7490),
  ),
  WorldInfo(
    8,
    'Transit Hub',
    'Crowded corridors and bottlenecks.',
    Color(0xFF4C4A78),
  ),
  WorldInfo(
    9,
    'Night District',
    'Limited light and changing reports.',
    Color(0xFF1E293B),
  ),
  WorldInfo(
    10,
    'Mountain Pass',
    'Broken bridges and long routes.',
    Color(0xFF57534E),
  ),
  WorldInfo(11, 'Metro Core', 'Many calls at once.', Color(0xFF334155)),
  WorldInfo(
    12,
    'Citywide Crisis',
    'Every earlier system at once.',
    Color(0xFF7F1D1D),
  ),
  WorldInfo(13, 'Finale', 'Linked teams across two zones.', Color(0xFF3F3F46)),
];

class CatalogEntry {
  final MissionScene scene;
  const CatalogEntry(this.scene);

  String get id => scene.id;
  int get world => scene.world;
  int get slot => scene.slot;
  int get number => missionNumber(scene.id);
  String get title => scene.title;
  String get brief => scene.brief;
  String get phase {
    if (world == 13) return 'finale';
    if (slot <= 4) return 'introduction';
    if (slot <= 10) return 'practice';
    if (slot <= 20) return 'synergy';
    if (slot <= 29) return 'advanced';
    return 'district_finale';
  }

  /// Ads never show after the first four teaching missions.
  String get tier => slot <= 4 && world == 1 ? 'tutorial' : phase;
}

class Catalog {
  final List<CatalogEntry> entries;
  final List<String> problems;
  const Catalog(this.entries, [this.problems = const []]);

  List<CatalogEntry> inWorld(int world) => [
    for (final e in entries)
      if (e.world == world) e,
  ];

  CatalogEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  static Catalog fromScenes(
    Iterable<MissionScene> scenes, [
    List<String> problems = const [],
  ]) => Catalog([for (final s in scenes) CatalogEntry(s)], problems);

  static Future<Catalog> load(AssetBundle bundle) async {
    final entries = <CatalogEntry>[];
    final problems = <String>[];
    for (var i = 1; i <= 365; i++) {
      final id = 'M${i.toString().padLeft(3, '0')}';
      final path = 'assets/missions/$id.json';
      try {
        final raw = await bundle.loadString(path);
        final scene = MissionScene.fromJson(
          (jsonDecode(raw) as Map).cast<String, Object?>(),
        );
        entries.add(CatalogEntry(scene));
      } catch (e) {
        if (i <= 10) problems.add('$id could not load: $e');
      }
    }
    return Catalog(entries, problems);
  }
}

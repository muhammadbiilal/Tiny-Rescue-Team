import 'dart:ui';

import 'package:flame/components.dart' hide Block;

import '../simulation/engine.dart';
import '../simulation/scene.dart';

const double worldW = 800;
const double worldH = 1040;

class HarborMap extends Component {
  final MissionScene scene;
  final Simulation Function() simOf;
  final bool highContrast;
  HarborMap(this.scene, this.simOf, {this.highContrast = false});

  @override
  void render(Canvas canvas) {
    final sim = simOf();
    _ground(canvas);
    for (final d in scene.decor) {
      _decor(canvas, d);
    }
    for (final e in scene.edges) {
      _edge(canvas, e, sim);
    }
    for (final n in scene.nodes) {
      _node(canvas, n, sim);
    }
  }

  void _ground(Canvas canvas) {
    final sky = highContrast
        ? const Color(0xFFE2E8F0)
        : scene.world == 2
        ? const Color(0xFFD6C4A8)
        : const Color(0xFFD7E8D2);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, worldW, worldH),
      Paint()..color = sky,
    );
    final wash = Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        const Offset(0, worldH),
        [
          const Color(0x66F4E4C1),
          const Color(0x00F4E4C1),
          const Color(0x3394A3B8),
        ],
        [0, 0.35, 1],
      );
    canvas.drawRect(const Rect.fromLTWH(0, 0, worldW, worldH), wash);
  }

  void _decor(Canvas canvas, String spec) {
    final parts = spec.split(':');
    if (parts.length != 2) return;
    final nums = [for (final n in parts[1].split(',')) double.tryParse(n) ?? 0];
    if (nums.length < 4) return;
    final r = Rect.fromLTWH(nums[0], nums[1], nums[2], nums[3]);
    switch (parts[0]) {
      case 'water':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(18)),
          Paint()
            ..shader = Gradient.linear(r.topLeft, r.bottomRight, [
              const Color(0xFF38BDF8),
              const Color(0xFF0E7490),
            ]),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(r.deflate(10), const Radius.circular(14)),
          Paint()..color = const Color(0x332DD4BF),
        );
      case 'pier':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(6)),
          Paint()..color = const Color(0xFFB45309),
        );
        for (var y = r.top + 8; y < r.bottom; y += 16) {
          canvas.drawLine(
            Offset(r.left + 4, y),
            Offset(r.right - 4, y),
            Paint()
              ..color = const Color(0x66FED7AA)
              ..strokeWidth = 2,
          );
        }
      case 'cobble':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()..color = const Color(0xAA78716C),
        );
      case 'eaves':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2)),
          Paint()..color = const Color(0xCC7C2D12),
        );
      case 'smoke':
        canvas.drawOval(r, Paint()..color = const Color(0x6687878A));
      case 'gable':
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(3)),
          Paint()..color = const Color(0xBB92400E),
        );
      default:
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = const Color(0x33FFFFFF),
        );
    }
  }

  void _edge(Canvas canvas, SceneEdge e, Simulation sim) {
    final a = scene.node(e.a);
    final b = scene.node(e.b);
    final blocked =
        sim.block[e.id] != Block.none && sim.block[e.id] != Block.dark;
    final dark = sim.block[e.id] == Block.dark;
    final water = (sim.terrain[e.id] ?? e.terrain) == Terrain.water;
    final color = highContrast
        ? (blocked ? const Color(0xFF111827) : const Color(0xFF1F2937))
        : water
        ? const Color(0xFF0284C7)
        : blocked
        ? const Color(0xFF9A3412)
        : dark
        ? const Color(0xFF334155)
        : const Color(0xFFE7D3A5);
    canvas.drawLine(
      Offset(a.x.toDouble(), a.y.toDouble()),
      Offset(b.x.toDouble(), b.y.toDouble()),
      Paint()
        ..color = color
        ..strokeWidth = blocked ? 10 : 14
        ..strokeCap = StrokeCap.round,
    );
    if (blocked) {
      final mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2;
      canvas.drawCircle(
        Offset(mx, my),
        8,
        Paint()..color = const Color(0xFFEA580C),
      );
    }
  }

  void _node(Canvas canvas, SceneNode n, Simulation sim) {
    final p = Offset(n.x.toDouble(), n.y.toDouble());
    final fill = switch (n.kind) {
      NodeKind.deploy => const Color(0xFF4ADE80),
      NodeKind.shelter => const Color(0xFFF8FAFC),
      NodeKind.pier => const Color(0xFFD97706),
      NodeKind.depot => const Color(0xFFF59E0B),
      NodeKind.need => const Color(0xFFFB7185),
      NodeKind.panel => const Color(0xFFA855F7),
      NodeKind.lookout => const Color(0xFF38BDF8),
      NodeKind.junction => const Color(0xFFCBD5E1),
      _ => const Color(0xFFF1E4C5),
    };
    canvas.drawCircle(
      p,
      n.kind == NodeKind.shelter ? 22 : 14,
      Paint()..color = fill.withValues(alpha: 0.95),
    );
    canvas.drawCircle(
      p,
      n.kind == NodeKind.shelter ? 22 : 14,
      Paint()
        ..color = const Color(0xFF1C1917)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    if (sim.fires[n.id] != null) {
      canvas.drawCircle(
        p,
        18 + sim.fires[n.id]! * 3.0,
        Paint()..color = const Color(0x88EF4444),
      );
    }
    if (n.label.isNotEmpty) {
      final builder =
          ParagraphBuilder(ParagraphStyle(fontSize: 11, fontFamily: 'Roboto'))
            ..pushStyle(TextStyle(color: const Color(0xFF1C1917), fontSize: 11))
            ..addText(n.label);
      final para = builder.build()
        ..layout(const ParagraphConstraints(width: 90));
      canvas.drawParagraph(para, Offset(p.dx - 45, p.dy + 16));
    }
  }
}

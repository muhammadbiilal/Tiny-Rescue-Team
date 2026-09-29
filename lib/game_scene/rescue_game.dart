import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../simulation/engine.dart';
import '../simulation/scene.dart';
import 'character_draw.dart';
import 'harbor_map.dart';

typedef EventSink = void Function(List<SimEvent> events);

class RescueGame extends FlameGame {
  final MissionScene scene;
  final Simulation sim;
  final bool reducedMotion;
  final bool highContrast;
  final EventSink? onEvents;
  double speed;
  double _acc = 0;
  double clock = 0;
  RescueGame({
    required this.scene,
    required this.sim,
    this.reducedMotion = false,
    this.highContrast = false,
    this.onEvents,
    this.speed = 1,
  });

  double get blend => (_acc / tickMs).clamp(0.0, 1.0);

  @override
  Color backgroundColor() => const Color(0xFFD7E8D2);

  @override
  Future<void> onLoad() async {
    camera.viewfinder.visibleGameSize = Vector2(worldW, worldH);
    camera.viewfinder.anchor = Anchor.topLeft;
    world.add(HarborMap(scene, () => sim, highContrast: highContrast));
    world.add(ActorsLayer(this));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (paused || !sim.running) return;
    clock += dt;
    _acc += dt * 1000 * speed;
    final emitted = <SimEvent>[];
    while (_acc >= tickMs && sim.running) {
      _acc -= tickMs;
      emitted.addAll(sim.step());
    }
    if (emitted.isNotEmpty) onEvents?.call(emitted);
  }

  Offset unitDraw(UnitState u) {
    final x = u.prevX + (u.x - u.prevX) * blend;
    final y = u.prevY + (u.y - u.prevY) * blend;
    return Offset(x, y);
  }
}

class ActorsLayer extends PositionComponent {
  final RescueGame game;
  ActorsLayer(this.game) : super(size: Vector2(worldW, worldH), priority: 10);

  @override
  void render(Canvas canvas) {
    final sim = game.sim;
    for (final c in sim.civilians.values) {
      if (!c.known || c.safe || c.lost || c.carriedBy >= 0) continue;
      final n = game.scene.node(c.node);
      _civilian(
        canvas,
        Offset(n.x.toDouble(), n.y.toDouble()),
        c.def.look,
        Pose.idle,
      );
    }
    for (final u in sim.units) {
      final p = game.unitDraw(u);
      final dx = (u.x - u.prevX).toDouble();
      final dy = (u.y - u.prevY).toDouble();
      final facing = facingFrom(dx, dy);
      final pose = _pose(u, sim);
      canvas.save();
      canvas.translate(p.dx - 36, p.dy - 78);
      drawResponder(
        canvas,
        const Size(72, 88),
        u.role,
        pose,
        facing,
        game.reducedMotion ? 0 : game.clock,
        highContrast: game.highContrast,
      );
      canvas.restore();
      if (u.carryingCivilian != null) {
        canvas.save();
        canvas.translate(p.dx - 8, p.dy - 70);
        _civilian(canvas, Offset.zero, 0, Pose.walk);
        canvas.restore();
      }
    }
  }

  void _civilian(Canvas canvas, Offset p, int look, Pose pose) {
    canvas.save();
    canvas.translate(p.dx - 28, p.dy - 52);
    drawCivilian(
      canvas,
      const Size(56, 64),
      look,
      pose,
      Facing.south,
      game.reducedMotion ? 0 : game.clock,
    );
    canvas.restore();
  }

  Pose _pose(UnitState u, Simulation sim) {
    if (sim.outcome == Outcome.won) return Pose.cheer;
    if (sim.outcome == Outcome.failed) return Pose.down;
    if (sim.tick < deployTicks) return Pose.deploy;
    if (u.abilityUsed &&
        u.activity == Activity.idle &&
        sim.events.isNotEmpty &&
        sim.events.last.type == EventType.ability) {
      return Pose.ability;
    }
    return switch (u.activity) {
      Activity.moving => Pose.walk,
      Activity.working => Pose.work,
      Activity.waiting || Activity.resting => Pose.idle,
      Activity.idle => Pose.idle,
    };
  }
}

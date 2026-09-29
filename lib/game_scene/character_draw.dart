import 'dart:math' as math;
import 'dart:ui';

import '../simulation/roles.dart';

enum Pose { idle, walk, work, ability, deploy, cheer, down }

enum Facing { south, north, east, west }

/// Original illustrated 2D figures. Palettes and silhouettes are unique to this game.
class RoleLook {
  final Color skin;
  final Color hair;
  final Color suit;
  final Color accent;
  final Color kit;
  const RoleLook(this.skin, this.hair, this.suit, this.accent, this.kit);
}

const rosaLook = RoleLook(
  Color(0xFFE8B89A),
  Color(0xFF2B1B12),
  Color(0xFFF4F0E6),
  Color(0xFFE4572E),
  Color(0xFFC2410C),
);

const tomiLook = RoleLook(
  Color(0xFF6B3F2A),
  Color(0xFF1A120E),
  Color(0xFF0F766E),
  Color(0xFF14B8A6),
  Color(0xFF134E4A),
);

RoleLook lookFor(Role role) => switch (role) {
  Role.rescuer => rosaLook,
  Role.medic => tomiLook,
  Role.engineer => RoleLook(
    const Color(0xFFD7A47A),
    const Color(0xFF4A2C17),
    const Color(0xFFFDE68A),
    const Color(0xFFCA8A04),
    const Color(0xFF854D0E),
  ),
  _ => RoleLook(
    const Color(0xFFC4A484),
    const Color(0xFF1F1A16),
    const Color(0xFF64748B),
    const Color(0xFF94A3B8),
    const Color(0xFF334155),
  ),
};

Facing facingFrom(double dx, double dy) {
  if (dx.abs() > dy.abs()) return dx >= 0 ? Facing.east : Facing.west;
  return dy >= 0 ? Facing.south : Facing.north;
}

void drawResponder(
  Canvas canvas,
  Size size,
  Role role,
  Pose pose,
  Facing facing,
  double t, {
  bool highContrast = false,
}) {
  final look = lookFor(role);
  final cx = size.width / 2;
  final ground = size.height * 0.92;
  final scale = size.width / 72;
  canvas.save();
  canvas.translate(cx, ground);
  canvas.scale(facing == Facing.west ? -scale : scale, scale);
  _figure(canvas, look, role, pose, facing, t, highContrast: highContrast);
  canvas.restore();
}

void drawCivilian(
  Canvas canvas,
  Size size,
  int look,
  Pose pose,
  Facing facing,
  double t,
) {
  const skins = [
    Color(0xFFE8C4A8),
    Color(0xFF8D5524),
    Color(0xFFF1D0B0),
    Color(0xFFC68642),
  ];
  const clothes = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    Color(0xFFDB2777),
    Color(0xFF059669),
  ];
  final roleLook = RoleLook(
    skins[look % 4],
    const Color(0xFF1C1917),
    clothes[look % 4],
    const Color(0xFFF8FAFC),
    clothes[look % 4],
  );
  final cx = size.width / 2;
  final ground = size.height * 0.92;
  final scale = size.width / 64;
  canvas.save();
  canvas.translate(cx, ground);
  canvas.scale(facing == Facing.west ? -scale : scale, scale);
  _figure(
    canvas,
    roleLook,
    Role.coordinator,
    pose,
    facing,
    t,
    highContrast: false,
    civilian: true,
  );
  canvas.restore();
}

void _figure(
  Canvas canvas,
  RoleLook look,
  Role role,
  Pose pose,
  Facing facing,
  double t, {
  required bool highContrast,
  bool civilian = false,
}) {
  final walk = pose == Pose.walk ? math.sin(t * math.pi * 2) : 0.0;
  final bob = pose == Pose.idle
      ? math.sin(t * math.pi * 2) * 1.2
      : (pose == Pose.walk ? walk.abs() * -2 : 0);
  final kneel = pose == Pose.work ? 7.0 : 0.0;
  final raise = pose == Pose.ability || pose == Pose.cheer ? 1.0 : 0.0;
  final side = facing == Facing.east || facing == Facing.west;

  void oval(Rect r, Color c) {
    canvas.drawOval(
      r,
      Paint()..color = highContrast ? c.withValues(alpha: 1) : c,
    );
  }

  void shade(Rect r, Color a, Color b) {
    canvas.drawOval(
      r,
      Paint()..shader = Gradient.linear(r.topCenter, r.bottomCenter, [a, b]),
    );
  }

  // Shadow
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, 2), width: 28, height: 8),
    Paint()..color = const Color(0x33000000),
  );

  canvas.translate(0, bob - kneel);

  final legSwing = walk * 10;
  final leftLeg = Offset(-6, -2);
  final rightLeg = Offset(6, -2);
  _limb(
    canvas,
    leftLeg,
    Offset(-7 + (side ? 0 : -legSwing * 0.2), 16 + (side ? legSwing : 0)),
    look.kit.withValues(alpha: 0.85),
    5,
  );
  _limb(
    canvas,
    rightLeg,
    Offset(7 + (side ? 0 : legSwing * 0.2), 16 + (side ? -legSwing : 0)),
    look.kit.withValues(alpha: 0.9),
    5,
  );

  // Torso
  shade(
    const Rect.fromLTWH(-12, -34, 24, 30),
    look.suit,
    Color.lerp(look.suit, look.accent, 0.25)!,
  );
  // Vest / jacket panel
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(-11, -32, 22, 16),
      const Radius.circular(4),
    ),
    Paint()..color = look.accent,
  );

  // Kit: Rosa helmet brim / Tomi bag
  if (!civilian && role == Role.rescuer) {
    shade(const Rect.fromLTWH(-13, -56, 26, 14), look.accent, look.kit);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-15, -48, 30, 5),
        const Radius.circular(2),
      ),
      Paint()..color = look.kit,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-2, -54, 12, 3),
      Paint()..color = const Color(0xFFF8FAFC),
    );
  } else if (!civilian && role == Role.medic) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, -28, 12, 16),
        const Radius.circular(3),
      ),
      Paint()..color = look.kit,
    );
    canvas.drawRect(
      const Rect.fromLTWH(11, -23, 6, 2),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawRect(
      const Rect.fromLTWH(13, -25, 2, 6),
      Paint()..color = const Color(0xFFF8FAFC),
    );
  }

  final armLift = raise * -22 + (pose == Pose.work ? 8 : 0) + walk * 8;
  _limb(
    canvas,
    const Offset(-11, -28),
    Offset(-16, -8 + armLift * 0.15),
    look.suit,
    4.2,
  );
  _limb(
    canvas,
    const Offset(11, -28),
    Offset(16 + raise * 4, -18 + armLift),
    look.suit,
    4.2,
  );

  // Head
  shade(
    const Rect.fromLTWH(-10, -52, 20, 20),
    Color.lerp(look.skin, const Color(0xFFFFFFFF), 0.12)!,
    look.skin,
  );
  if (role != Role.rescuer || civilian) {
    oval(const Rect.fromLTWH(-10, -56, 20, 10), look.hair);
  }
  // Eyes
  if (facing != Facing.north) {
    final eyeY = -43.0;
    canvas.drawCircle(
      Offset(side ? 3 : -3.5, eyeY),
      1.4,
      Paint()..color = const Color(0xFF1C1917),
    );
    if (!side)
      canvas.drawCircle(
        const Offset(3.5, -43),
        1.4,
        Paint()..color = const Color(0xFF1C1917),
      );
  }
  if (pose == Pose.down) {
    canvas.drawArc(
      const Rect.fromLTWH(-6, -40, 12, 6),
      0.2,
      2.7,
      false,
      Paint()
        ..color = const Color(0xFF1C1917)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }
}

void _limb(Canvas canvas, Offset from, Offset to, Color color, double width) {
  canvas.drawLine(
    from,
    to,
    Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
}

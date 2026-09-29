import 'package:flutter/material.dart';

import '../app_state.dart';
import '../game_scene/character_draw.dart';
import '../l10n/gen/app_localizations.dart';
import '../simulation/describe.dart';
import '../simulation/progression.dart';
import '../simulation/roles.dart';

class RosterScreen extends StatelessWidget {
  const RosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final unlocked = rolesUnlockedAt(app.totalCompleted + 1).toSet();
    return Scaffold(
      appBar: AppBar(title: Text(l.roster)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            l.tokens(app.tokens),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final role in Role.values)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Portrait(role: role, locked: !unlocked.contains(role)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roleName[role]!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            unlocked.contains(role)
                                ? roleTitle[role]!
                                : 'Unlocks later',
                          ),
                          Text(abilityTitle[role.def.ability]!),
                          if (unlocked.contains(role)) ...[
                            Text(abilityHelp[role.def.ability]!),
                            const SizedBox(height: 8),
                            Text(
                              '${l.mobility}: ${app.upgradeOf(role).path == UpgradePath.mobility ? 'T${app.upgradeOf(role).tier}' : '—'}',
                            ),
                            Text(
                              '${l.expertise}: ${app.upgradeOf(role).path == UpgradePath.expertise ? 'T${app.upgradeOf(role).tier}' : '—'}',
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    final err = app.buyUpgrade(
                                      role,
                                      UpgradePath.mobility,
                                    );
                                    if (err != null)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(err)),
                                      );
                                  },
                                  child: Text(l.mobility),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final err = app.buyUpgrade(
                                      role,
                                      UpgradePath.expertise,
                                    );
                                    if (err != null)
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(err)),
                                      );
                                  },
                                  child: Text(l.expertise),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      app.buyUpgrade(role, UpgradePath.none),
                                  child: Text(l.respec),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  final Role role;
  final bool locked;
  const _Portrait({required this.role, required this.locked});

  @override
  Widget build(BuildContext context) {
    final asset = switch (role) {
      Role.rescuer => 'assets/art/rosa_portrait.png',
      Role.medic => 'assets/art/tomi_portrait.png',
      _ => null,
    };
    Widget child;
    if (asset != null) {
      child = Image.asset(
        asset,
        width: 88,
        height: 110,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            CustomPaint(size: const Size(88, 110), painter: _Silhouette(role)),
      );
    } else {
      child = CustomPaint(
        size: const Size(88, 110),
        painter: _Silhouette(role),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColorFiltered(
        colorFilter: locked
            ? const ColorFilter.mode(Color(0xFF94A3B8), BlendMode.saturation)
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: child,
      ),
    );
  }
}

class _Silhouette extends CustomPainter {
  final Role role;
  const _Silhouette(this.role);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE2E8F0),
    );
    drawResponder(canvas, size, role, Pose.idle, Facing.south, 0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HomeRosterPreview extends StatelessWidget {
  const HomeRosterPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/art/rosa_portrait.png',
              width: 120,
              height: 168,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const SizedBox(
                width: 120,
                height: 168,
                child: ColoredBox(color: Color(0xFFE4572E)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/art/tomi_portrait.png',
              width: 120,
              height: 168,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => const SizedBox(
                width: 120,
                height: 168,
                child: ColoredBox(color: Color(0xFF14B8A6)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

# Tiny Rescue Team v2 — Progress

29 September 2026: Harbor M001–M030, Old Town M031–M060, and Riverside M061–M090 are playable offline with solver witnesses. The v1 grid puzzle is not used. **This is not a production-ready 365-mission release.**

| Count | Number | Evidence |
|---|---|---|
| Briefed | 365 | `docs/MISSIONS_001_365.json` `design_brief_only` |
| Scene-authored | 90 | `tool/content/` Harbor + Old Town + Riverside → `assets/missions/M001.json`–`M090.json` |
| Solver-validated | 90 | `dart run tool/export_missions.dart` (90/90) and `dart run tool/validate_content.dart` (0 errors, 0 warnings) |
| Human-played | 0 | No uncoached player session recorded |
| Art-complete (slice bar) | 2 roles + Harbor card | Rosa and Tomi portraits + in-engine animation. Bea, Juno (Scout, M031), and Marco (Boat Pilot, M061) use the shared silhouette until portraits exist |
| Release-ready | 0 | Privacy/ads, signing, device FPS, M091–M365, remaining role art, name clearance open |

Harbor free roster is three roles (Rosa, Tomi, Bea). CSV `team_size` 4 on Harbor slots 21–30 cannot be unique free roles until Scout unlocks at M031, so authored Harbor scenes use team size 3.

Old Town intro/practice (M031–M040) uses team size 2 with Juno Park plus Rosa or Tomi. Synergy uses 3. Advanced and the district finale use all four free roles.

Riverside unlocks Marco Reyes. Water lanes are boat-only; `routeOpen` still requires a land path. Intro/practice is team 2, synergy 3, advanced 4.

Solver-tagged `moderate` in the authored set: M028, M036, M074, M078, M080, M089, M090. The rest are `straightforward`.

CSV duplicate phrasing (M048/M058 two corridors; M078/M088 two call pairs) is authored as distinct jobs, not copied objectives.

## Tests actually run this batch

- `dart format` on touched files
- `flutter analyze --no-fatal-infos` — no errors on the last Harbor/Old Town pass; Riverside files formatted
- `flutter test` — Harbor, Old Town, and Riverside witnesses
- `dart run tool/validate_content.dart` — `briefs=365 authored=90 solver_validated=90 warnings=0 errors=0`
- Android debug APK: previously failed on Kotlin incremental caches for plugin modules; not re-run this batch
- iOS: not built (Windows host)
- Device FPS: not measured
- Ads: default disabled; `ADS_MODE=production` refused

## Not claimed

- 365 playable encounters (M091–M365 still briefs; next district is Industrial Zone)
- Production art/audio mix
- Human QA or 60 FPS
- Store submission, paid assets, or production ad IDs

# Tiny Rescue Team v2 — Progress

29 September 2026: Harbor District M001–M030 is playable offline with solver witnesses. The v1 grid puzzle is not used. **This is not a production-ready 365-mission release.**

| Count | Number | Evidence |
|---|---|---|
| Briefed | 365 | `docs/MISSIONS_001_365.json` `design_brief_only` |
| Scene-authored | 30 | `tool/content/slice.dart` + `tool/content/harbor_w01.dart` → `assets/missions/M001.json`–`M030.json` |
| Solver-validated | 30 | `dart run tool/export_missions.dart` (30/30) and `dart run tool/validate_content.dart` (0 errors, 0 warnings) |
| Human-played | 0 | No uncoached player session recorded |
| Art-complete (slice bar) | 2 roles + Harbor card | Rosa and Tomi portraits + in-engine animation. Bea (Engineer) uses the shared silhouette until her portrait exists |
| Release-ready | 0 | Privacy/ads, signing, device FPS, M031–M365, remaining role art, name clearance open |

Harbor free roster is three roles (Rosa, Tomi, Bea). CSV `team_size` 4 on slots 21–30 cannot be unique free roles until Scout unlocks at M031, so authored scenes use team size 3.

M028 is the only Harbor mission the solver tagged `moderate`; the rest are `straightforward`.

## Tests actually run this batch

- `dart format` on touched files
- `flutter analyze --no-fatal-infos` — no errors
- `flutter test` — 12 passed, including Harbor M001–M030 witnesses
- `dart run tool/validate_content.dart` — `briefs=365 authored=30 solver_validated=30 warnings=0 errors=0`
- Android debug APK: previously failed on Kotlin incremental caches for plugin modules; not re-run this batch
- iOS: not built (Windows host)
- Device FPS: not measured
- Ads: default disabled; `ADS_MODE=production` refused

## Not claimed

- 365 playable encounters (M031–M365 still briefs)
- Production art/audio mix
- Human QA or 60 FPS
- Store submission, paid assets, or production ad IDs

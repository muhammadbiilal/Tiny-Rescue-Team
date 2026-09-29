// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tiny Rescue Team';

  @override
  String get tagline =>
      'Plan the team. Dispatch. Watch them work. Fictional rescues, not real safety training.';

  @override
  String get play => 'Play';

  @override
  String continueLevel(String id) {
    return 'Continue $id';
  }

  @override
  String get worlds => 'Districts';

  @override
  String get roster => 'Team';

  @override
  String get settings => 'Settings';

  @override
  String get progress => 'Progress';

  @override
  String get credits => 'Credits and privacy';

  @override
  String get worldLocked => 'Finish the previous district to unlock';

  @override
  String levelsDone(int done, int total) {
    return '$done of $total complete';
  }

  @override
  String levelLocked(String id) {
    return 'Mission $id, locked';
  }

  @override
  String levelOpen(String id, int stars) {
    return 'Mission $id, $stars stars';
  }

  @override
  String get dispatch => 'Dispatch';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get speed => 'Speed';

  @override
  String get objective => 'Objective';

  @override
  String get forecast => 'Forecast';

  @override
  String get tutorial => 'How it works';

  @override
  String get gotIt => 'Got it';

  @override
  String get levels => 'Missions';

  @override
  String get nextLevel => 'Next mission';

  @override
  String get replay => 'Play again';

  @override
  String get won => 'Everyone is safe!';

  @override
  String wonDetail(int seconds) {
    return 'Finished in $seconds seconds.';
  }

  @override
  String get failed => 'Call unfinished';

  @override
  String get music => 'Music';

  @override
  String get effects => 'Sound effects';

  @override
  String get reducedMotion => 'Reduce motion';

  @override
  String get highContrast => 'High contrast map';

  @override
  String get haptics => 'Vibration';

  @override
  String get listControls =>
      'List controls (screen reader and switch friendly)';

  @override
  String get resetProgress => 'Reset all progress';

  @override
  String get resetConfirm =>
      'Erase all completed missions, stars, tokens and upgrades on this device?';

  @override
  String get cancel => 'Cancel';

  @override
  String get erase => 'Erase';

  @override
  String get recoveredBackup =>
      'Your save was damaged and was restored from a backup.';

  @override
  String get recoveredReset =>
      'Your save was damaged and could not be restored. A copy was kept on the device.';

  @override
  String get contentProblem =>
      'Some mission files could not be loaded. Reinstall the app if missions are missing.';

  @override
  String starsEarned(int stars) {
    return '$stars of 3 stars';
  }

  @override
  String totalStars(int stars, int done, int total) {
    return '$stars stars, $done of $total missions';
  }

  @override
  String tokens(int count) {
    return '$count service tokens';
  }

  @override
  String get placeTeam => 'Place the team';

  @override
  String get equipment => 'Equipment';

  @override
  String get priority => 'Priority';

  @override
  String get ability => 'Ability';

  @override
  String get redirect => 'Redirect';

  @override
  String get eventLog => 'What happened';

  @override
  String get creditsBody =>
      'Tiny Rescue Team is a fictional tactical rescue game. It does not teach real emergency procedures and is not affiliated with any emergency service.\n\nPrivacy: the game works fully offline. It has no account, no analytics and sends no personal data. Progress is stored only on this device. Advertising is switched off in this build.\n\nArt: original illustrated portraits (Rosa Quill, Tomi Okafor, Harbor backdrop) plus original in-engine character animation. Audio: original synthesized tones for this project. See assets/art/ASSET_REGISTER.md.';

  @override
  String get adLabel => 'Advertisement';

  @override
  String get respec => 'Refund path';

  @override
  String get mobility => 'Mobility';

  @override
  String get expertise => 'Expertise';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tiny Rescue Team'**
  String get appTitle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Plan the team. Dispatch. Watch them work. Fictional rescues, not real safety training.'**
  String get tagline;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @continueLevel.
  ///
  /// In en, this message translates to:
  /// **'Continue {id}'**
  String continueLevel(String id);

  /// No description provided for @worlds.
  ///
  /// In en, this message translates to:
  /// **'Districts'**
  String get worlds;

  /// No description provided for @roster.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get roster;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @credits.
  ///
  /// In en, this message translates to:
  /// **'Credits and privacy'**
  String get credits;

  /// No description provided for @worldLocked.
  ///
  /// In en, this message translates to:
  /// **'Finish the previous district to unlock'**
  String get worldLocked;

  /// No description provided for @levelsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} complete'**
  String levelsDone(int done, int total);

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Mission {id}, locked'**
  String levelLocked(String id);

  /// No description provided for @levelOpen.
  ///
  /// In en, this message translates to:
  /// **'Mission {id}, {stars} stars'**
  String levelOpen(String id, int stars);

  /// No description provided for @dispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get dispatch;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @objective.
  ///
  /// In en, this message translates to:
  /// **'Objective'**
  String get objective;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @tutorial.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get tutorial;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @levels.
  ///
  /// In en, this message translates to:
  /// **'Missions'**
  String get levels;

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next mission'**
  String get nextLevel;

  /// No description provided for @replay.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get replay;

  /// No description provided for @won.
  ///
  /// In en, this message translates to:
  /// **'Everyone is safe!'**
  String get won;

  /// No description provided for @wonDetail.
  ///
  /// In en, this message translates to:
  /// **'Finished in {seconds} seconds.'**
  String wonDetail(int seconds);

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Call unfinished'**
  String get failed;

  /// No description provided for @music.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get music;

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get effects;

  /// No description provided for @reducedMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reducedMotion;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast map'**
  String get highContrast;

  /// No description provided for @haptics.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get haptics;

  /// No description provided for @listControls.
  ///
  /// In en, this message translates to:
  /// **'List controls (screen reader and switch friendly)'**
  String get listControls;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset all progress'**
  String get resetProgress;

  /// No description provided for @resetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Erase all completed missions, stars, tokens and upgrades on this device?'**
  String get resetConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @erase.
  ///
  /// In en, this message translates to:
  /// **'Erase'**
  String get erase;

  /// No description provided for @recoveredBackup.
  ///
  /// In en, this message translates to:
  /// **'Your save was damaged and was restored from a backup.'**
  String get recoveredBackup;

  /// No description provided for @recoveredReset.
  ///
  /// In en, this message translates to:
  /// **'Your save was damaged and could not be restored. A copy was kept on the device.'**
  String get recoveredReset;

  /// No description provided for @contentProblem.
  ///
  /// In en, this message translates to:
  /// **'Some mission files could not be loaded. Reinstall the app if missions are missing.'**
  String get contentProblem;

  /// No description provided for @starsEarned.
  ///
  /// In en, this message translates to:
  /// **'{stars} of 3 stars'**
  String starsEarned(int stars);

  /// No description provided for @totalStars.
  ///
  /// In en, this message translates to:
  /// **'{stars} stars, {done} of {total} missions'**
  String totalStars(int stars, int done, int total);

  /// No description provided for @tokens.
  ///
  /// In en, this message translates to:
  /// **'{count} service tokens'**
  String tokens(int count);

  /// No description provided for @placeTeam.
  ///
  /// In en, this message translates to:
  /// **'Place the team'**
  String get placeTeam;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @ability.
  ///
  /// In en, this message translates to:
  /// **'Ability'**
  String get ability;

  /// No description provided for @redirect.
  ///
  /// In en, this message translates to:
  /// **'Redirect'**
  String get redirect;

  /// No description provided for @eventLog.
  ///
  /// In en, this message translates to:
  /// **'What happened'**
  String get eventLog;

  /// No description provided for @creditsBody.
  ///
  /// In en, this message translates to:
  /// **'Tiny Rescue Team is a fictional tactical rescue game. It does not teach real emergency procedures and is not affiliated with any emergency service.\n\nPrivacy: the game works fully offline. It has no account, no analytics and sends no personal data. Progress is stored only on this device. Advertising is switched off in this build.\n\nArt: original illustrated portraits (Rosa Quill, Tomi Okafor, Harbor backdrop) plus original in-engine character animation. Audio: original synthesized tones for this project. See assets/art/ASSET_REGISTER.md.'**
  String get creditsBody;

  /// No description provided for @adLabel.
  ///
  /// In en, this message translates to:
  /// **'Advertisement'**
  String get adLabel;

  /// No description provided for @respec.
  ///
  /// In en, this message translates to:
  /// **'Refund path'**
  String get respec;

  /// No description provided for @mobility.
  ///
  /// In en, this message translates to:
  /// **'Mobility'**
  String get mobility;

  /// No description provided for @expertise.
  ///
  /// In en, this message translates to:
  /// **'Expertise'**
  String get expertise;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

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

  /// App name shown in the home app bar and task switcher.
  ///
  /// In en, this message translates to:
  /// **'CleanCut'**
  String get appTitle;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get commonRedo;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsThemeSection.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeSection;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as device'**
  String get themeSystem;

  /// No description provided for @homeNewProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get homeNewProject;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap New project to pick videos and photos.'**
  String get homeEmptyBody;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your projects.'**
  String get homeLoadFailed;

  /// No description provided for @homeProjectOptions.
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String homeProjectOptions(String name);

  /// No description provided for @projectClipCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Empty} =1{1 clip} other{{count} clips}}'**
  String projectClipCount(int count);

  /// No description provided for @projectEditedOn.
  ///
  /// In en, this message translates to:
  /// **'Edited {date}'**
  String projectEditedOn(DateTime date);

  /// No description provided for @projectDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Project {date}'**
  String projectDefaultName(DateTime date);

  /// No description provided for @projectCopyName.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String projectCopyName(String name);

  /// No description provided for @projectRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get projectRename;

  /// No description provided for @projectDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get projectDuplicate;

  /// No description provided for @projectDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get projectDelete;

  /// No description provided for @projectRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename project'**
  String get projectRenameTitle;

  /// No description provided for @projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectNameLabel;

  /// No description provided for @projectNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get projectNameEmpty;

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String projectDeleted(String name);

  /// No description provided for @projectActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get projectActionFailed;

  /// No description provided for @aspectSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Canvas size'**
  String get aspectSheetTitle;

  /// No description provided for @aspectOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get aspectOriginal;

  /// No description provided for @aspectRatioLabel.
  ///
  /// In en, this message translates to:
  /// **'{width}:{height}'**
  String aspectRatioLabel(int width, int height);

  /// No description provided for @mediaPickerFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your media.'**
  String get mediaPickerFailed;

  /// No description provided for @editorPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'The editor is coming soon.'**
  String get editorPlaceholder;

  /// No description provided for @editorClipSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No clips} =1{1 clip} other{{count} clips}} · {duration}'**
  String editorClipSummary(int count, String duration);

  /// No description provided for @editorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This project no longer exists.'**
  String get editorNotFound;

  /// No description provided for @editorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes.'**
  String get editorSaveFailed;
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

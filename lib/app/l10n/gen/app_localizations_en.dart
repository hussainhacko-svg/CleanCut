// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CleanCut';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonRedo => 'Redo';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonBack => 'Back';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsThemeSection => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'Same as device';

  @override
  String get homeNewProject => 'New project';

  @override
  String get homeEmptyTitle => 'No projects yet';

  @override
  String get homeEmptyBody => 'Tap New project to pick videos and photos.';

  @override
  String get homeLoadFailed => 'Couldn\'t load your projects.';

  @override
  String homeProjectOptions(String name) {
    return 'Options for $name';
  }

  @override
  String projectClipCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clips',
      one: '1 clip',
      zero: 'Empty',
    );
    return '$_temp0';
  }

  @override
  String projectEditedOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Edited $dateString';
  }

  @override
  String projectDefaultName(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Project $dateString';
  }

  @override
  String projectCopyName(String name) {
    return '$name copy';
  }

  @override
  String get projectRename => 'Rename';

  @override
  String get projectDuplicate => 'Duplicate';

  @override
  String get projectDelete => 'Delete';

  @override
  String get projectRenameTitle => 'Rename project';

  @override
  String get projectNameLabel => 'Name';

  @override
  String get projectNameEmpty => 'Enter a name';

  @override
  String projectDeleted(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get projectActionFailed => 'Something went wrong. Please try again.';

  @override
  String get aspectSheetTitle => 'Canvas size';

  @override
  String get aspectOriginal => 'Original';

  @override
  String aspectRatioLabel(int width, int height) {
    return '$width:$height';
  }

  @override
  String get mediaPickerFailed => 'Couldn\'t open your media.';

  @override
  String get editorPlaceholder => 'The editor is coming soon.';

  @override
  String editorClipSummary(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count clips',
      one: '1 clip',
      zero: 'No clips',
    );
    return '$_temp0 · $duration';
  }

  @override
  String get editorNotFound => 'This project no longer exists.';

  @override
  String get editorSaveFailed => 'Couldn\'t save your changes.';
}

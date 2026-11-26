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
  String get homeMyProjects => 'My projects';

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
  String projectCardDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat(
      'd, MMM, y',
      localeName,
    );
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
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
  String get editorNotFound => 'This project no longer exists.';

  @override
  String get editorSaveFailed => 'Couldn\'t save your changes.';

  @override
  String get editorHome => 'Home';

  @override
  String get editorExport => 'Export';

  @override
  String get editorExportSoon => 'Export is coming in a later update.';

  @override
  String get editorPlay => 'Play';

  @override
  String get editorPause => 'Pause';

  @override
  String get editorFullscreen => 'Full screen';

  @override
  String get editorExitFullscreen => 'Exit full screen';

  @override
  String editorTimecode(String position, String duration) {
    return '$position / $duration';
  }

  @override
  String get editorPlaybackFailed => 'Couldn\'t play this project\'s media.';

  @override
  String get editorSeek => 'Playback position';

  @override
  String get editorToolSoon => 'Coming in a later update.';

  @override
  String get toolAdd => 'Add media';

  @override
  String get toolMusic => 'Music';

  @override
  String get toolVoice => 'Voice';

  @override
  String get toolText => 'Text';

  @override
  String get toolEffect => 'Effect';

  @override
  String get toolOverlay => 'Overlay';

  @override
  String get toolRatio => 'Ratio';

  @override
  String get toolSplit => 'Split';

  @override
  String get toolFilters => 'Filters';

  @override
  String get toolCrop => 'Crop';

  @override
  String get toolAdjust => 'Adjust';

  @override
  String get toolSpeed => 'Speed';

  @override
  String get toolAnimation => 'Animation';

  @override
  String get toolVolume => 'Volume';

  @override
  String get toolDelete => 'Delete';

  @override
  String get laneOverlay => 'Overlay';

  @override
  String get laneAudio => 'Audio';

  @override
  String get timelineTransition => 'Transition';

  @override
  String get timelineMuteOriginal => 'Mute original audio';

  @override
  String get panelTitle => 'Properties';

  @override
  String get panelNothingSelected =>
      'Select a clip on the timeline to edit it.';

  @override
  String get panelClip => 'Clip';
}

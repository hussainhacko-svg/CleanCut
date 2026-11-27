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
  String get commonReset => 'Reset';

  @override
  String get commonClose => 'Close';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsLicenses => 'Open source licenses';

  @override
  String get homeNewProject => 'New project';

  @override
  String get homeMyProjects => 'My projects';

  @override
  String get homeEmptyTitle => 'No projects yet';

  @override
  String get homeEmptyBody => 'Tap + to pick videos and photos.';

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
  String get toolDuplicate => 'Duplicate';

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

  @override
  String get editorSplitOutside =>
      'Move the playhead over the selected clip to split it.';

  @override
  String speedValue(double value) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString×';
  }

  @override
  String get speedKeepPitch => 'Keep pitch';

  @override
  String get speedTypeTitle => 'Speed';

  @override
  String get speedTypeLabel => 'Speed (0.1–10)';

  @override
  String get speedTypeInvalid => 'Enter a speed from 0.1 to 10';

  @override
  String get speedTypeHint => 'Tap to type an exact speed';

  @override
  String get speedTabNormal => 'Normal';

  @override
  String get speedTabCurve => 'Curve';

  @override
  String get curveNone => 'None';

  @override
  String get curveCustom => 'Custom';

  @override
  String get curveMontage => 'Montage';

  @override
  String get curveHero => 'Hero';

  @override
  String get curveBullet => 'Bullet';

  @override
  String get curveFlashIn => 'Flash in';

  @override
  String get curveFlashOut => 'Flash out';

  @override
  String get curveEditHint => 'Tap again to edit the curve';

  @override
  String get curveGraph =>
      'Speed curve. Drag a point to change the speed there.';

  @override
  String get curveAddPoint => 'Add point';

  @override
  String get curveDeletePoint => 'Delete point';

  @override
  String get curveBackToPresets => 'Presets';

  @override
  String get cropFree => 'Free';

  @override
  String cropAspect(int width, int height) {
    return '$width:$height';
  }

  @override
  String get cropMirror => 'Mirror';

  @override
  String get cropFlip => 'Flip';

  @override
  String get cropRotate90 => 'Rotate 90°';

  @override
  String get cropRotation => 'Rotation';

  @override
  String rotationValue(int value) {
    return '$value°';
  }

  @override
  String get rotationTypeLabel => 'Degrees (−180 to 180)';

  @override
  String get rotationTypeInvalid => 'Enter an angle from −180 to 180';

  @override
  String get rotationTypeHint => 'Tap to type an exact angle';

  @override
  String get cropOverlayLabel => 'Crop frame handles';

  @override
  String get transformGizmoLabel => 'Transform preview';

  @override
  String get toolTransform => 'Transform';

  @override
  String get transformTabFill => 'Fill';

  @override
  String get transformTabPosition => 'Position';

  @override
  String get transformTabOpacity => 'Opacity';

  @override
  String get transformTabBorder => 'Border';

  @override
  String get fitModeFit => 'Fit';

  @override
  String get fitModeFill => 'Fill';

  @override
  String get fitModeStretch => 'Stretch';

  @override
  String get transformX => 'X';

  @override
  String get transformY => 'Y';

  @override
  String get transformScale => 'Scale';

  @override
  String get transformOpacity => 'Opacity';

  @override
  String get transformBorderWidth => 'Width';

  @override
  String get transformBorderCorners => 'Corners';

  @override
  String get transformBorderColor => 'Color';

  @override
  String percentValue(int value) {
    return '$value%';
  }

  @override
  String valueRangeLabel(String min, String max) {
    return '$min to $max';
  }

  @override
  String valueRangeInvalid(String min, String max) {
    return 'Enter a value from $min to $max';
  }

  @override
  String get tapToTypeHint => 'Tap to type an exact value';

  @override
  String colorSwatchLabel(int index) {
    return 'Color $index';
  }

  @override
  String get ratioTabRatio => 'Ratio';

  @override
  String get ratioTabBackground => 'Background';

  @override
  String get backgroundColor => 'Color';

  @override
  String get backgroundGradient => 'Gradient';

  @override
  String get backgroundBlur => 'Blur';

  @override
  String get backgroundImage => 'Image';

  @override
  String get backgroundAngle => 'Angle';

  @override
  String get backgroundBlurAmount => 'Strength';

  @override
  String get backgroundPickImage => 'Choose image';

  @override
  String get backgroundChangeImage => 'Change image';

  @override
  String gradientSwatchLabel(int index) {
    return 'Gradient $index';
  }

  @override
  String keyframeAdd(String property) {
    return 'Add $property keyframe';
  }

  @override
  String keyframeRemove(String property) {
    return 'Remove $property keyframe';
  }

  @override
  String get filterCategoryFilm => 'Film';

  @override
  String get filterCategoryVibrant => 'Vibrant';

  @override
  String get filterCategoryBw => 'B&W';

  @override
  String get filterNone => 'None';

  @override
  String get filterGold => 'Gold';

  @override
  String get filterVelvia => 'Velvia';

  @override
  String get filterVintage => 'Vintage';

  @override
  String get filterCinema => 'Cinema';

  @override
  String get filterVivid => 'Vivid';

  @override
  String get filterSunset => 'Sunset';

  @override
  String get filterNordic => 'Nordic';

  @override
  String get filterPastel => 'Pastel';

  @override
  String get filterNoir => 'Noir';

  @override
  String get filterSilver => 'Silver';

  @override
  String get filterSepia => 'Sepia';

  @override
  String get filterMatte => 'Matte';

  @override
  String get filterIntensity => 'Intensity';

  @override
  String get adjustExposure => 'Exposure';

  @override
  String get adjustBrightness => 'Brightness';

  @override
  String get adjustContrast => 'Contrast';

  @override
  String get adjustSaturation => 'Saturation';

  @override
  String get adjustWarmth => 'Warmth';

  @override
  String get adjustTint => 'Tint';

  @override
  String get adjustHighlights => 'Highlights';

  @override
  String get adjustShadows => 'Shadows';

  @override
  String get adjustSharpen => 'Sharpen';

  @override
  String get adjustVignette => 'Vignette';

  @override
  String adjustResetField(String field) {
    return 'Reset $field';
  }

  @override
  String get toolBlur => 'Blur';

  @override
  String get toolMask => 'Mask';

  @override
  String get blurStrength => 'Strength';

  @override
  String get maskNone => 'None';

  @override
  String get maskLinear => 'Linear';

  @override
  String get maskMirror => 'Mirror';

  @override
  String get maskCircle => 'Circle';

  @override
  String get maskRect => 'Rectangle';

  @override
  String get maskHeart => 'Heart';

  @override
  String get maskStar => 'Star';

  @override
  String get maskFeather => 'Feather';

  @override
  String get maskRotation => 'Rotation';

  @override
  String get maskSize => 'Size';

  @override
  String get maskInvert => 'Invert';

  @override
  String get maskPosition => 'Position';

  @override
  String get maskOverlayLabel => 'Mask handles';
}

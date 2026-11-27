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

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get settingsLicenses;

  /// No description provided for @homeNewProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get homeNewProject;

  /// No description provided for @homeMyProjects.
  ///
  /// In en, this message translates to:
  /// **'My projects'**
  String get homeMyProjects;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to pick videos and photos.'**
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

  /// Last-edited date on a project card, e.g. 26, Aug, 2023.
  ///
  /// In en, this message translates to:
  /// **'{date}'**
  String projectCardDate(DateTime date);

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

  /// No description provided for @editorHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get editorHome;

  /// No description provided for @editorExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get editorExport;

  /// No description provided for @editorExportSoon.
  ///
  /// In en, this message translates to:
  /// **'Export is coming in a later update.'**
  String get editorExportSoon;

  /// No description provided for @editorPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get editorPlay;

  /// No description provided for @editorPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get editorPause;

  /// No description provided for @editorFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get editorFullscreen;

  /// No description provided for @editorExitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get editorExitFullscreen;

  /// Playback readout under the preview, e.g. 00:06 / 00:12.
  ///
  /// In en, this message translates to:
  /// **'{position} / {duration}'**
  String editorTimecode(String position, String duration);

  /// No description provided for @editorPlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play this project\'s media.'**
  String get editorPlaybackFailed;

  /// No description provided for @editorSeek.
  ///
  /// In en, this message translates to:
  /// **'Playback position'**
  String get editorSeek;

  /// No description provided for @editorToolSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later update.'**
  String get editorToolSoon;

  /// No description provided for @toolAdd.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get toolAdd;

  /// No description provided for @toolMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get toolMusic;

  /// No description provided for @toolVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get toolVoice;

  /// No description provided for @toolText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get toolText;

  /// No description provided for @toolEffect.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get toolEffect;

  /// No description provided for @toolOverlay.
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get toolOverlay;

  /// No description provided for @toolRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get toolRatio;

  /// No description provided for @toolSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get toolSplit;

  /// No description provided for @toolDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get toolDuplicate;

  /// No description provided for @toolFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get toolFilters;

  /// No description provided for @toolCrop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get toolCrop;

  /// No description provided for @toolAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get toolAdjust;

  /// No description provided for @toolSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get toolSpeed;

  /// No description provided for @toolAnimation.
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get toolAnimation;

  /// No description provided for @toolVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get toolVolume;

  /// No description provided for @toolDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get toolDelete;

  /// No description provided for @laneOverlay.
  ///
  /// In en, this message translates to:
  /// **'Overlay'**
  String get laneOverlay;

  /// No description provided for @laneAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get laneAudio;

  /// No description provided for @timelineTransition.
  ///
  /// In en, this message translates to:
  /// **'Transition'**
  String get timelineTransition;

  /// No description provided for @timelineMuteOriginal.
  ///
  /// In en, this message translates to:
  /// **'Mute original audio'**
  String get timelineMuteOriginal;

  /// No description provided for @panelTitle.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get panelTitle;

  /// No description provided for @panelNothingSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a clip on the timeline to edit it.'**
  String get panelNothingSelected;

  /// No description provided for @panelClip.
  ///
  /// In en, this message translates to:
  /// **'Clip'**
  String get panelClip;

  /// No description provided for @editorSplitOutside.
  ///
  /// In en, this message translates to:
  /// **'Move the playhead over the selected clip to split it.'**
  String get editorSplitOutside;

  /// A playback speed, e.g. 0.5× or 2×.
  ///
  /// In en, this message translates to:
  /// **'{value}×'**
  String speedValue(double value);

  /// No description provided for @speedKeepPitch.
  ///
  /// In en, this message translates to:
  /// **'Keep pitch'**
  String get speedKeepPitch;

  /// No description provided for @speedTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speedTypeTitle;

  /// No description provided for @speedTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Speed (0.1–10)'**
  String get speedTypeLabel;

  /// No description provided for @speedTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a speed from 0.1 to 10'**
  String get speedTypeInvalid;

  /// No description provided for @speedTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to type an exact speed'**
  String get speedTypeHint;

  /// No description provided for @speedTabNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get speedTabNormal;

  /// No description provided for @speedTabCurve.
  ///
  /// In en, this message translates to:
  /// **'Curve'**
  String get speedTabCurve;

  /// No description provided for @curveNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get curveNone;

  /// No description provided for @curveCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get curveCustom;

  /// No description provided for @curveMontage.
  ///
  /// In en, this message translates to:
  /// **'Montage'**
  String get curveMontage;

  /// No description provided for @curveHero.
  ///
  /// In en, this message translates to:
  /// **'Hero'**
  String get curveHero;

  /// No description provided for @curveBullet.
  ///
  /// In en, this message translates to:
  /// **'Bullet'**
  String get curveBullet;

  /// No description provided for @curveFlashIn.
  ///
  /// In en, this message translates to:
  /// **'Flash in'**
  String get curveFlashIn;

  /// No description provided for @curveFlashOut.
  ///
  /// In en, this message translates to:
  /// **'Flash out'**
  String get curveFlashOut;

  /// No description provided for @curveEditHint.
  ///
  /// In en, this message translates to:
  /// **'Tap again to edit the curve'**
  String get curveEditHint;

  /// No description provided for @curveGraph.
  ///
  /// In en, this message translates to:
  /// **'Speed curve. Drag a point to change the speed there.'**
  String get curveGraph;

  /// No description provided for @curveAddPoint.
  ///
  /// In en, this message translates to:
  /// **'Add point'**
  String get curveAddPoint;

  /// No description provided for @curveDeletePoint.
  ///
  /// In en, this message translates to:
  /// **'Delete point'**
  String get curveDeletePoint;

  /// No description provided for @curveBackToPresets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get curveBackToPresets;

  /// Crop preset without a locked aspect ratio.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get cropFree;

  /// A crop aspect preset, e.g. 16:9.
  ///
  /// In en, this message translates to:
  /// **'{width}:{height}'**
  String cropAspect(int width, int height);

  /// No description provided for @cropMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get cropMirror;

  /// No description provided for @cropFlip.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get cropFlip;

  /// No description provided for @cropRotate90.
  ///
  /// In en, this message translates to:
  /// **'Rotate 90°'**
  String get cropRotate90;

  /// No description provided for @cropRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get cropRotation;

  /// An angle in degrees, e.g. 45° or -12°.
  ///
  /// In en, this message translates to:
  /// **'{value}°'**
  String rotationValue(int value);

  /// No description provided for @rotationTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Degrees (−180 to 180)'**
  String get rotationTypeLabel;

  /// No description provided for @rotationTypeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an angle from −180 to 180'**
  String get rotationTypeInvalid;

  /// No description provided for @rotationTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to type an exact angle'**
  String get rotationTypeHint;

  /// No description provided for @cropOverlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Crop frame handles'**
  String get cropOverlayLabel;

  /// No description provided for @transformGizmoLabel.
  ///
  /// In en, this message translates to:
  /// **'Transform preview'**
  String get transformGizmoLabel;

  /// No description provided for @toolTransform.
  ///
  /// In en, this message translates to:
  /// **'Transform'**
  String get toolTransform;

  /// No description provided for @transformTabFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get transformTabFill;

  /// No description provided for @transformTabPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get transformTabPosition;

  /// No description provided for @transformTabOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get transformTabOpacity;

  /// No description provided for @transformTabBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get transformTabBorder;

  /// No description provided for @fitModeFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get fitModeFit;

  /// No description provided for @fitModeFill.
  ///
  /// In en, this message translates to:
  /// **'Fill'**
  String get fitModeFill;

  /// No description provided for @fitModeStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get fitModeStretch;

  /// No description provided for @transformX.
  ///
  /// In en, this message translates to:
  /// **'X'**
  String get transformX;

  /// No description provided for @transformY.
  ///
  /// In en, this message translates to:
  /// **'Y'**
  String get transformY;

  /// No description provided for @transformScale.
  ///
  /// In en, this message translates to:
  /// **'Scale'**
  String get transformScale;

  /// No description provided for @transformOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get transformOpacity;

  /// No description provided for @transformBorderWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get transformBorderWidth;

  /// No description provided for @transformBorderCorners.
  ///
  /// In en, this message translates to:
  /// **'Corners'**
  String get transformBorderCorners;

  /// No description provided for @transformBorderColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get transformBorderColor;

  /// A whole-number percentage, e.g. 100% or -50%.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue(int value);

  /// Allowed numeric range label in a type-to-edit dialog.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max}'**
  String valueRangeLabel(String min, String max);

  /// Validation error in a type-to-edit dialog.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from {min} to {max}'**
  String valueRangeInvalid(String min, String max);

  /// No description provided for @tapToTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to type an exact value'**
  String get tapToTypeHint;

  /// Accessible label for a color swatch.
  ///
  /// In en, this message translates to:
  /// **'Color {index}'**
  String colorSwatchLabel(int index);

  /// No description provided for @ratioTabRatio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get ratioTabRatio;

  /// No description provided for @ratioTabBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get ratioTabBackground;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get backgroundColor;

  /// No description provided for @backgroundGradient.
  ///
  /// In en, this message translates to:
  /// **'Gradient'**
  String get backgroundGradient;

  /// No description provided for @backgroundBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get backgroundBlur;

  /// No description provided for @backgroundImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get backgroundImage;

  /// No description provided for @backgroundAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get backgroundAngle;

  /// No description provided for @backgroundBlurAmount.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get backgroundBlurAmount;

  /// No description provided for @backgroundPickImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get backgroundPickImage;

  /// No description provided for @backgroundChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Change image'**
  String get backgroundChangeImage;

  /// Accessible label for a gradient swatch.
  ///
  /// In en, this message translates to:
  /// **'Gradient {index}'**
  String gradientSwatchLabel(int index);

  /// Tooltip for adding a keyframe on a property slider.
  ///
  /// In en, this message translates to:
  /// **'Add {property} keyframe'**
  String keyframeAdd(String property);

  /// Tooltip for removing a keyframe on a property slider.
  ///
  /// In en, this message translates to:
  /// **'Remove {property} keyframe'**
  String keyframeRemove(String property);

  /// No description provided for @filterCategoryFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get filterCategoryFilm;

  /// No description provided for @filterCategoryVibrant.
  ///
  /// In en, this message translates to:
  /// **'Vibrant'**
  String get filterCategoryVibrant;

  /// No description provided for @filterCategoryBw.
  ///
  /// In en, this message translates to:
  /// **'B&W'**
  String get filterCategoryBw;

  /// No description provided for @filterNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get filterNone;

  /// No description provided for @filterGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get filterGold;

  /// No description provided for @filterVelvia.
  ///
  /// In en, this message translates to:
  /// **'Velvia'**
  String get filterVelvia;

  /// No description provided for @filterVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get filterVintage;

  /// No description provided for @filterCinema.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get filterCinema;

  /// No description provided for @filterVivid.
  ///
  /// In en, this message translates to:
  /// **'Vivid'**
  String get filterVivid;

  /// No description provided for @filterSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get filterSunset;

  /// No description provided for @filterNordic.
  ///
  /// In en, this message translates to:
  /// **'Nordic'**
  String get filterNordic;

  /// No description provided for @filterPastel.
  ///
  /// In en, this message translates to:
  /// **'Pastel'**
  String get filterPastel;

  /// No description provided for @filterNoir.
  ///
  /// In en, this message translates to:
  /// **'Noir'**
  String get filterNoir;

  /// No description provided for @filterSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get filterSilver;

  /// No description provided for @filterSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get filterSepia;

  /// No description provided for @filterMatte.
  ///
  /// In en, this message translates to:
  /// **'Matte'**
  String get filterMatte;

  /// No description provided for @filterIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get filterIntensity;

  /// No description provided for @adjustExposure.
  ///
  /// In en, this message translates to:
  /// **'Exposure'**
  String get adjustExposure;

  /// No description provided for @adjustBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get adjustBrightness;

  /// No description provided for @adjustContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get adjustContrast;

  /// No description provided for @adjustSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get adjustSaturation;

  /// No description provided for @adjustWarmth.
  ///
  /// In en, this message translates to:
  /// **'Warmth'**
  String get adjustWarmth;

  /// No description provided for @adjustTint.
  ///
  /// In en, this message translates to:
  /// **'Tint'**
  String get adjustTint;

  /// No description provided for @adjustHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get adjustHighlights;

  /// No description provided for @adjustShadows.
  ///
  /// In en, this message translates to:
  /// **'Shadows'**
  String get adjustShadows;

  /// No description provided for @adjustSharpen.
  ///
  /// In en, this message translates to:
  /// **'Sharpen'**
  String get adjustSharpen;

  /// No description provided for @adjustVignette.
  ///
  /// In en, this message translates to:
  /// **'Vignette'**
  String get adjustVignette;

  /// Tooltip for resetting a single adjustment slider to zero.
  ///
  /// In en, this message translates to:
  /// **'Reset {field}'**
  String adjustResetField(String field);

  /// No description provided for @toolBlur.
  ///
  /// In en, this message translates to:
  /// **'Blur'**
  String get toolBlur;

  /// No description provided for @toolMask.
  ///
  /// In en, this message translates to:
  /// **'Mask'**
  String get toolMask;

  /// No description provided for @blurStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get blurStrength;

  /// No description provided for @maskNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get maskNone;

  /// No description provided for @maskLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get maskLinear;

  /// No description provided for @maskMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get maskMirror;

  /// No description provided for @maskCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get maskCircle;

  /// No description provided for @maskRect.
  ///
  /// In en, this message translates to:
  /// **'Rectangle'**
  String get maskRect;

  /// No description provided for @maskHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get maskHeart;

  /// No description provided for @maskStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get maskStar;

  /// No description provided for @maskFeather.
  ///
  /// In en, this message translates to:
  /// **'Feather'**
  String get maskFeather;

  /// No description provided for @maskRotation.
  ///
  /// In en, this message translates to:
  /// **'Rotation'**
  String get maskRotation;

  /// No description provided for @maskSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get maskSize;

  /// No description provided for @maskInvert.
  ///
  /// In en, this message translates to:
  /// **'Invert'**
  String get maskInvert;

  /// No description provided for @maskPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get maskPosition;

  /// No description provided for @maskOverlayLabel.
  ///
  /// In en, this message translates to:
  /// **'Mask handles'**
  String get maskOverlayLabel;
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

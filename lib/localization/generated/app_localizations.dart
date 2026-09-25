import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QARI | Qari'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Read it. Understand it. Continue it.'**
  String get appTagline;

  /// No description provided for @splashLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting ready...'**
  String get splashLoading;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Qari'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read your files in your favorite language and enjoy a smart reading experience.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything in one app'**
  String get welcomeFeaturesTitle;

  /// No description provided for @featureRead.
  ///
  /// In en, this message translates to:
  /// **'Read any file format'**
  String get featureRead;

  /// No description provided for @featureTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate instantly'**
  String get featureTranslate;

  /// No description provided for @featureSummarize.
  ///
  /// In en, this message translates to:
  /// **'AI summaries'**
  String get featureSummarize;

  /// No description provided for @featureListen.
  ///
  /// In en, this message translates to:
  /// **'Listen anytime'**
  String get featureListen;

  /// No description provided for @featureOffline.
  ///
  /// In en, this message translates to:
  /// **'Works offline'**
  String get featureOffline;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @welcomeLegalHint.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to our Terms & Privacy Policy.'**
  String get welcomeLegalHint;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonErrorTitle;

  /// No description provided for @commonErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again. If the problem persists, contact support.'**
  String get commonErrorBody;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @featureUnderConstruction.
  ///
  /// In en, this message translates to:
  /// **'This feature arrives in a later phase.'**
  String get featureUnderConstruction;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get homeGreeting;

  /// No description provided for @homeGreetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to read?'**
  String get homeGreetingSubtitle;

  /// No description provided for @homeQuickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get homeQuickActions;

  /// No description provided for @homeAddFile.
  ///
  /// In en, this message translates to:
  /// **'Add file'**
  String get homeAddFile;

  /// No description provided for @homeAddFileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import PDF, DOCX, EPUB and more'**
  String get homeAddFileSubtitle;

  /// No description provided for @homeContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get homeContinueReading;

  /// No description provided for @homeContinueReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get homeContinueReadingSubtitle;

  /// No description provided for @homeRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'Recent files'**
  String get homeRecentFiles;

  /// No description provided for @homeNoRecentFiles.
  ///
  /// In en, this message translates to:
  /// **'No recent files yet. Your latest reads will appear here.'**
  String get homeNoRecentFiles;

  /// No description provided for @homeAddFirstFile.
  ///
  /// In en, this message translates to:
  /// **'Add your first file'**
  String get homeAddFirstFile;

  /// No description provided for @homeLastRead.
  ///
  /// In en, this message translates to:
  /// **'Last read'**
  String get homeLastRead;

  /// No description provided for @homeLastReadEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been read yet'**
  String get homeLastReadEmpty;

  /// No description provided for @homeLibrary.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get homeLibrary;

  /// No description provided for @homeLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'All your files in one place'**
  String get homeLibrarySubtitle;

  /// No description provided for @homeLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty. Add your first file.'**
  String get homeLibraryEmpty;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeViewAll;

  /// No description provided for @featurePhasePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'This feature arrives in a later phase.'**
  String get featurePhasePlaceholder;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library'**
  String get libraryTitle;

  /// No description provided for @librarySearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get librarySearch;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your library is empty'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Import your first file to start reading.'**
  String get libraryEmptySubtitle;

  /// No description provided for @libraryImportFile.
  ///
  /// In en, this message translates to:
  /// **'Import a file'**
  String get libraryImportFile;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get settingsLanguageArabic;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @settingsInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get settingsInformation;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get settingsTerms;

  /// No description provided for @settingsHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelpSupport;

  /// No description provided for @settingsAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get settingsAboutUs;

  /// No description provided for @settingsClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear local data'**
  String get settingsClearData;

  /// No description provided for @settingsClearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear all local data?'**
  String get settingsClearDataConfirm;

  /// No description provided for @settingsClearDataDone.
  ///
  /// In en, this message translates to:
  /// **'Local data cleared.'**
  String get settingsClearDataDone;

  /// No description provided for @settingsResetTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsResetTheme;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About QARI | Qari'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'A smart multilingual file reader. Read it. Understand it. Continue it.'**
  String get aboutDescription;

  /// No description provided for @aboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersionLabel;

  /// No description provided for @infoPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get infoPrivacyTitle;

  /// No description provided for @infoPrivacyBody1.
  ///
  /// In en, this message translates to:
  /// **'QARI is designed to respect your privacy. Your documents and reading data stay on your device by default.'**
  String get infoPrivacyBody1;

  /// No description provided for @infoPrivacyBody2.
  ///
  /// In en, this message translates to:
  /// **'When you enable syncing, data is backed up securely and is never shared with third parties. You can delete your data at any time.'**
  String get infoPrivacyBody2;

  /// No description provided for @infoTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get infoTermsTitle;

  /// No description provided for @infoTermsBody1.
  ///
  /// In en, this message translates to:
  /// **'By using QARI you agree to use the app for lawful personal purposes and to respect the rights of content owners.'**
  String get infoTermsBody1;

  /// No description provided for @infoTermsBody2.
  ///
  /// In en, this message translates to:
  /// **'The AI, translation and text-to-speech features are provided as-is for personal use.'**
  String get infoTermsBody2;

  /// No description provided for @infoHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get infoHelpTitle;

  /// No description provided for @infoHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Need a hand? Import your file from the Home screen, then open it in Library. Contact support through the app store listing.'**
  String get infoHelpBody;

  /// No description provided for @infoAboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get infoAboutUsTitle;

  /// No description provided for @infoAboutUsBody.
  ///
  /// In en, this message translates to:
  /// **'QARI is built by a small team passionate about reading, languages and intelligent tools that let you read anything, anywhere.'**
  String get infoAboutUsBody;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again later.'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection and retry.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials. Please try again.'**
  String get authErrorInvalidCredential;

  /// No description provided for @authErrorAccountExistsDifferent.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with a different sign-in method.'**
  String get authErrorAccountExistsDifferent;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is not enabled yet.'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorGoogleCancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled.'**
  String get authErrorGoogleCancelled;

  /// No description provided for @authErrorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get authErrorGoogleFailed;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

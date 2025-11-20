import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Chamak'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountSecurity;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @preferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get preferNotToSay;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterYourName;

  /// No description provided for @enterYourAge.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get enterYourAge;

  /// No description provided for @enterYourCity.
  ///
  /// In en, this message translates to:
  /// **'Enter your city'**
  String get enterYourCity;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get tellUsAboutYourself;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Picture'**
  String get changeProfilePicture;

  /// No description provided for @openCamera.
  ///
  /// In en, this message translates to:
  /// **'Open Camera'**
  String get openCamera;

  /// No description provided for @openGallery.
  ///
  /// In en, this message translates to:
  /// **'Open Gallery'**
  String get openGallery;

  /// No description provided for @takeANewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a new photo'**
  String get takeANewPhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @detect.
  ///
  /// In en, this message translates to:
  /// **'Detect'**
  String get detect;

  /// No description provided for @detecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detecting;

  /// No description provided for @yourCityWillBeAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'Your city will be auto-detected'**
  String get yourCityWillBeAutoDetected;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @locationDetected.
  ///
  /// In en, this message translates to:
  /// **'Location detected'**
  String get locationDetected;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable - Please enter manually'**
  String get locationUnavailable;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get locationPermissionNeeded;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Enable location services'**
  String get enableLocationServices;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHosts.
  ///
  /// In en, this message translates to:
  /// **'Search hosts...'**
  String get searchHosts;

  /// No description provided for @searchLiveStreams.
  ///
  /// In en, this message translates to:
  /// **'Search live streams...'**
  String get searchLiveStreams;

  /// No description provided for @searchForHosts.
  ///
  /// In en, this message translates to:
  /// **'Search for hosts'**
  String get searchForHosts;

  /// No description provided for @searchForLiveStreams.
  ///
  /// In en, this message translates to:
  /// **'Search for live streams'**
  String get searchForLiveStreams;

  /// No description provided for @startTypingToFind.
  ///
  /// In en, this message translates to:
  /// **'Start typing to find what you\'re looking for'**
  String get startTypingToFind;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryDifferentKeywords.
  ///
  /// In en, this message translates to:
  /// **'Try searching with different keywords'**
  String get tryDifferentKeywords;

  /// No description provided for @balanceRechargeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Balance, Recharge'**
  String get balanceRechargeWithdrawal;

  /// No description provided for @chatInbox.
  ///
  /// In en, this message translates to:
  /// **'Chat & Inbox'**
  String get chatInbox;

  /// No description provided for @yourProgressAchievements.
  ///
  /// In en, this message translates to:
  /// **'Your progress & achievements'**
  String get yourProgressAchievements;

  /// No description provided for @phonePasswordAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Phone, Password, Account Settings'**
  String get phonePasswordAccountSettings;

  /// No description provided for @getHelpReportIssues.
  ///
  /// In en, this message translates to:
  /// **'Get help & report issues'**
  String get getHelpReportIssues;

  /// No description provided for @appPreferencesPrivacyTerms.
  ///
  /// In en, this message translates to:
  /// **'App preferences, Privacy & Terms'**
  String get appPreferencesPrivacyTerms;

  /// No description provided for @followersListComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Followers list coming soon!'**
  String get followersListComingSoon;

  /// No description provided for @followingListComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Following list coming soon!'**
  String get followingListComingSoon;

  /// No description provided for @idCopied.
  ///
  /// In en, this message translates to:
  /// **'ID {id} copied to clipboard!'**
  String idCopied(String id);

  /// No description provided for @setYourName.
  ///
  /// In en, this message translates to:
  /// **'Set your name'**
  String get setYourName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameRequired;

  /// No description provided for @ageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age'**
  String get ageRequired;

  /// No description provided for @validAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid age (13-100)'**
  String get validAge;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @bioMaxLength.
  ///
  /// In en, this message translates to:
  /// **'Bio must be less than 500 characters'**
  String get bioMaxLength;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @aboutUs.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUs;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @thankYouForFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouForFeedback;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @writeFeedbackHere.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback here...'**
  String get writeFeedbackHere;

  /// No description provided for @valueFeedbackMessage.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback! Please share your thoughts or report any issues.'**
  String get valueFeedbackMessage;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @writeYourConcernHere.
  ///
  /// In en, this message translates to:
  /// **'Write your concern here'**
  String get writeYourConcernHere;

  /// No description provided for @describeYourIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue in detail...'**
  String get describeYourIssue;

  /// No description provided for @pleaseDescribeConcern.
  ///
  /// In en, this message translates to:
  /// **'Please describe your concern'**
  String get pleaseDescribeConcern;

  /// No description provided for @provideMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide more details (at least 10 characters)'**
  String get provideMoreDetails;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @concernSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your concern has been submitted successfully!'**
  String get concernSubmittedSuccessfully;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @newFollowers.
  ///
  /// In en, this message translates to:
  /// **'New Followers'**
  String get newFollowers;

  /// No description provided for @likeAndFavourite.
  ///
  /// In en, this message translates to:
  /// **'Like and Favourite'**
  String get likeAndFavourite;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @kycVerification.
  ///
  /// In en, this message translates to:
  /// **'KYC Verification'**
  String get kycVerification;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch Account'**
  String get switchAccount;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @idCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'ID copied to clipboard'**
  String get idCopiedToClipboard;

  /// No description provided for @updatePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Update Phone Number'**
  String get updatePhoneNumber;

  /// No description provided for @enterNewPhoneNumberDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your new phone number to update your account details.'**
  String get enterNewPhoneNumberDescription;

  /// No description provided for @enterNewPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter new phone number'**
  String get enterNewPhoneNumber;

  /// No description provided for @sendOTP.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOTP;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseEnterValidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get pleaseEnterValidPhoneNumber;

  /// No description provided for @pleaseEnterYourMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your mobile number'**
  String get pleaseEnterYourMobileNumber;

  /// No description provided for @pleaseEnterValidMobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid mobile number'**
  String get pleaseEnterValidMobileNumber;

  /// No description provided for @pleaseEnterCompleteOTP.
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete OTP'**
  String get pleaseEnterCompleteOTP;

  /// No description provided for @otpSentToNewNumber.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to new number'**
  String get otpSentToNewNumber;

  /// No description provided for @completeKYCDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete your KYC verification to unlock additional features and increase your account limits.'**
  String get completeKYCDescription;

  /// No description provided for @enhancedSecurity.
  ///
  /// In en, this message translates to:
  /// **'Enhanced security'**
  String get enhancedSecurity;

  /// No description provided for @higherTransactionLimits.
  ///
  /// In en, this message translates to:
  /// **'Higher transaction limits'**
  String get higherTransactionLimits;

  /// No description provided for @verifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified badge'**
  String get verifiedBadge;

  /// No description provided for @startVerification.
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get startVerification;

  /// No description provided for @kycVerificationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'KYC verification coming soon!'**
  String get kycVerificationComingSoon;

  /// No description provided for @switchAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout and switch to a different account?'**
  String get switchAccountConfirmation;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent and cannot be undone. All your data will be deleted.'**
  String get deleteAccountWarning;

  /// No description provided for @typeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"DELETE\" to confirm:'**
  String get typeDeleteToConfirm;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @pleaseTypeDeleteToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Please type DELETE to confirm'**
  String get pleaseTypeDeleteToConfirm;

  /// No description provided for @accountDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// No description provided for @myEarning.
  ///
  /// In en, this message translates to:
  /// **'My Earning'**
  String get myEarning;

  /// No description provided for @earningsWithdrawals.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Withdrawals'**
  String get earningsWithdrawals;

  /// No description provided for @totalEarning.
  ///
  /// In en, this message translates to:
  /// **'Total Earning'**
  String get totalEarning;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @withdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get withdrawn;

  /// No description provided for @withdrawMoney.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Money'**
  String get withdrawMoney;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @upiId.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiId;

  /// No description provided for @enterUpiId.
  ///
  /// In en, this message translates to:
  /// **'Enter UPI ID (e.g. name@upi)'**
  String get enterUpiId;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter valid amount'**
  String get enterValidAmount;

  /// No description provided for @minimumWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal:'**
  String get minimumWithdrawal;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get insufficientBalance;

  /// No description provided for @pleaseEnterUpiId.
  ///
  /// In en, this message translates to:
  /// **'Please enter UPI ID'**
  String get pleaseEnterUpiId;

  /// No description provided for @enterValidUpiId.
  ///
  /// In en, this message translates to:
  /// **'Enter valid UPI ID (e.g. name@upi)'**
  String get enterValidUpiId;

  /// No description provided for @withdrawalRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal request submitted!'**
  String get withdrawalRequestSubmitted;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get withdrawal;

  /// No description provided for @earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get earnings;

  /// No description provided for @withdrawalMethod.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Method'**
  String get withdrawalMethod;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @crypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get crypto;

  /// No description provided for @accountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get accountHolderName;

  /// No description provided for @enterAccountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Enter account holder name'**
  String get enterAccountHolderName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @enterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter account number'**
  String get enterAccountNumber;

  /// No description provided for @ifscCode.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get ifscCode;

  /// No description provided for @enterIfscCode.
  ///
  /// In en, this message translates to:
  /// **'Enter IFSC code'**
  String get enterIfscCode;

  /// No description provided for @walletAddress.
  ///
  /// In en, this message translates to:
  /// **'Wallet Address'**
  String get walletAddress;

  /// No description provided for @enterWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter crypto wallet address'**
  String get enterWalletAddress;

  /// No description provided for @pleaseEnterAccountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Please enter account holder name'**
  String get pleaseEnterAccountHolderName;

  /// No description provided for @pleaseEnterAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter account number'**
  String get pleaseEnterAccountNumber;

  /// No description provided for @enterValidAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter valid account number (9-18 digits)'**
  String get enterValidAccountNumber;

  /// No description provided for @pleaseEnterIfscCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter IFSC code'**
  String get pleaseEnterIfscCode;

  /// No description provided for @enterValidIfscCode.
  ///
  /// In en, this message translates to:
  /// **'Enter valid IFSC code (11 characters)'**
  String get enterValidIfscCode;

  /// No description provided for @pleaseEnterWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter wallet address'**
  String get pleaseEnterWalletAddress;

  /// No description provided for @enterValidWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter valid wallet address (min 26 characters)'**
  String get enterValidWalletAddress;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @viewWarningsGuidelines.
  ///
  /// In en, this message translates to:
  /// **'View warnings & community guidelines'**
  String get viewWarningsGuidelines;

  /// No description provided for @warningForPermanentBlock.
  ///
  /// In en, this message translates to:
  /// **'Warning for permanent block'**
  String get warningForPermanentBlock;

  /// No description provided for @currentWarnings.
  ///
  /// In en, this message translates to:
  /// **'Current warnings'**
  String get currentWarnings;

  /// No description provided for @greatNoWarnings.
  ///
  /// In en, this message translates to:
  /// **'Great! You have no warnings'**
  String get greatNoWarnings;

  /// No description provided for @followCommunityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Please follow community guidelines'**
  String get followCommunityGuidelines;

  /// No description provided for @riskOfPermanentBlock.
  ///
  /// In en, this message translates to:
  /// **'Warning: Risk of permanent block!'**
  String get riskOfPermanentBlock;

  /// No description provided for @toAvoidWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings से बचने के लिए'**
  String get toAvoidWarnings;

  /// No description provided for @rule01Hindi.
  ///
  /// In en, this message translates to:
  /// **'सभी लोग से Respect से बात करें'**
  String get rule01Hindi;

  /// No description provided for @rule01English.
  ///
  /// In en, this message translates to:
  /// **'Talk to everyone with respect'**
  String get rule01English;

  /// No description provided for @rule02Hindi.
  ///
  /// In en, this message translates to:
  /// **'किसी से भी Instagram और WhatsApp details ना मांगे'**
  String get rule02Hindi;

  /// No description provided for @rule02English.
  ///
  /// In en, this message translates to:
  /// **'Do not ask anyone for Instagram or WhatsApp details'**
  String get rule02English;

  /// No description provided for @rule03Hindi.
  ///
  /// In en, this message translates to:
  /// **'गन्दी भाषा का उपयोग ना करें और विनम्र रहे'**
  String get rule03Hindi;

  /// No description provided for @rule03English.
  ///
  /// In en, this message translates to:
  /// **'Do not use abusive language and be polite'**
  String get rule03English;

  /// No description provided for @rule04Hindi.
  ///
  /// In en, this message translates to:
  /// **'किसी को भी गलत report ना करें'**
  String get rule04Hindi;

  /// No description provided for @rule04English.
  ///
  /// In en, this message translates to:
  /// **'Do not falsely report anyone'**
  String get rule04English;

  /// No description provided for @helpAndFeedback.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get helpAndFeedback;

  /// No description provided for @faqsCommonIssues.
  ///
  /// In en, this message translates to:
  /// **'FAQs, common issues & solutions'**
  String get faqsCommonIssues;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @howToRechargeCoins.
  ///
  /// In en, this message translates to:
  /// **'How to recharge coins?'**
  String get howToRechargeCoins;

  /// No description provided for @rechargeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Wallet → Flat Recharge → Select a package → Pay via UPI/Card. Coins will be credited instantly.'**
  String get rechargeAnswer;

  /// No description provided for @howToWithdrawEarnings.
  ///
  /// In en, this message translates to:
  /// **'How to withdraw earnings?'**
  String get howToWithdrawEarnings;

  /// No description provided for @withdrawAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to My Earning → Enter amount → Choose payment method → Submit request. It will be processed in 2-3 business days.'**
  String get withdrawAnswer;

  /// No description provided for @whatIsLevelSystem.
  ///
  /// In en, this message translates to:
  /// **'What is the level system?'**
  String get whatIsLevelSystem;

  /// No description provided for @levelAnswer.
  ///
  /// In en, this message translates to:
  /// **'You earn XP by being active on the app. As you collect more XP, your level increases, unlocking new features and rewards.'**
  String get levelAnswer;

  /// No description provided for @howToContactSupport.
  ///
  /// In en, this message translates to:
  /// **'How to contact support?'**
  String get howToContactSupport;

  /// No description provided for @contactAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap on Contact Support from Settings or Profile. You can chat with our team or submit your issue via form.'**
  String get contactAnswer;

  /// No description provided for @cannotFindAnswer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your answer?'**
  String get cannotFindAnswer;

  /// No description provided for @contactSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact our support team for personalized help'**
  String get contactSupportTeam;

  /// No description provided for @hereToHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help!'**
  String get hereToHelp;

  /// No description provided for @findAnswersCommon.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions'**
  String get findAnswersCommon;

  /// No description provided for @stillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get stillNeedHelp;

  /// No description provided for @supportTeamHereForYou.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here for you'**
  String get supportTeamHereForYou;

  /// No description provided for @faqUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile?'**
  String get faqUpdateProfile;

  /// No description provided for @faqUpdateProfileAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile tab, tap the edit icon on your profile picture. You can update your name, age, gender, language, location, bio, and add cover photos.'**
  String get faqUpdateProfileAnswer;

  /// No description provided for @faqRechargeWallet.
  ///
  /// In en, this message translates to:
  /// **'How can I recharge my wallet?'**
  String get faqRechargeWallet;

  /// No description provided for @faqRechargeWalletAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open Wallet from Profile menu, choose between Flat Recharge or Reseller options. Select your package and complete payment via Google Play.'**
  String get faqRechargeWalletAnswer;

  /// No description provided for @faqSendMessages.
  ///
  /// In en, this message translates to:
  /// **'How do I send messages?'**
  String get faqSendMessages;

  /// No description provided for @faqSendMessagesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Search for a user, open their profile, and tap the Message button. You can also access all your chats from the Messages menu in your profile.'**
  String get faqSendMessagesAnswer;

  /// No description provided for @faqFollowers.
  ///
  /// In en, this message translates to:
  /// **'What are Followers and Following?'**
  String get faqFollowers;

  /// No description provided for @faqFollowersAnswer.
  ///
  /// In en, this message translates to:
  /// **'Followers are users who follow you. Following shows users you follow. You can see these counts on your profile and other user profiles.'**
  String get faqFollowersAnswer;

  /// No description provided for @faqLevelSystem.
  ///
  /// In en, this message translates to:
  /// **'How does the Level system work?'**
  String get faqLevelSystem;

  /// No description provided for @faqLevelSystemAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your level increases as you use the app. Higher levels unlock special features and badges. Tap on Level in your profile to see details.'**
  String get faqLevelSystemAnswer;

  /// No description provided for @faqChangePhone.
  ///
  /// In en, this message translates to:
  /// **'How do I change my phone number?'**
  String get faqChangePhone;

  /// No description provided for @faqChangePhoneAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Account & Security → Update Phone Number. Enter your new number and verify with OTP.'**
  String get faqChangePhoneAnswer;

  /// No description provided for @faqWithdrawEarnings.
  ///
  /// In en, this message translates to:
  /// **'How can I withdraw my earnings?'**
  String get faqWithdrawEarnings;

  /// No description provided for @faqWithdrawEarningsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open My Earning from Profile menu. Enter withdrawal amount, provide your UPI ID or bank details, and submit. Minimum withdrawal is ₹50.'**
  String get faqWithdrawEarningsAnswer;

  /// No description provided for @faqDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'How do I delete my account?'**
  String get faqDeleteAccount;

  /// No description provided for @faqDeleteAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Account & Security → Delete Account. Type DELETE to confirm. This action is permanent and cannot be undone.'**
  String get faqDeleteAccountAnswer;

  /// No description provided for @faqEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'How to enable notifications?'**
  String get faqEnableNotifications;

  /// No description provided for @faqEnableNotificationsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile → Settings → Notification Settings. Enable the types of notifications you want to receive.'**
  String get faqEnableNotificationsAnswer;

  /// No description provided for @faqAppNotWorking.
  ///
  /// In en, this message translates to:
  /// **'App is not working properly, what to do?'**
  String get faqAppNotWorking;

  /// No description provided for @faqAppNotWorkingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Try these steps: 1) Clear app cache, 2) Update to latest version, 3) Restart your device, 4) If issue persists, contact support.'**
  String get faqAppNotWorkingAnswer;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @eventsAndAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Events & Announcements'**
  String get eventsAndAnnouncements;

  /// No description provided for @upcomingEventsPosters.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events & posters'**
  String get upcomingEventsPosters;

  /// No description provided for @stayUpdated.
  ///
  /// In en, this message translates to:
  /// **'Stay Updated!'**
  String get stayUpdated;

  /// No description provided for @checkLatestEvents.
  ///
  /// In en, this message translates to:
  /// **'Check latest events & announcements'**
  String get checkLatestEvents;

  /// No description provided for @upcomingEvents.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get upcomingEvents;

  /// No description provided for @event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get event;

  /// No description provided for @announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get announcement;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @moreEventsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'More events coming soon!'**
  String get moreEventsComingSoon;

  /// No description provided for @checkBackRegularly.
  ///
  /// In en, this message translates to:
  /// **'Check back regularly for new updates'**
  String get checkBackRegularly;

  /// No description provided for @errorLoadingStreams.
  ///
  /// In en, this message translates to:
  /// **'Error loading streams'**
  String get errorLoadingStreams;

  /// No description provided for @noLiveStreamsAtMoment.
  ///
  /// In en, this message translates to:
  /// **'No live streams at the moment'**
  String get noLiveStreamsAtMoment;

  /// No description provided for @beFirstToGoLive.
  ///
  /// In en, this message translates to:
  /// **'Be the first to go live!'**
  String get beFirstToGoLive;

  /// No description provided for @liveStreamingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Live streaming feature coming soon!'**
  String get liveStreamingComingSoon;

  /// No description provided for @liveLabel.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get liveLabel;

  /// No description provided for @connectingToLiveStream.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}\'s live stream...'**
  String connectingToLiveStream(String name);

  /// No description provided for @startYourLiveStream.
  ///
  /// In en, this message translates to:
  /// **'Start Your Live Stream'**
  String get startYourLiveStream;

  /// No description provided for @shareYourMoments.
  ///
  /// In en, this message translates to:
  /// **'Share your moments with your followers\nand connect with them live!'**
  String get shareYourMoments;

  /// No description provided for @goLiveNow.
  ///
  /// In en, this message translates to:
  /// **'Go Live Now'**
  String get goLiveNow;

  /// No description provided for @me.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get me;

  /// No description provided for @sampleEvent1Title.
  ///
  /// In en, this message translates to:
  /// **'Weekly Contest'**
  String get sampleEvent1Title;

  /// No description provided for @sampleEvent1Desc.
  ///
  /// In en, this message translates to:
  /// **'Win exciting prizes! Top 10 users will get rewards worth ₹10,000'**
  String get sampleEvent1Desc;

  /// No description provided for @sampleEvent2Title.
  ///
  /// In en, this message translates to:
  /// **'Mega Live Competition'**
  String get sampleEvent2Title;

  /// No description provided for @sampleEvent2Desc.
  ///
  /// In en, this message translates to:
  /// **'Join the biggest live streaming competition of the month'**
  String get sampleEvent2Desc;

  /// No description provided for @sampleEvent3Title.
  ///
  /// In en, this message translates to:
  /// **'Talent Show'**
  String get sampleEvent3Title;

  /// No description provided for @sampleEvent3Desc.
  ///
  /// In en, this message translates to:
  /// **'Showcase your talent and win amazing gifts'**
  String get sampleEvent3Desc;

  /// No description provided for @sampleAnnouncement1Title.
  ///
  /// In en, this message translates to:
  /// **'New Feature Launch 🎉'**
  String get sampleAnnouncement1Title;

  /// No description provided for @sampleAnnouncement1Desc.
  ///
  /// In en, this message translates to:
  /// **'Introducing video calls! Stay connected with your friends in real-time.'**
  String get sampleAnnouncement1Desc;

  /// No description provided for @sampleAnnouncement2Title.
  ///
  /// In en, this message translates to:
  /// **'App Update v2.0'**
  String get sampleAnnouncement2Title;

  /// No description provided for @sampleAnnouncement2Desc.
  ///
  /// In en, this message translates to:
  /// **'Enhanced performance, new UI, and bug fixes for better experience.'**
  String get sampleAnnouncement2Desc;

  /// No description provided for @sampleAnnouncement3Title.
  ///
  /// In en, this message translates to:
  /// **'Holiday Special Offer'**
  String get sampleAnnouncement3Title;

  /// No description provided for @sampleAnnouncement3Desc.
  ///
  /// In en, this message translates to:
  /// **'Get 50% extra coins on all recharges during the holiday season!'**
  String get sampleAnnouncement3Desc;

  /// No description provided for @liveNow.
  ///
  /// In en, this message translates to:
  /// **'Live Now'**
  String get liveNow;

  /// No description provided for @released.
  ///
  /// In en, this message translates to:
  /// **'Released'**
  String get released;

  /// No description provided for @comingSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoonLabel;

  /// No description provided for @followingTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Following Tab'**
  String get followingTabTitle;

  /// No description provided for @followingTabDescription.
  ///
  /// In en, this message translates to:
  /// **'See live streams from hosts you follow.\nStay connected with your favorite creators!'**
  String get followingTabDescription;

  /// No description provided for @followingFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon! Follow system will be available in the next update.'**
  String get followingFeatureComingSoon;

  /// No description provided for @newHosts.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newHosts;

  /// No description provided for @newlyJoinedHosts.
  ///
  /// In en, this message translates to:
  /// **'Newly Joined Hosts'**
  String get newlyJoinedHosts;

  /// No description provided for @discoverNewTalent.
  ///
  /// In en, this message translates to:
  /// **'Discover fresh talent on the platform'**
  String get discoverNewTalent;

  /// No description provided for @joinedToday.
  ///
  /// In en, this message translates to:
  /// **'Joined today'**
  String get joinedToday;

  /// No description provided for @joinedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Joined {days} days ago'**
  String joinedDaysAgo(String days);

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy Now'**
  String get buyNow;

  /// No description provided for @myBalance.
  ///
  /// In en, this message translates to:
  /// **'My Balance'**
  String get myBalance;

  /// No description provided for @availableCoins.
  ///
  /// In en, this message translates to:
  /// **'Available Coins'**
  String get availableCoins;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @withdrawEarnings.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Earnings'**
  String get withdrawEarnings;

  /// No description provided for @depositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit Amount'**
  String get depositAmount;

  /// No description provided for @flatRecharge.
  ///
  /// In en, this message translates to:
  /// **'Flat Recharge'**
  String get flatRecharge;

  /// No description provided for @reseller.
  ///
  /// In en, this message translates to:
  /// **'Reseller'**
  String get reseller;

  /// No description provided for @save20Percent.
  ///
  /// In en, this message translates to:
  /// **'SAVE 20%'**
  String get save20Percent;

  /// No description provided for @getBestDeals.
  ///
  /// In en, this message translates to:
  /// **'💰 Get Best Deals!'**
  String get getBestDeals;

  /// No description provided for @saveUpTo20Percent.
  ///
  /// In en, this message translates to:
  /// **'Save up to 20% with trusted resellers'**
  String get saveUpTo20Percent;

  /// No description provided for @best.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get best;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @satisfaction.
  ///
  /// In en, this message translates to:
  /// **'Satisfaction'**
  String get satisfaction;

  /// No description provided for @guaranteed.
  ///
  /// In en, this message translates to:
  /// **'Guaranteed'**
  String get guaranteed;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @protected.
  ///
  /// In en, this message translates to:
  /// **'Protected'**
  String get protected;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @paymentViaGooglePlay.
  ///
  /// In en, this message translates to:
  /// **'Payment via Google Play'**
  String get paymentViaGooglePlay;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @withdrawEarningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Earnings'**
  String get withdrawEarningsTitle;

  /// No description provided for @withdrawalAmountINR.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal Amount (INR)'**
  String get withdrawalAmountINR;

  /// No description provided for @minimumWithdrawal50.
  ///
  /// In en, this message translates to:
  /// **'Minimum withdrawal: ₹50'**
  String get minimumWithdrawal50;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @rechargeSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Recharge successful!'**
  String get rechargeSuccessful;

  /// No description provided for @startingChatWith.
  ///
  /// In en, this message translates to:
  /// **'Starting chat with {name}...'**
  String startingChatWith(String name);

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select Country'**
  String get selectCountry;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'HOST'**
  String get host;

  /// No description provided for @inr.
  ///
  /// In en, this message translates to:
  /// **'INR'**
  String get inr;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @rechargeWithConfidence.
  ///
  /// In en, this message translates to:
  /// **'Recharge with confidence — your money is always secure.'**
  String get rechargeWithConfidence;

  /// No description provided for @fastSafeTrusted.
  ///
  /// In en, this message translates to:
  /// **'Fast, safe, and trusted — every recharge is protected.'**
  String get fastSafeTrusted;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @discoverLocalContent.
  ///
  /// In en, this message translates to:
  /// **'Discover local content'**
  String get discoverLocalContent;

  /// No description provided for @findNearbyHosts.
  ///
  /// In en, this message translates to:
  /// **'Find nearby hosts'**
  String get findNearbyHosts;

  /// No description provided for @yourDataStaysPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your data stays private'**
  String get yourDataStaysPrivate;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @pleaseLoginToStartLiveStream.
  ///
  /// In en, this message translates to:
  /// **'Please login to start a live stream'**
  String get pleaseLoginToStartLiveStream;

  /// No description provided for @liveStream.
  ///
  /// In en, this message translates to:
  /// **'Live Stream'**
  String get liveStream;

  /// No description provided for @announcementPanel.
  ///
  /// In en, this message translates to:
  /// **'Announcement Panel'**
  String get announcementPanel;

  /// No description provided for @errorLoadingEvents.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get errorLoadingEvents;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No Events Yet'**
  String get noEventsYet;

  /// No description provided for @eventsFromAdminWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Events from admin will appear here'**
  String get eventsFromAdminWillAppear;

  /// No description provided for @errorLoadingAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Error loading announcements'**
  String get errorLoadingAnnouncements;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No Announcements Yet'**
  String get noAnnouncementsYet;

  /// No description provided for @announcementsFromAdminWillAppear.
  ///
  /// In en, this message translates to:
  /// **'Announcements from admin will appear here'**
  String get announcementsFromAdminWillAppear;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noAnnouncementsToShow.
  ///
  /// In en, this message translates to:
  /// **'No announcements to show'**
  String get noAnnouncementsToShow;

  /// No description provided for @announcementDismissed.
  ///
  /// In en, this message translates to:
  /// **'Announcement dismissed'**
  String get announcementDismissed;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @transactionHistoryComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Transaction History coming soon!'**
  String get transactionHistoryComingSoon;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorLoadingProfile;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @errorLoadingTransactions.
  ///
  /// In en, this message translates to:
  /// **'Error loading transactions'**
  String get errorLoadingTransactions;

  /// No description provided for @noTransactionsYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get noTransactionsYet;

  /// No description provided for @earningsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your earnings will appear here'**
  String get earningsWillAppearHere;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get searchMessages;

  /// No description provided for @newMessageFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'New message feature coming soon!'**
  String get newMessageFeatureComingSoon;

  /// No description provided for @chatWith.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWith(String name);

  /// No description provided for @fullChatInterfaceComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Full chat interface coming soon!'**
  String get fullChatInterfaceComingSoon;

  /// No description provided for @warningsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} warnings remaining'**
  String warningsRemaining(int count);

  /// No description provided for @followTheseGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Follow these guidelines'**
  String get followTheseGuidelines;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get errorOccurred;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From:'**
  String get from;

  /// No description provided for @until.
  ///
  /// In en, this message translates to:
  /// **'Until:'**
  String get until;

  /// No description provided for @levelAndAchievements.
  ///
  /// In en, this message translates to:
  /// **'Level & Achievements'**
  String get levelAndAchievements;

  /// No description provided for @yourCurrentLevel.
  ///
  /// In en, this message translates to:
  /// **'Your Current Level'**
  String get yourCurrentLevel;

  /// No description provided for @xpProgress.
  ///
  /// In en, this message translates to:
  /// **'{currentXP} / {totalXP} XP'**
  String xpProgress(int currentXP, int totalXP);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @totalXP.
  ///
  /// In en, this message translates to:
  /// **'Total XP'**
  String get totalXP;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @xpReward.
  ///
  /// In en, this message translates to:
  /// **'+{amount} XP'**
  String xpReward(int amount);

  /// No description provided for @failedToSubmitTicket.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit ticket. Please try again.'**
  String get failedToSubmitTicket;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @chatWithSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Chat with support team'**
  String get chatWithSupportTeam;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Chamak Live'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect with people around the world through live streaming, chat, and share amazing moments.'**
  String get appDescription;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features:'**
  String get features;

  /// No description provided for @liveStreaming.
  ///
  /// In en, this message translates to:
  /// **'• Live streaming'**
  String get liveStreaming;

  /// No description provided for @realTimeChat.
  ///
  /// In en, this message translates to:
  /// **'• Real-time chat'**
  String get realTimeChat;

  /// No description provided for @virtualGifts.
  ///
  /// In en, this message translates to:
  /// **'• Virtual gifts'**
  String get virtualGifts;

  /// No description provided for @hostViewerModes.
  ///
  /// In en, this message translates to:
  /// **'• Host & viewer modes'**
  String get hostViewerModes;

  /// No description provided for @securePayments.
  ///
  /// In en, this message translates to:
  /// **'• Secure payments'**
  String get securePayments;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'We respect your privacy and are committed to protecting your personal data. This policy describes how we collect, use, and share your information.\n\n1. Information Collection\n2. Data Usage\n3. Data Sharing\n4. Security Measures\n5. Your Rights\n\nLast updated: January 2025'**
  String get privacyPolicyContent;

  /// No description provided for @termsConditionsContent.
  ///
  /// In en, this message translates to:
  /// **'By using Chamak Live, you agree to these terms and conditions.\n\n1. Account Registration\n2. User Conduct\n3. Content Guidelines\n4. Payment Terms\n5. Termination\n\nLast updated: January 2025'**
  String get termsConditionsContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'en',
        'hi',
        'kn',
        'ml',
        'mr',
        'ta',
        'te'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

// dart format off
// coverage:ignore-file
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('en'),
    Locale('zh')
  ];

  /// Text shown in the AppBar of the Counter Page
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counterAppBarTitle;

  /// Main headline on auth page
  ///
  /// In en, this message translates to:
  /// **'Create your shared space'**
  String get authPageTitle;

  /// Subtitle on auth page
  ///
  /// In en, this message translates to:
  /// **'Start tracking moments that matter together.'**
  String get authPageSubtitle;

  /// Step indicator text
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String authStepIndicator(int current, int total);

  /// Register tab label
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterTab;

  /// Login tab label
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLoginTab;

  /// Nickname field label
  ///
  /// In en, this message translates to:
  /// **'NICKNAME'**
  String get authNicknameLabel;

  /// Nickname field placeholder
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get authNicknamePlaceholder;

  /// Email or phone field label
  ///
  /// In en, this message translates to:
  /// **'EMAIL OR PHONE'**
  String get authEmailOrPhoneLabel;

  /// Email placeholder
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get authEmailPlaceholder;

  /// Phone placeholder
  ///
  /// In en, this message translates to:
  /// **'13800138000'**
  String get authPhonePlaceholder;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'PHONE NUMBER'**
  String get authPhoneLabel;

  /// Verification code field label
  ///
  /// In en, this message translates to:
  /// **'VERIFICATION CODE'**
  String get authVerificationCodeLabel;

  /// Verification code placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get authVerificationCodePlaceholder;

  /// Create account button text
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccountButton;

  /// Get verification code button text
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get authGetVerificationCodeButton;

  /// Sending state button text
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get authSendingButton;

  /// Resend countdown button text
  ///
  /// In en, this message translates to:
  /// **'Resend ({seconds}s)'**
  String authResendButton(int seconds);

  /// Separator text for alternative login methods
  ///
  /// In en, this message translates to:
  /// **'OR CONTINUE WITH'**
  String get authOrContinueWith;

  /// Join with invite code button text
  ///
  /// In en, this message translates to:
  /// **'Join with Invite Code'**
  String get authJoinWithInviteCode;

  /// Terms agreement prefix
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get authTermsAgreement;

  /// Terms of Service link text
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// Privacy Policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// Conjunction between terms and privacy
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get authAnd;

  /// Code sent success message
  ///
  /// In en, this message translates to:
  /// **'Verification code sent!'**
  String get authCodeSentSuccess;

  /// Phone required validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get authValidationPhoneRequired;

  /// Invalid phone validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get authValidationPhoneInvalid;

  /// Email required validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get authValidationEmailRequired;

  /// Invalid email validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authValidationEmailInvalid;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Failed to send code. Please try again.'**
  String get authErrorGeneric;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter 6-20 characters'**
  String get authPasswordPlaceholder;

  /// Confirm Password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get authPasswordConfirmLabel;

  /// Confirm Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get authPasswordConfirmPlaceholder;

  /// Password login mode chip text
  ///
  /// In en, this message translates to:
  /// **'Password Login'**
  String get authPasswordLogin;

  /// Code login mode chip text
  ///
  /// In en, this message translates to:
  /// **'Code Login'**
  String get authCodeLogin;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get authValidationPasswordTooShort;

  /// Passwords mismatch validation error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authValidationPasswordsDoNotMatch;

  /// Registration success snackbar message
  ///
  /// In en, this message translates to:
  /// **'Registration Successful! Please login.'**
  String get authRegistrationSuccess;

  /// Login success snackbar message
  ///
  /// In en, this message translates to:
  /// **'Login Successful!'**
  String get authLoginSuccess;

  /// Password max length validation error
  ///
  /// In en, this message translates to:
  /// **'Password too long (max 20)'**
  String get authValidationPasswordTooLong;

  /// Welcome title on onboarding profile setup page
  ///
  /// In en, this message translates to:
  /// **'Welcome aboard!'**
  String get onboardingWelcomeTitle;

  /// Welcome subtitle on onboarding profile setup page
  ///
  /// In en, this message translates to:
  /// **'Let\'s set up your profile so others can recognize you.'**
  String get onboardingWelcomeSubtitle;

  /// Nickname required validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get onboardingNicknameRequired;

  /// Nickname max length validation message
  ///
  /// In en, this message translates to:
  /// **'Nickname too long (max 20)'**
  String get onboardingNicknameTooLong;

  /// Continue button text on onboarding page
  ///
  /// In en, this message translates to:
  /// **'Let\'s Go'**
  String get onboardingContinueButton;

  /// Skip button text on onboarding page
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkipButton;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profilePageTitle;

  /// Save button text on profile page
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveButton;

  /// Profile update success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdateSuccess;

  /// Profile update error message
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile. Please try again.'**
  String get profileUpdateError;

  /// Logout button text on profile page
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get profileLogoutButton;

  /// Logout confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Log Out?'**
  String get profileLogoutConfirmTitle;

  /// Logout confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get profileLogoutConfirmMessage;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Create group page title
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupTitle;

  /// Create group page headline
  ///
  /// In en, this message translates to:
  /// **'Start your family space'**
  String get createGroupHeadline;

  /// Create group page subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a group to share points with your family or partner.'**
  String get createGroupSubtitle;

  /// Group name field label
  ///
  /// In en, this message translates to:
  /// **'GROUP NAME'**
  String get createGroupNameLabel;

  /// Group name field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g., My Family'**
  String get createGroupNamePlaceholder;

  /// Create group submit button text
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroupSubmitButton;

  /// Group creation success message
  ///
  /// In en, this message translates to:
  /// **'Group created successfully!'**
  String get createGroupSuccess;

  /// Group creation error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create group. Please try again.'**
  String get createGroupError;

  /// Invitation page title
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get invitationTitle;

  /// Invitation page headline
  ///
  /// In en, this message translates to:
  /// **'Share Invitation Code'**
  String get invitationHeadline;

  /// Invitation page subtitle
  ///
  /// In en, this message translates to:
  /// **'Share the code with members to join {groupName}'**
  String invitationSubtitle(String groupName);

  /// Invitation code label
  ///
  /// In en, this message translates to:
  /// **'INVITATION CODE'**
  String get invitationCodeLabel;

  /// Copy link button text
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get invitationCopyButton;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get invitationShareButton;

  /// Refresh code button text
  ///
  /// In en, this message translates to:
  /// **'Refresh Code'**
  String get invitationRefreshButton;

  /// Refresh confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Refresh Invitation Code?'**
  String get invitationRefreshTitle;

  /// Refresh confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'The old code will be invalidated. Are you sure?'**
  String get invitationRefreshMessage;

  /// Copy success message
  ///
  /// In en, this message translates to:
  /// **'Invitation link copied!'**
  String get invitationCopied;

  /// Refresh success message
  ///
  /// In en, this message translates to:
  /// **'Invitation code refreshed!'**
  String get invitationRefreshed;

  /// Invitation error message
  ///
  /// In en, this message translates to:
  /// **'Failed to get invitation code. Please try again.'**
  String get invitationError;

  /// Share message content
  ///
  /// In en, this message translates to:
  /// **'Join my group {groupName}!\nInvitation link: {shareUrl}'**
  String invitationShareMessage(String groupName, String shareUrl);

  /// Join group page title
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupTitle;

  /// Join group page headline
  ///
  /// In en, this message translates to:
  /// **'Enter Invitation Code'**
  String get joinGroupHeadline;

  /// Join group page subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter the code to join your family or partner\'s group'**
  String get joinGroupSubtitle;

  /// Invitation code input label
  ///
  /// In en, this message translates to:
  /// **'INVITATION CODE'**
  String get joinGroupCodeLabel;

  /// Invitation code input placeholder
  ///
  /// In en, this message translates to:
  /// **'ABC123'**
  String get joinGroupCodePlaceholder;

  /// Preview group button text
  ///
  /// In en, this message translates to:
  /// **'Find Group'**
  String get joinGroupPreviewButton;

  /// Confirm join button text
  ///
  /// In en, this message translates to:
  /// **'Join Group'**
  String get joinGroupConfirmButton;

  /// Member count text
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String joinGroupMemberCount(int count);

  /// Join success message
  ///
  /// In en, this message translates to:
  /// **'Successfully joined {groupName}!'**
  String joinGroupSuccess(String groupName);

  /// Join error message
  ///
  /// In en, this message translates to:
  /// **'Failed to join group. Please try again.'**
  String get joinGroupError;

  /// Invalid code error message
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired invitation code'**
  String get joinGroupErrorInvalidCode;

  /// Already member error message
  ///
  /// In en, this message translates to:
  /// **'You are already a member of this group'**
  String get joinGroupErrorAlreadyMember;

  /// Group selection page title
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get groupSelectionTitle;

  /// Group selection page subtitle
  ///
  /// In en, this message translates to:
  /// **'Create a new group or join an existing one to start sharing moments together.'**
  String get groupSelectionSubtitle;

  /// Create group option title
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get groupSelectionCreateTitle;

  /// Create group option subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a new space for your family or partner'**
  String get groupSelectionCreateSubtitle;

  /// Join group option title
  ///
  /// In en, this message translates to:
  /// **'Join Existing Group'**
  String get groupSelectionJoinTitle;

  /// Join group option subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter an invitation code to join'**
  String get groupSelectionJoinSubtitle;

  /// Display group name on home page
  ///
  /// In en, this message translates to:
  /// **'Group: {groupName}'**
  String homeGroupName(String groupName);

  /// Bottom navigation label for home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTabTitle;

  /// Invite members button text
  ///
  /// In en, this message translates to:
  /// **'Invite Members'**
  String get homeInviteMembers;

  /// Small label above the active group name in home top bar
  ///
  /// In en, this message translates to:
  /// **'Managing'**
  String get homeManagingLabel;

  /// Tooltip and semantics label for the home message entry button
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get homeMessageEntryLabel;

  /// Snackbar hint when the message entry button is tapped
  ///
  /// In en, this message translates to:
  /// **'Messages are coming soon.'**
  String get homeMessageEntryHint;

  /// Title for group switcher sheet
  ///
  /// In en, this message translates to:
  /// **'Switch Group'**
  String get groupSelectTitle;

  /// Action to create a new group
  ///
  /// In en, this message translates to:
  /// **'Create New Group'**
  String get groupCreateAction;

  /// Action to join an existing group
  ///
  /// In en, this message translates to:
  /// **'Join Existing Group'**
  String get groupJoinAction;

  /// Title for member management page
  ///
  /// In en, this message translates to:
  /// **'Member Management'**
  String get memberManagementTitle;

  /// Warning shown when member list is empty
  ///
  /// In en, this message translates to:
  /// **'No members found in this group.'**
  String get noMembersWarning;

  /// General retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Title for member detail page
  ///
  /// In en, this message translates to:
  /// **'Member Details'**
  String get memberDetailTitle;

  /// Label for group role section
  ///
  /// In en, this message translates to:
  /// **'Group Role'**
  String get memberRoleLabel;

  /// Label for permissions section
  ///
  /// In en, this message translates to:
  /// **'Granular Permissions'**
  String get memberPermissionsLabel;

  /// Note explaining admin permissions
  ///
  /// In en, this message translates to:
  /// **'Administrators have all permissions by default.'**
  String get memberAdminPermissionNote;

  /// Member joined date
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String memberJoinedDate(String date);

  /// Admin role label
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// Member role label
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// Permission label
  ///
  /// In en, this message translates to:
  /// **'Create Agreement'**
  String get permCreateAgreement;

  /// Permission label
  ///
  /// In en, this message translates to:
  /// **'Edit Agreement'**
  String get permEditAgreement;

  /// Permission label
  ///
  /// In en, this message translates to:
  /// **'Delete Agreement'**
  String get permDeleteAgreement;

  /// Permission label
  ///
  /// In en, this message translates to:
  /// **'Record for Others'**
  String get permRecordForOthers;

  /// Permission label
  ///
  /// In en, this message translates to:
  /// **'Modify Group Defaults'**
  String get permModifyDefaults;

  /// Permission label
  ///
  /// In en, this message translates to:
  /// **'Create Special Events'**
  String get permCreateSpecialEvents;

  /// Permission label
  ///
  /// In en, this message translates to:
  /// **'Revoke Records'**
  String get permRevokeRecords;

  /// Title for default settings page
  ///
  /// In en, this message translates to:
  /// **'Default Configuration'**
  String get defaultSettingsTitle;

  /// Label for require confirmation setting
  ///
  /// In en, this message translates to:
  /// **'Require Confirmation'**
  String get requireConfirmation;

  /// Description for require confirmation setting
  ///
  /// In en, this message translates to:
  /// **'Agreements require confirmation by default'**
  String get requireConfirmationDesc;

  /// Label for auto complete setting
  ///
  /// In en, this message translates to:
  /// **'Auto Complete Redemption'**
  String get autoComplete;

  /// Description for auto complete setting
  ///
  /// In en, this message translates to:
  /// **'Redemptions complete automatically'**
  String get autoCompleteDesc;

  /// Label for auto fulfill setting
  ///
  /// In en, this message translates to:
  /// **'Auto Fulfill Redemption'**
  String get autoFulfill;

  /// Description for auto fulfill setting
  ///
  /// In en, this message translates to:
  /// **'Redemptions are fulfilled automatically'**
  String get autoFulfillDesc;

  /// Label for provider incentive setting
  ///
  /// In en, this message translates to:
  /// **'Provider Incentive Ratio'**
  String get providerIncentive;

  /// Description for provider incentive setting
  ///
  /// In en, this message translates to:
  /// **'Percentage of points given to provider ({value}%)'**
  String providerIncentiveDesc(int value);

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Save success message
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get saveSuccess;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Agreements tab title
  ///
  /// In en, this message translates to:
  /// **'Agreements'**
  String get agreementTabTitle;

  /// Empty state title for agreements
  ///
  /// In en, this message translates to:
  /// **'No agreements yet'**
  String get agreementEmptyTitle;

  /// Empty state subtitle for agreements
  ///
  /// In en, this message translates to:
  /// **'Create your first agreement'**
  String get agreementEmptySubtitle;

  /// Empty state for inactive agreements tab
  ///
  /// In en, this message translates to:
  /// **'No inactive agreements'**
  String get agreementNoInactive;

  /// Create agreement button text
  ///
  /// In en, this message translates to:
  /// **'Create Agreement'**
  String get agreementCreateButton;

  /// Agreement name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get agreementNameLabel;

  /// Agreement name field placeholder
  ///
  /// In en, this message translates to:
  /// **'e.g., Do the dishes'**
  String get agreementNamePlaceholder;

  /// Name required validation message
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get agreementNameRequired;

  /// Agreement description field label
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get agreementDescriptionLabel;

  /// Agreement points field label
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get agreementPointsLabel;

  /// Points validation message
  ///
  /// In en, this message translates to:
  /// **'Points must be between 1 and 99999'**
  String get agreementPointsInvalid;

  /// Require confirmation toggle label
  ///
  /// In en, this message translates to:
  /// **'Requires confirmation'**
  String get agreementRequireConfirmationLabel;

  /// Require confirmation toggle hint
  ///
  /// In en, this message translates to:
  /// **'Completion must be confirmed by another member'**
  String get agreementRequireConfirmationHint;

  /// Cover image field label
  ///
  /// In en, this message translates to:
  /// **'Cover image (optional)'**
  String get agreementCoverImageLabel;

  /// Applicable members field label
  ///
  /// In en, this message translates to:
  /// **'Applicable to'**
  String get agreementApplicableMembersLabel;

  /// All members option text
  ///
  /// In en, this message translates to:
  /// **'All members'**
  String get agreementAllMembers;

  /// Members count suffix
  ///
  /// In en, this message translates to:
  /// **'members'**
  String get agreementMembersCount;

  /// Save agreement button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get agreementSaveButton;

  /// Agreement creation success message
  ///
  /// In en, this message translates to:
  /// **'Agreement created'**
  String get agreementCreateSuccess;

  /// Agreement creation error message
  ///
  /// In en, this message translates to:
  /// **'Failed to create agreement'**
  String get agreementCreateError;

  /// Agreement update success message
  ///
  /// In en, this message translates to:
  /// **'Agreement updated'**
  String get agreementUpdateSuccess;

  /// Agreement update error message
  ///
  /// In en, this message translates to:
  /// **'Failed to update agreement'**
  String get agreementUpdateError;

  /// Edit agreement page title
  ///
  /// In en, this message translates to:
  /// **'Edit Agreement'**
  String get agreementEditTitle;

  /// Agreement details button text
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get agreementDetails;

  /// Record completion button text
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get agreementRecordComplete;

  /// Deactivate agreement button text
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get agreementDeactivate;

  /// Activate agreement button text
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get agreementActivate;

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get agreementStatusActive;

  /// Inactive status label
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get agreementStatusInactive;

  /// Requires confirmation badge text
  ///
  /// In en, this message translates to:
  /// **'Requires confirmation'**
  String get agreementRequiresConfirmation;

  /// Pin agreement action label
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get agreementPinAction;

  /// Unpin agreement action label
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get agreementUnpinAction;

  /// Agreement pin success message
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get agreementPinSuccess;

  /// Agreement unpin success message
  ///
  /// In en, this message translates to:
  /// **'Unpinned'**
  String get agreementUnpinSuccess;

  /// Pinned agreements section title
  ///
  /// In en, this message translates to:
  /// **'Pinned agreements'**
  String get agreementPinnedSectionTitle;

  /// Agreement error when user is not a group member
  ///
  /// In en, this message translates to:
  /// **'You are not a member of this group'**
  String get agreementNotMemberError;

  /// Agreement error when agreement does not exist
  ///
  /// In en, this message translates to:
  /// **'Agreement not found'**
  String get agreementNotFoundError;

  /// Agreement error when pin action fails
  ///
  /// In en, this message translates to:
  /// **'Failed to pin agreement'**
  String get agreementPinError;

  /// Agreement error when unpin action fails
  ///
  /// In en, this message translates to:
  /// **'Failed to unpin agreement'**
  String get agreementUnpinError;

  /// Agreement error when loading agreements fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load agreements'**
  String get agreementLoadError;

  /// Generic agreement error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get agreementGenericError;

  /// No description provided for @agreementCompletionPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get agreementCompletionPendingTitle;

  /// No description provided for @agreementCompletionPendingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pending completions'**
  String get agreementCompletionPendingEmpty;

  /// No description provided for @agreementCompletionConfirmSuccess.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get agreementCompletionConfirmSuccess;

  /// No description provided for @agreementCompletionRejectSuccess.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get agreementCompletionRejectSuccess;

  /// No description provided for @agreementCompletionConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get agreementCompletionConfirmAction;

  /// No description provided for @agreementCompletionRejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get agreementCompletionRejectAction;

  /// No description provided for @agreementCompletionRejectReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get agreementCompletionRejectReasonHint;

  /// No description provided for @agreementCompletionUnknownAgreement.
  ///
  /// In en, this message translates to:
  /// **'Unknown agreement'**
  String get agreementCompletionUnknownAgreement;

  /// No description provided for @agreementCompletionCompleterLabel.
  ///
  /// In en, this message translates to:
  /// **'Completer:'**
  String get agreementCompletionCompleterLabel;

  /// No description provided for @agreementCompletionRecorderLabel.
  ///
  /// In en, this message translates to:
  /// **'Recorder:'**
  String get agreementCompletionRecorderLabel;

  /// No description provided for @agreementCompletionCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Requested at:'**
  String get agreementCompletionCreatedAtLabel;

  /// No description provided for @agreementCompletionSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Submitted, waiting for confirmation'**
  String get agreementCompletionSubmittedMessage;

  /// No description provided for @agreementCompletionConfirmedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recorded, points granted'**
  String get agreementCompletionConfirmedMessage;

  /// No description provided for @agreementCompletionRecordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Completion'**
  String get agreementCompletionRecordDialogTitle;

  /// No description provided for @agreementCompletionRecordDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm recording this agreement completion?'**
  String get agreementCompletionRecordDialogMessage;

  /// No description provided for @agreementCompletionRequiresConfirmationHint.
  ///
  /// In en, this message translates to:
  /// **'This agreement requires confirmation'**
  String get agreementCompletionRequiresConfirmationHint;

  /// No description provided for @agreementCompletionRecordForOthersToggle.
  ///
  /// In en, this message translates to:
  /// **'Record for others'**
  String get agreementCompletionRecordForOthersToggle;

  /// No description provided for @agreementCompletionRecordForLabel.
  ///
  /// In en, this message translates to:
  /// **'Completer'**
  String get agreementCompletionRecordForLabel;

  /// No description provided for @rewardTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get rewardTabTitle;

  /// No description provided for @rewardStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get rewardStatusActive;

  /// No description provided for @rewardStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get rewardStatusInactive;

  /// No description provided for @rewardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rewards yet'**
  String get rewardEmptyTitle;

  /// No description provided for @rewardEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first reward'**
  String get rewardEmptySubtitle;

  /// No description provided for @rewardNoInactive.
  ///
  /// In en, this message translates to:
  /// **'No inactive rewards'**
  String get rewardNoInactive;

  /// No description provided for @rewardCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create Reward'**
  String get rewardCreateButton;

  /// No description provided for @rewardNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get rewardNameLabel;

  /// No description provided for @rewardNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., Movie ticket'**
  String get rewardNamePlaceholder;

  /// No description provided for @rewardNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get rewardNameRequired;

  /// No description provided for @rewardDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get rewardDescriptionLabel;

  /// No description provided for @rewardCostPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cost points'**
  String get rewardCostPointsLabel;

  /// No description provided for @rewardCostPointsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Points must be between 1 and 99999'**
  String get rewardCostPointsInvalid;

  /// No description provided for @rewardAutoFulfillLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto Fulfill'**
  String get rewardAutoFulfillLabel;

  /// No description provided for @rewardAutoCompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto Complete'**
  String get rewardAutoCompleteLabel;

  /// No description provided for @rewardCoverImageLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image (optional)'**
  String get rewardCoverImageLabel;

  /// No description provided for @rewardCoverUploadAction.
  ///
  /// In en, this message translates to:
  /// **'Upload cover'**
  String get rewardCoverUploadAction;

  /// No description provided for @rewardCoverUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get rewardCoverUploading;

  /// No description provided for @rewardCoverRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get rewardCoverRemoveAction;

  /// No description provided for @rewardCoverUploadError.
  ///
  /// In en, this message translates to:
  /// **'Cover upload failed'**
  String get rewardCoverUploadError;

  /// No description provided for @rewardSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get rewardSaveButton;

  /// No description provided for @rewardCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward created'**
  String get rewardCreateSuccess;

  /// No description provided for @rewardCreateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to create reward'**
  String get rewardCreateError;

  /// No description provided for @rewardUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward updated'**
  String get rewardUpdateSuccess;

  /// No description provided for @rewardUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update reward'**
  String get rewardUpdateError;

  /// No description provided for @rewardEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reward'**
  String get rewardEditTitle;

  /// No description provided for @rewardDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get rewardDisableAction;

  /// No description provided for @rewardEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get rewardEnableAction;

  /// No description provided for @rewardDisableSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward disabled'**
  String get rewardDisableSuccess;

  /// No description provided for @rewardEnableSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reward enabled'**
  String get rewardEnableSuccess;

  /// No description provided for @rewardPinnedSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned rewards'**
  String get rewardPinnedSectionTitle;

  /// No description provided for @rewardPinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get rewardPinAction;

  /// No description provided for @rewardUnpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get rewardUnpinAction;

  /// No description provided for @redemptionOrderTabTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get redemptionOrderTabTitle;

  /// No description provided for @redemptionStatusAwaitingFulfill.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Fulfill'**
  String get redemptionStatusAwaitingFulfill;

  /// No description provided for @redemptionStatusAwaitingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Awaiting Confirm'**
  String get redemptionStatusAwaitingConfirm;

  /// No description provided for @redemptionStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get redemptionStatusCompleted;

  /// No description provided for @redemptionStatusUnsatisfied.
  ///
  /// In en, this message translates to:
  /// **'Unsatisfied'**
  String get redemptionStatusUnsatisfied;

  /// No description provided for @redemptionOrderEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get redemptionOrderEmptyTitle;

  /// No description provided for @redemptionOrderEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Redeem your first reward'**
  String get redemptionOrderEmptySubtitle;

  /// No description provided for @redemptionOrderDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Detail'**
  String get redemptionOrderDetailTitle;

  /// No description provided for @redemptionOrderQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get redemptionOrderQuantityLabel;

  /// No description provided for @redemptionOrderUnitPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit points'**
  String get redemptionOrderUnitPointsLabel;

  /// No description provided for @redemptionOrderTotalPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total points'**
  String get redemptionOrderTotalPointsLabel;

  /// No description provided for @redemptionOrderConsumerLabel.
  ///
  /// In en, this message translates to:
  /// **'Consumer'**
  String get redemptionOrderConsumerLabel;

  /// No description provided for @redemptionOrderProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get redemptionOrderProviderLabel;

  /// No description provided for @redemptionOrderTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get redemptionOrderTimelineTitle;

  /// No description provided for @redemptionOrderCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get redemptionOrderCreatedAtLabel;

  /// No description provided for @redemptionOrderFulfilledAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Fulfilled at'**
  String get redemptionOrderFulfilledAtLabel;

  /// No description provided for @redemptionOrderConfirmedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed at'**
  String get redemptionOrderConfirmedAtLabel;

  /// No description provided for @redemptionOrderEndedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Ended at'**
  String get redemptionOrderEndedAtLabel;

  /// No description provided for @redemptionActionRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem'**
  String get redemptionActionRedeem;

  /// No description provided for @redemptionConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get redemptionConfirmButton;

  /// No description provided for @redemptionInsufficientPoints.
  ///
  /// In en, this message translates to:
  /// **'Insufficient points'**
  String get redemptionInsufficientPoints;

  /// No description provided for @redemptionUnsatisfiedButton.
  ///
  /// In en, this message translates to:
  /// **'Not satisfied'**
  String get redemptionUnsatisfiedButton;

  /// No description provided for @redemptionUnsatisfiedReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get redemptionUnsatisfiedReasonHint;

  /// No description provided for @redemptionFulfillButton.
  ///
  /// In en, this message translates to:
  /// **'Mark fulfilled'**
  String get redemptionFulfillButton;

  /// No description provided for @redemptionConfirmSatisfiedButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm satisfied'**
  String get redemptionConfirmSatisfiedButton;

  /// No description provided for @redemptionCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Redemption created'**
  String get redemptionCreateSuccess;

  /// No description provided for @redemptionCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Redemption failed'**
  String get redemptionCreateFailed;

  /// No description provided for @redemptionBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Points balance'**
  String get redemptionBalanceLabel;

  /// No description provided for @redemptionBalanceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading points'**
  String get redemptionBalanceLoading;

  /// No description provided for @redemptionBalanceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load points'**
  String get redemptionBalanceLoadFailed;

  /// No description provided for @commonAppName.
  ///
  /// In en, this message translates to:
  /// **'Way2We'**
  String get commonAppName;

  /// No description provided for @commonPointsUnit.
  ///
  /// In en, this message translates to:
  /// **'pts'**
  String get commonPointsUnit;

  /// Points with unit
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String commonPoints(int points);

  /// Positive points delta with unit
  ///
  /// In en, this message translates to:
  /// **'+{points} pts'**
  String commonPointsDelta(int points);

  /// Quantity times unit points
  ///
  /// In en, this message translates to:
  /// **'{quantity} × {points} pts'**
  String commonQuantityTimesPoints(int quantity, int points);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get counterAppBarTitle => 'Counter';

  @override
  String get authPageTitle => 'Create your shared space';

  @override
  String get authPageSubtitle => 'Start tracking moments that matter together.';

  @override
  String authStepIndicator(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get authRegisterTab => 'Register';

  @override
  String get authLoginTab => 'Log In';

  @override
  String get authNicknameLabel => 'NICKNAME';

  @override
  String get authNicknamePlaceholder => 'What should we call you?';

  @override
  String get authEmailOrPhoneLabel => 'EMAIL OR PHONE';

  @override
  String get authEmailPlaceholder => 'name@example.com';

  @override
  String get authPhonePlaceholder => '13800138000';

  @override
  String get authPhoneLabel => 'PHONE NUMBER';

  @override
  String get authVerificationCodeLabel => 'VERIFICATION CODE';

  @override
  String get authVerificationCodePlaceholder => 'Enter code';

  @override
  String get authCreateAccountButton => 'Create Account';

  @override
  String get authGetVerificationCodeButton => 'Get';

  @override
  String get authSendingButton => 'Sending...';

  @override
  String authResendButton(int seconds) {
    return 'Resend (${seconds}s)';
  }

  @override
  String get authOrContinueWith => 'OR CONTINUE WITH';

  @override
  String get authJoinWithInviteCode => 'Join with Invite Code';

  @override
  String get authTermsAgreement => 'By continuing, you agree to our';

  @override
  String get authTermsOfService => 'Terms of Service';

  @override
  String get authPrivacyPolicy => 'Privacy Policy';

  @override
  String get authAnd => 'and';

  @override
  String get authCodeSentSuccess => 'Verification code sent!';

  @override
  String get authValidationPhoneRequired => 'Please enter your phone number';

  @override
  String get authValidationPhoneInvalid => 'Please enter a valid phone number';

  @override
  String get authValidationEmailRequired => 'Please enter your email';

  @override
  String get authValidationEmailInvalid => 'Please enter a valid email address';

  @override
  String get authErrorGeneric => 'Failed to send code. Please try again.';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordPlaceholder => 'Enter 6-20 characters';

  @override
  String get authPasswordConfirmLabel => 'Confirm Password';

  @override
  String get authPasswordConfirmPlaceholder => 'Re-enter password';

  @override
  String get authPasswordLogin => 'Password Login';

  @override
  String get authCodeLogin => 'Code Login';

  @override
  String get authValidationPasswordTooShort => 'Password too short';

  @override
  String get authValidationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authRegistrationSuccess => 'Registration Successful! Please login.';

  @override
  String get authLoginSuccess => 'Login Successful!';

  @override
  String get authValidationPasswordTooLong => 'Password too long (max 20)';

  @override
  String get onboardingWelcomeTitle => 'Welcome aboard!';

  @override
  String get onboardingWelcomeSubtitle => 'Let\'s set up your profile so others can recognize you.';

  @override
  String get onboardingNicknameRequired => 'Please enter a nickname';

  @override
  String get onboardingNicknameTooLong => 'Nickname too long (max 20)';

  @override
  String get onboardingContinueButton => 'Let\'s Go';

  @override
  String get onboardingSkipButton => 'Skip for now';

  @override
  String get profilePageTitle => 'Profile Settings';

  @override
  String get profileSaveButton => 'Save Changes';

  @override
  String get profileUpdateSuccess => 'Profile updated successfully!';

  @override
  String get profileUpdateError => 'Failed to update profile. Please try again.';

  @override
  String get profileLogoutButton => 'Log Out';

  @override
  String get profileLogoutConfirmTitle => 'Log Out?';

  @override
  String get profileLogoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get createGroupTitle => 'Create Group';

  @override
  String get createGroupHeadline => 'Start your family space';

  @override
  String get createGroupSubtitle => 'Create a group to share points with your family or partner.';

  @override
  String get createGroupNameLabel => 'GROUP NAME';

  @override
  String get createGroupNamePlaceholder => 'e.g., My Family';

  @override
  String get createGroupSubmitButton => 'Create Group';

  @override
  String get createGroupSuccess => 'Group created successfully!';

  @override
  String get createGroupError => 'Failed to create group. Please try again.';

  @override
  String get invitationTitle => 'Invite Members';

  @override
  String get invitationHeadline => 'Share Invitation Code';

  @override
  String invitationSubtitle(String groupName) {
    return 'Share the code with members to join $groupName';
  }

  @override
  String get invitationCodeLabel => 'INVITATION CODE';

  @override
  String get invitationCopyButton => 'Copy Link';

  @override
  String get invitationShareButton => 'Share';

  @override
  String get invitationRefreshButton => 'Refresh Code';

  @override
  String get invitationRefreshTitle => 'Refresh Invitation Code?';

  @override
  String get invitationRefreshMessage => 'The old code will be invalidated. Are you sure?';

  @override
  String get invitationCopied => 'Invitation link copied!';

  @override
  String get invitationRefreshed => 'Invitation code refreshed!';

  @override
  String get invitationError => 'Failed to get invitation code. Please try again.';

  @override
  String invitationShareMessage(String groupName, String shareUrl) {
    return 'Join my group $groupName!\nInvitation link: $shareUrl';
  }

  @override
  String get joinGroupTitle => 'Join Group';

  @override
  String get joinGroupHeadline => 'Enter Invitation Code';

  @override
  String get joinGroupSubtitle => 'Enter the code to join your family or partner\'s group';

  @override
  String get joinGroupCodeLabel => 'INVITATION CODE';

  @override
  String get joinGroupCodePlaceholder => 'ABC123';

  @override
  String get joinGroupPreviewButton => 'Find Group';

  @override
  String get joinGroupConfirmButton => 'Join Group';

  @override
  String joinGroupMemberCount(int count) {
    return '$count members';
  }

  @override
  String joinGroupSuccess(String groupName) {
    return 'Successfully joined $groupName!';
  }

  @override
  String get joinGroupError => 'Failed to join group. Please try again.';

  @override
  String get joinGroupErrorInvalidCode => 'Invalid or expired invitation code';

  @override
  String get joinGroupErrorAlreadyMember => 'You are already a member of this group';

  @override
  String get groupSelectionTitle => 'Get Started';

  @override
  String get groupSelectionSubtitle => 'Create a new group or join an existing one to start sharing moments together.';

  @override
  String get groupSelectionCreateTitle => 'Create New Group';

  @override
  String get groupSelectionCreateSubtitle => 'Start a new space for your family or partner';

  @override
  String get groupSelectionJoinTitle => 'Join Existing Group';

  @override
  String get groupSelectionJoinSubtitle => 'Enter an invitation code to join';

  @override
  String homeGroupName(String groupName) {
    return 'Group: $groupName';
  }

  @override
  String get homeTabTitle => 'Home';

  @override
  String get homeInviteMembers => 'Invite Members';

  @override
  String get homeManagingLabel => 'Managing';

  @override
  String get homeMessageEntryLabel => 'Messages';

  @override
  String get homeMessageEntryHint => 'Messages are coming soon.';

  @override
  String get groupSelectTitle => 'Switch Group';

  @override
  String get groupCreateAction => 'Create New Group';

  @override
  String get groupJoinAction => 'Join Existing Group';

  @override
  String get memberManagementTitle => 'Member Management';

  @override
  String get noMembersWarning => 'No members found in this group.';

  @override
  String get commonRetry => 'Retry';

  @override
  String get memberDetailTitle => 'Member Details';

  @override
  String get memberRoleLabel => 'Group Role';

  @override
  String get memberPermissionsLabel => 'Granular Permissions';

  @override
  String get memberAdminPermissionNote => 'Administrators have all permissions by default.';

  @override
  String memberJoinedDate(String date) {
    return 'Joined $date';
  }

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleMember => 'Member';

  @override
  String get permCreateAgreement => 'Create Agreement';

  @override
  String get permEditAgreement => 'Edit Agreement';

  @override
  String get permDeleteAgreement => 'Delete Agreement';

  @override
  String get permRecordForOthers => 'Record for Others';

  @override
  String get permModifyDefaults => 'Modify Group Defaults';

  @override
  String get permCreateSpecialEvents => 'Create Special Events';

  @override
  String get permRevokeRecords => 'Revoke Records';

  @override
  String get defaultSettingsTitle => 'Default Configuration';

  @override
  String get requireConfirmation => 'Require Confirmation';

  @override
  String get requireConfirmationDesc => 'Agreements require confirmation by default';

  @override
  String get autoComplete => 'Auto Complete Redemption';

  @override
  String get autoCompleteDesc => 'Redemptions complete automatically';

  @override
  String get autoFulfill => 'Auto Fulfill Redemption';

  @override
  String get autoFulfillDesc => 'Redemptions are fulfilled automatically';

  @override
  String get providerIncentive => 'Provider Incentive Ratio';

  @override
  String providerIncentiveDesc(int value) {
    return 'Percentage of points given to provider ($value%)';
  }

  @override
  String get save => 'Save';

  @override
  String get saveSuccess => 'Settings saved successfully';

  @override
  String get retry => 'Retry';

  @override
  String get agreementTabTitle => 'Agreements';

  @override
  String get agreementEmptyTitle => 'No agreements yet';

  @override
  String get agreementEmptySubtitle => 'Create your first agreement';

  @override
  String get agreementNoInactive => 'No inactive agreements';

  @override
  String get agreementCreateButton => 'Create Agreement';

  @override
  String get agreementNameLabel => 'Name';

  @override
  String get agreementNamePlaceholder => 'e.g., Do the dishes';

  @override
  String get agreementNameRequired => 'Name is required';

  @override
  String get agreementDescriptionLabel => 'Description (optional)';

  @override
  String get agreementPointsLabel => 'Points';

  @override
  String get agreementPointsInvalid => 'Points must be between 1 and 99999';

  @override
  String get agreementRequireConfirmationLabel => 'Requires confirmation';

  @override
  String get agreementRequireConfirmationHint => 'Completion must be confirmed by another member';

  @override
  String get agreementCoverImageLabel => 'Cover image (optional)';

  @override
  String get agreementApplicableMembersLabel => 'Applicable to';

  @override
  String get agreementAllMembers => 'All members';

  @override
  String get agreementMembersCount => 'members';

  @override
  String get agreementSaveButton => 'Save';

  @override
  String get agreementCreateSuccess => 'Agreement created';

  @override
  String get agreementCreateError => 'Failed to create agreement';

  @override
  String get agreementUpdateSuccess => 'Agreement updated';

  @override
  String get agreementUpdateError => 'Failed to update agreement';

  @override
  String get agreementEditTitle => 'Edit Agreement';

  @override
  String get agreementDetails => 'Details';

  @override
  String get agreementRecordComplete => 'Record';

  @override
  String get agreementDeactivate => 'Deactivate';

  @override
  String get agreementActivate => 'Activate';

  @override
  String get agreementStatusActive => 'Active';

  @override
  String get agreementStatusInactive => 'Inactive';

  @override
  String get agreementRequiresConfirmation => 'Requires confirmation';

  @override
  String get agreementPinAction => 'Pin';

  @override
  String get agreementUnpinAction => 'Unpin';

  @override
  String get agreementPinSuccess => 'Pinned';

  @override
  String get agreementUnpinSuccess => 'Unpinned';

  @override
  String get agreementPinnedSectionTitle => 'Pinned agreements';

  @override
  String get agreementNotMemberError => 'You are not a member of this group';

  @override
  String get agreementNotFoundError => 'Agreement not found';

  @override
  String get agreementPinError => 'Failed to pin agreement';

  @override
  String get agreementUnpinError => 'Failed to unpin agreement';

  @override
  String get agreementLoadError => 'Failed to load agreements';

  @override
  String get agreementGenericError => 'Something went wrong. Please try again.';

  @override
  String get agreementCompletionPendingTitle => 'Pending';

  @override
  String get agreementCompletionPendingEmpty => 'No pending completions';

  @override
  String get agreementCompletionConfirmSuccess => 'Confirmed';

  @override
  String get agreementCompletionRejectSuccess => 'Rejected';

  @override
  String get agreementCompletionConfirmAction => 'Confirm';

  @override
  String get agreementCompletionRejectAction => 'Reject';

  @override
  String get agreementCompletionRejectReasonHint => 'Reason (optional)';

  @override
  String get agreementCompletionUnknownAgreement => 'Unknown agreement';

  @override
  String get agreementCompletionCompleterLabel => 'Completer:';

  @override
  String get agreementCompletionRecorderLabel => 'Recorder:';

  @override
  String get agreementCompletionCreatedAtLabel => 'Requested at:';

  @override
  String get agreementCompletionSubmittedMessage => 'Submitted, waiting for confirmation';

  @override
  String get agreementCompletionConfirmedMessage => 'Recorded, points granted';

  @override
  String get agreementCompletionRecordDialogTitle => 'Record Completion';

  @override
  String get agreementCompletionRecordDialogMessage => 'Confirm recording this agreement completion?';

  @override
  String get agreementCompletionRequiresConfirmationHint => 'This agreement requires confirmation';

  @override
  String get agreementCompletionRecordForOthersToggle => 'Record for others';

  @override
  String get agreementCompletionRecordForLabel => 'Completer';

  @override
  String get rewardTabTitle => 'Products';

  @override
  String get profileTabTitle => 'Me';

  @override
  String get rewardStatusActive => 'Active';

  @override
  String get rewardStatusInactive => 'Inactive';

  @override
  String get rewardEmptyTitle => 'No rewards yet';

  @override
  String get rewardEmptySubtitle => 'Create your first reward';

  @override
  String get rewardNoInactive => 'No inactive rewards';

  @override
  String get rewardCreateButton => 'Create Reward';

  @override
  String get rewardNameLabel => 'Name';

  @override
  String get rewardNamePlaceholder => 'e.g., Movie ticket';

  @override
  String get rewardNameRequired => 'Name is required';

  @override
  String get rewardDescriptionLabel => 'Description (optional)';

  @override
  String get rewardCostPointsLabel => 'Cost points';

  @override
  String get rewardCostPointsInvalid => 'Points must be between 1 and 99999';

  @override
  String get rewardAutoFulfillLabel => 'Auto Fulfill';

  @override
  String get rewardAutoCompleteLabel => 'Auto Complete';

  @override
  String get rewardCoverImageLabel => 'Cover image (optional)';

  @override
  String get rewardCoverUploadAction => 'Upload cover';

  @override
  String get rewardCoverUploading => 'Uploading...';

  @override
  String get rewardCoverRemoveAction => 'Remove cover';

  @override
  String get rewardCoverUploadError => 'Cover upload failed';

  @override
  String get rewardSaveButton => 'Save';

  @override
  String get rewardCreateSuccess => 'Reward created';

  @override
  String get rewardCreateError => 'Failed to create reward';

  @override
  String get rewardUpdateSuccess => 'Reward updated';

  @override
  String get rewardUpdateError => 'Failed to update reward';

  @override
  String get rewardEditTitle => 'Edit reward';

  @override
  String get rewardDisableAction => 'Disable';

  @override
  String get rewardEnableAction => 'Enable';

  @override
  String get rewardDisableSuccess => 'Reward disabled';

  @override
  String get rewardEnableSuccess => 'Reward enabled';

  @override
  String get rewardPinnedSectionTitle => 'Pinned rewards';

  @override
  String get rewardPinAction => 'Pin';

  @override
  String get rewardUnpinAction => 'Unpin';

  @override
  String get redemptionOrderTabTitle => 'My Orders';

  @override
  String get redemptionStatusAwaitingFulfill => 'Awaiting Fulfill';

  @override
  String get redemptionStatusAwaitingConfirm => 'Awaiting Confirm';

  @override
  String get redemptionStatusCompleted => 'Completed';

  @override
  String get redemptionStatusUnsatisfied => 'Unsatisfied';

  @override
  String get redemptionOrderEmptyTitle => 'No orders yet';

  @override
  String get redemptionOrderEmptySubtitle => 'Redeem your first reward';

  @override
  String get redemptionOrderDetailTitle => 'Order Detail';

  @override
  String get redemptionOrderQuantityLabel => 'Quantity';

  @override
  String get redemptionOrderUnitPointsLabel => 'Unit points';

  @override
  String get redemptionOrderTotalPointsLabel => 'Total points';

  @override
  String get redemptionOrderConsumerLabel => 'Consumer';

  @override
  String get redemptionOrderProviderLabel => 'Provider';

  @override
  String get redemptionOrderTimelineTitle => 'Timeline';

  @override
  String get redemptionOrderCreatedAtLabel => 'Created at';

  @override
  String get redemptionOrderFulfilledAtLabel => 'Fulfilled at';

  @override
  String get redemptionOrderConfirmedAtLabel => 'Confirmed at';

  @override
  String get redemptionOrderEndedAtLabel => 'Ended at';

  @override
  String get redemptionActionRedeem => 'Redeem';

  @override
  String get redemptionConfirmButton => 'Confirm';

  @override
  String get redemptionInsufficientPoints => 'Insufficient points';

  @override
  String get redemptionUnsatisfiedButton => 'Not satisfied';

  @override
  String get redemptionUnsatisfiedReasonHint => 'Reason (optional)';

  @override
  String get redemptionFulfillButton => 'Mark fulfilled';

  @override
  String get redemptionConfirmSatisfiedButton => 'Confirm satisfied';

  @override
  String get redemptionCreateSuccess => 'Redemption created';

  @override
  String get redemptionCreateFailed => 'Redemption failed';

  @override
  String get redemptionBalanceLabel => 'Points balance';

  @override
  String get redemptionBalanceLoading => 'Loading points';

  @override
  String get redemptionBalanceLoadFailed => 'Failed to load points';

  @override
  String get commonAppName => 'Way2We';

  @override
  String get commonPointsUnit => 'pts';

  @override
  String commonPoints(int points) {
    return '$points pts';
  }

  @override
  String commonPointsDelta(int points) {
    return '+$points pts';
  }

  @override
  String commonQuantityTimesPoints(int quantity, int points) {
    return '$quantity × $points pts';
  }
}

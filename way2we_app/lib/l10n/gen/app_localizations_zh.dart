// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get counterAppBarTitle => '计数器';

  @override
  String get authPageTitle => '创建你们的共享空间';

  @override
  String get authPageSubtitle => '开始记录你们的重要时刻';

  @override
  String authStepIndicator(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get authRegisterTab => '注册';

  @override
  String get authLoginTab => '登录';

  @override
  String get authNicknameLabel => '昵称';

  @override
  String get authNicknamePlaceholder => '你想叫什么名字？';

  @override
  String get authEmailOrPhoneLabel => '邮箱或手机号';

  @override
  String get authEmailPlaceholder => 'name@example.com';

  @override
  String get authPhonePlaceholder => '13800138000';

  @override
  String get authPhoneLabel => '手机号';

  @override
  String get authVerificationCodeLabel => '验证码';

  @override
  String get authVerificationCodePlaceholder => '请输入验证码';

  @override
  String get authCreateAccountButton => '创建账号';

  @override
  String get authGetVerificationCodeButton => '获取';

  @override
  String get authSendingButton => '发送中...';

  @override
  String authResendButton(int seconds) {
    return '重新发送 (${seconds}s)';
  }

  @override
  String get authOrContinueWith => '或者通过以下方式';

  @override
  String get authJoinWithInviteCode => '使用邀请码加入';

  @override
  String get authTermsAgreement => '继续即表示同意我们的';

  @override
  String get authTermsOfService => '服务条款';

  @override
  String get authPrivacyPolicy => '隐私政策';

  @override
  String get authAnd => '和';

  @override
  String get authCodeSentSuccess => '验证码已发送！';

  @override
  String get authValidationPhoneRequired => '请输入手机号';

  @override
  String get authValidationPhoneInvalid => '请输入有效的手机号';

  @override
  String get authValidationEmailRequired => '请输入邮箱';

  @override
  String get authValidationEmailInvalid => '请输入有效的邮箱地址';

  @override
  String get authErrorGeneric => '发送验证码失败，请稍后重试';

  @override
  String get authPasswordLabel => '密码';

  @override
  String get authPasswordPlaceholder => '请输入6-20位字符';

  @override
  String get authPasswordConfirmLabel => '确认密码';

  @override
  String get authPasswordConfirmPlaceholder => '请再次输入密码';

  @override
  String get authPasswordLogin => '密码登录';

  @override
  String get authCodeLogin => '验证码登录';

  @override
  String get authValidationPasswordTooShort => '密码太短';

  @override
  String get authValidationPasswordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get authRegistrationSuccess => '注册成功！请登录。';

  @override
  String get authLoginSuccess => '登录成功！';

  @override
  String get authValidationPasswordTooLong => '密码太长（最多20个字符）';

  @override
  String get onboardingWelcomeTitle => '欢迎加入！';

  @override
  String get onboardingWelcomeSubtitle => '让我们设置您的个人资料，以便他人识别您。';

  @override
  String get onboardingNicknameRequired => '请输入昵称';

  @override
  String get onboardingNicknameTooLong => '昵称太长（最长20个字符）';

  @override
  String get onboardingContinueButton => '开启旅程';

  @override
  String get onboardingSkipButton => '稍后再说';

  @override
  String get profilePageTitle => '个人资料设置';

  @override
  String get profileSaveButton => '保存修改';

  @override
  String get profileUpdateSuccess => '个人资料更新成功！';

  @override
  String get profileUpdateError => '个人资料更新失败，请重试。';

  @override
  String get profileLogoutButton => '退出登录';

  @override
  String get profileLogoutConfirmTitle => '退出登录？';

  @override
  String get profileLogoutConfirmMessage => '确定要退出登录吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get createGroupTitle => '创建群组';

  @override
  String get createGroupHeadline => '开启你们的家庭空间';

  @override
  String get createGroupSubtitle => '创建一个群组，与家人或伴侣共享积分。';

  @override
  String get createGroupNameLabel => '群组名称';

  @override
  String get createGroupNamePlaceholder => '例如：我的家庭';

  @override
  String get createGroupSubmitButton => '创建群组';

  @override
  String get createGroupSuccess => '群组创建成功！';

  @override
  String get createGroupError => '群组创建失败，请重试。';

  @override
  String get invitationTitle => '邀请成员';

  @override
  String get invitationHeadline => '分享邀请码';

  @override
  String invitationSubtitle(String groupName) {
    return '将邀请码分享给 $groupName 的成员';
  }

  @override
  String get invitationCodeLabel => '邀请码';

  @override
  String get invitationCopyButton => '复制链接';

  @override
  String get invitationShareButton => '分享';

  @override
  String get invitationRefreshButton => '刷新邀请码';

  @override
  String get invitationRefreshTitle => '刷新邀请码？';

  @override
  String get invitationRefreshMessage => '刷新后，旧的邀请码将失效。确定要刷新吗？';

  @override
  String get invitationCopied => '邀请链接已复制！';

  @override
  String get invitationRefreshed => '邀请码已刷新！';

  @override
  String get invitationError => '获取邀请码失败，请重试。';

  @override
  String invitationShareMessage(String groupName, String shareUrl) {
    return '加入我的群组 $groupName！\n邀请链接：$shareUrl';
  }

  @override
  String get joinGroupTitle => '加入群组';

  @override
  String get joinGroupHeadline => '输入邀请码';

  @override
  String get joinGroupSubtitle => '输入邀请码加入家人或伴侣的群组';

  @override
  String get joinGroupCodeLabel => '邀请码';

  @override
  String get joinGroupCodePlaceholder => 'ABC123';

  @override
  String get joinGroupPreviewButton => '查找群组';

  @override
  String get joinGroupConfirmButton => '确认加入';

  @override
  String joinGroupMemberCount(int count) {
    return '$count 位成员';
  }

  @override
  String joinGroupSuccess(String groupName) {
    return '成功加入 $groupName！';
  }

  @override
  String get joinGroupError => '加入群组失败，请重试。';

  @override
  String get joinGroupErrorInvalidCode => '邀请码无效或已过期';

  @override
  String get joinGroupErrorAlreadyMember => '您已经是该群组成员';

  @override
  String get groupSelectionTitle => '开始使用';

  @override
  String get groupSelectionSubtitle => '创建新群组或加入现有群组，开始一起分享美好时刻。';

  @override
  String get groupSelectionCreateTitle => '创建新群组';

  @override
  String get groupSelectionCreateSubtitle => '为家人或伴侣创建新的共享空间';

  @override
  String get groupSelectionJoinTitle => '加入现有群组';

  @override
  String get groupSelectionJoinSubtitle => '输入邀请码加入群组';

  @override
  String homeGroupName(String groupName) {
    return '群组：$groupName';
  }

  @override
  String get homeInviteMembers => '邀请成员';

  @override
  String get groupSelectTitle => '选择群组';

  @override
  String get groupCreateAction => '创建新群组';

  @override
  String get groupJoinAction => '加入群组';

  @override
  String get memberManagementTitle => '成员管理';

  @override
  String get noMembersWarning => '该群组暂无成员。';

  @override
  String get commonRetry => '重试';

  @override
  String get memberDetailTitle => '成员详情';

  @override
  String get memberRoleLabel => '群组角色';

  @override
  String get memberPermissionsLabel => '详细权限';

  @override
  String get memberAdminPermissionNote => '管理员默认拥有所有权限。';

  @override
  String memberJoinedDate(String date) {
    return '加入时间 $date';
  }

  @override
  String get roleAdmin => '管理员';

  @override
  String get roleMember => '成员';

  @override
  String get permCreateAgreement => '创建协议';

  @override
  String get permEditAgreement => '编辑协议';

  @override
  String get permDeleteAgreement => '删除协议';

  @override
  String get permRecordForOthers => '代他人记录';

  @override
  String get permModifyDefaults => '修改群组默认值';

  @override
  String get permCreateSpecialEvents => '创建特殊事件';

  @override
  String get permRevokeRecords => '撤销记录';

  @override
  String get defaultSettingsTitle => '默认配置';

  @override
  String get requireConfirmation => '需要确认';

  @override
  String get requireConfirmationDesc => '完成约定默认需要确认';

  @override
  String get autoComplete => '自动完成兑换';

  @override
  String get autoCompleteDesc => '兑换请求自动完成';

  @override
  String get autoFulfill => '自动履约';

  @override
  String get autoFulfillDesc => '兑换自动履约';

  @override
  String get providerIncentive => '提供者激励比例';

  @override
  String providerIncentiveDesc(int value) {
    return '给提供者的积分比例 ($value%)';
  }

  @override
  String get save => '保存';

  @override
  String get saveSuccess => '配置保存成功';

  @override
  String get retry => '重试';

  @override
  String get agreementTabTitle => '约定';

  @override
  String get agreementEmptyTitle => '暂无约定';

  @override
  String get agreementEmptySubtitle => '创建第一个约定';

  @override
  String get agreementNoInactive => '暂无失效约定';

  @override
  String get agreementCreateButton => '创建约定';

  @override
  String get agreementNameLabel => '名称';

  @override
  String get agreementNamePlaceholder => '例如：洗碗';

  @override
  String get agreementNameRequired => '请输入名称';

  @override
  String get agreementDescriptionLabel => '描述（选填）';

  @override
  String get agreementPointsLabel => '积分';

  @override
  String get agreementPointsInvalid => '积分必须在1到99999之间';

  @override
  String get agreementRequireConfirmationLabel => '需要确认';

  @override
  String get agreementRequireConfirmationHint => '完成后需要其他成员确认';

  @override
  String get agreementCoverImageLabel => '封面图片（选填）';

  @override
  String get agreementApplicableMembersLabel => '适用于';

  @override
  String get agreementAllMembers => '所有成员';

  @override
  String get agreementMembersCount => '位成员';

  @override
  String get agreementSaveButton => '保存';

  @override
  String get agreementCreateSuccess => '约定创建成功';

  @override
  String get agreementCreateError => '创建约定失败';

  @override
  String get agreementUpdateSuccess => '约定更新成功';

  @override
  String get agreementUpdateError => '更新约定失败';

  @override
  String get agreementEditTitle => '编辑约定';

  @override
  String get agreementDetails => '详情';

  @override
  String get agreementRecordComplete => '记录';

  @override
  String get agreementDeactivate => '停用';

  @override
  String get agreementActivate => '启用';

  @override
  String get agreementStatusActive => '生效中';

  @override
  String get agreementStatusInactive => '已停用';

  @override
  String get agreementRequiresConfirmation => '需要确认';

  @override
  String get agreementPinAction => '置顶';

  @override
  String get agreementUnpinAction => '取消置顶';

  @override
  String get agreementPinSuccess => '已置顶';

  @override
  String get agreementUnpinSuccess => '已取消置顶';

  @override
  String get agreementPinnedSectionTitle => '置顶约定';

  @override
  String get agreementNotMemberError => '您不是该群组的成员';

  @override
  String get agreementNotFoundError => '约定不存在';

  @override
  String get agreementPinError => '置顶失败';

  @override
  String get agreementUnpinError => '取消置顶失败';

  @override
  String get agreementLoadError => '获取约定失败';

  @override
  String get agreementGenericError => '操作失败，请稍后重试';

  @override
  String get rewardTabTitle => '兑换/商品';

  @override
  String get rewardStatusActive => '上架中';

  @override
  String get rewardStatusInactive => '已下架';

  @override
  String get rewardEmptyTitle => '还没有商品，添加一个奖励';

  @override
  String get rewardEmptySubtitle => '创建第一个商品';

  @override
  String get rewardNoInactive => '暂无下架商品';

  @override
  String get rewardCreateButton => '创建商品';

  @override
  String get rewardNameLabel => '名称';

  @override
  String get rewardNamePlaceholder => '例如：电影票';

  @override
  String get rewardNameRequired => '请输入名称';

  @override
  String get rewardDescriptionLabel => '描述（选填）';

  @override
  String get rewardCostPointsLabel => '积分价格';

  @override
  String get rewardCostPointsInvalid => '积分必须在1到99999之间';

  @override
  String get rewardAutoFulfillLabel => '自动履约';

  @override
  String get rewardAutoCompleteLabel => '自动完成';

  @override
  String get rewardCoverImageLabel => '封面图片（选填）';

  @override
  String get rewardCoverUploadAction => '上传封面';

  @override
  String get rewardCoverUploading => '上传中...';

  @override
  String get rewardCoverRemoveAction => '移除封面';

  @override
  String get rewardCoverUploadError => '封面上传失败';

  @override
  String get rewardSaveButton => '保存';

  @override
  String get rewardCreateSuccess => '商品创建成功';

  @override
  String get rewardCreateError => '创建商品失败';

  @override
  String get rewardUpdateSuccess => '商品更新成功';

  @override
  String get rewardUpdateError => '更新商品失败';

  @override
  String get rewardEditTitle => '编辑商品';

  @override
  String get rewardDisableAction => '停用';

  @override
  String get rewardEnableAction => '启用';

  @override
  String get rewardDisableSuccess => '已停用商品';

  @override
  String get rewardEnableSuccess => '已启用商品';
}

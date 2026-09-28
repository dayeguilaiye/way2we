import '../../../core/network/failure.dart';

T parse<T>(T Function() read) {
  try {
    return read();
  } on AppFailure {
    rethrow;
  } catch (_) {
    throw const ProtocolFailure();
  }
}

class SpaceInfo {
  const SpaceInfo(this.id, this.name, this.memberId, this.status);
  final String id, name, memberId, status;
  factory SpaceInfo.summary(Map<String, dynamic> j) => parse(() {
    final s = j['space'] as Map<String, dynamic>;
    return SpaceInfo(
      s['id'] as String,
      s['name'] as String,
      j['my_member_id'] as String,
      j['my_status'] as String,
    );
  });
}

class MemberInfo {
  const MemberInfo(this.id, this.userId, this.name, this.status, this.balance);
  final String id, userId, name, status;
  final int balance;
  factory MemberInfo.fromJson(Map<String, dynamic> j) => parse(
    () => MemberInfo(
      j['id'] as String,
      j['user_id'] as String,
      j['nickname'] as String,
      j['status'] as String,
      j['balance'] as int,
    ),
  );
}

class InvitationInfo {
  const InvitationInfo(
    this.id,
    this.spaceId,
    this.spaceName,
    this.inviter,
    this.candidateId,
    this.name,
    this.status,
    this.required,
    this.approved,
  );
  final String id, spaceId, spaceName, inviter, status;
  final String? candidateId, name;
  final List<String> required, approved;
  factory InvitationInfo.fromJson(Map<String, dynamic> j) => parse(
    () => InvitationInfo(
      j['id'] as String,
      j['space_id'] as String,
      j['space_name'] as String,
      j['inviter_nickname'] as String,
      j['candidate_user_id'] as String?,
      j['candidate_display_name'] as String?,
      j['status'] as String,
      List<String>.unmodifiable(j['required_member_ids'] as List),
      List<String>.unmodifiable(j['approved_member_ids'] as List),
    ),
  );
  String get label => switch (status) {
    'joined' => '已加入',
    'expired' => '邀请已过期',
    'waiting' => candidateId == null ? '等待接受' : '等待全员同意',
    _ => '状态待更新',
  };
}

class InvitePreview {
  const InvitePreview(this.spaceName, this.inviter, this.expires);
  final String spaceName, inviter;
  final DateTime expires;
  factory InvitePreview.fromJson(Map<String, dynamic> j) => parse(
    () => InvitePreview(
      j['space_name'] as String,
      j['inviter_nickname'] as String,
      DateTime.parse(j['expires_at'] as String),
    ),
  );
}

class NoticeInfo {
  const NoticeInfo(
    this.id,
    this.summary,
    this.kind,
    this.resourceId,
    this.spaceId,
    this.time,
    this.read,
  );
  final String id, summary, kind, resourceId, spaceId;
  final DateTime time;
  final bool read;
  factory NoticeInfo.fromJson(Map<String, dynamic> j) => parse(() {
    final r = j['resource'] as Map<String, dynamic>;
    return NoticeInfo(
      j['id'] as String,
      j['summary'] as String,
      r['kind'] as String,
      r['id'] as String,
      r['space_id'] as String,
      DateTime.parse(j['created_at'] as String),
      j['read_at'] != null,
    );
  });
}

class DataPage<T> {
  const DataPage(this.items, this.next);
  final List<T> items;
  final String? next;
  factory DataPage.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) decode,
  ) => parse(
    () => DataPage(
      List<T>.unmodifiable(
        (j['items'] as List).map((v) => decode(v as Map<String, dynamic>)),
      ),
      j['next_cursor'] as String?,
    ),
  );
}

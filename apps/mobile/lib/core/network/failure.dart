sealed class AppFailure implements Exception {
  const AppFailure({this.requestId});
  final String? requestId;
}

final class ApiFailure extends AppFailure {
  const ApiFailure({
    required this.code,
    required this.status,
    this.fields = const {},
    this.retryAfterSeconds,
    super.requestId,
  });
  final String code;
  final int status;
  final int? retryAfterSeconds;
  final Map<String, String> fields;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

final class ProtocolFailure extends AppFailure {
  const ProtocolFailure({super.requestId});
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure();
}

final class StorageFailure extends AppFailure {
  const StorageFailure();
}

String failureMessage(AppFailure failure) => switch (failure) {
  ApiFailure(:final code) => switch (code) {
    'VALIDATION_FAILED' => '请检查填写内容。',
    'UNAUTHENTICATED' => '登录已到期，请重新登录。',
    'CODE_INVALID_OR_EXPIRED' => '验证码无效或已过期，请重新申请。',
    'INSUFFICIENT_POINTS' => '积分不足，请调整数量或稍后再试。',
    'MEMBERSHIP_INACTIVE' => '你已退出这个空间。',
    'ITEM_CHANGED' => '商品已更新，请查看最新内容。',
    'OPERATION_IN_PROGRESS' || 'OPERATION_NOT_FOUND' => '暂未确认结果，请继续核对。',
    'NOT_FOUND' => '内容暂时不可用。',
    'RATE_LIMITED' => '操作过于频繁，请稍后重试。',
    _ => '暂时无法完成，请稍后重试。',
  },
  StorageFailure() => '暂时无法保存本机数据，请重试。',
  NetworkFailure() => '网络连接失败，请检查网络后重试。',
  TimeoutFailure() => '请求超时，请稍后重试；已提交的操作需要核对结果。',
  ProtocolFailure() => '暂时无法读取结果，请稍后重试。',
  CancelledFailure() => '已停止等待；已提交的操作需要核对结果。',
};
String? fieldMessage(AppFailure? failure, String field) {
  if (failure case ApiFailure(:final fields)) {
    return switch (fields[field]) {
      'POSITIVE_INTEGER_REQUIRED' => '请输入大于 0 的整数。',
      'INVALID_EMAIL' => '请输入有效的邮箱地址。',
      'SIX_DIGITS_REQUIRED' => '请输入 6 位数字验证码。',
      'NAME_LENGTH' => '昵称需要 1～60 个字。',
      null => null,
      _ => '请检查此项内容。',
    };
  }
  return null;
}

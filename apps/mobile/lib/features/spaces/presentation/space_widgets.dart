import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/network/failure.dart';
import '../../account/presentation/account_widgets.dart';
import '../application/space_controller.dart';
import '../data/space_repository.dart';

class QueryView<T> extends StatelessWidget {
  const QueryView({
    super.key,
    required this.value,
    required this.content,
    required this.retry,
  });
  final AsyncValue<T> value;
  final Widget Function(T) content;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => value.when(
    skipLoadingOnRefresh: false,
    data: content,
    loading: () => const Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (e, _) => FailureNotice(
      e is AppFailure ? e : const ProtocolFailure(),
      onRetry: retry,
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).extension<BrandColors>()!.surface,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 16),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontFamily: 'BrandSerif', fontSize: 24),
    ),
  );
}

class OperationNotice extends ConsumerWidget {
  const OperationNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(operationProvider);
    final c = ref.read(operationProvider.notifier);
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('正在处理…'),
      );
    }
    if (!state.ready) {
      return state.failure == null
          ? const LinearProgressIndicator()
          : FailureNotice(state.failure!, onRetry: c.load);
    }
    if (state.pending != null) {
      return FailureNotice(
        state.failure ?? const TimeoutFailure(),
        pending: true,
        onRetry: c.retry,
      );
    }
    if (state.failure != null) return FailureNotice(state.failure!);
    final op = state.completed;
    final result = state.result;
    if (op != null && result != null) {
      String? target;
      String label = '查看结果';
      if (op.path == '/v1/spaces') {
        target = '/spaces/${(result['space'] as Map)['id']}';
      } else if (op.path == '/v1/invitations/accept' ||
          op.path.endsWith('/approve')) {
        target = '/invitations/${result['id']}';
      }
      if (result['invite_code'] case final String code) {
        return InviteShare(code: code, onClose: c.dismissResult);
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('已保存'),
            if (target != null)
              TextButton(
                onPressed: () {
                  c.dismissResult();
                  context.push(target!);
                },
                child: Text(label),
              ),
            TextButton(onPressed: c.dismissResult, child: const Text('知道了')),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class InviteShare extends StatelessWidget {
  const InviteShare({super.key, required this.code, this.onClose});
  final String code;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Surface(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('把邀请交给对方', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SelectableText(
            code,
            style: const TextStyle(fontSize: 18, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          const Text('7 天内有效。对方接受后，需要当前成员全部同意。'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => copy(context, code),
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('复制邀请码'),
              ),
              TextButton(
                onPressed: () => copy(context, invitationLink(code)),
                child: const Text('复制链接'),
              ),
              if (onClose != null)
                TextButton(onPressed: onClose, child: const Text('收起')),
            ],
          ),
        ],
      ),
    ),
  );
  static Future<void> copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已复制')));
    }
  }
}

class PageTurn extends StatelessWidget {
  const PageTurn({
    super.key,
    required this.next,
    required this.previous,
    required this.onNext,
    required this.onPrevious,
  });
  final String? next;
  final bool previous;
  final VoidCallback onNext, onPrevious;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Wrap(
      spacing: 16,
      children: [
        if (previous)
          TextButton(onPressed: onPrevious, child: const Text('上一页')),
        if (next != null)
          TextButton(onPressed: onNext, child: const Text('下一页')),
      ],
    ),
  );
}

bool canSubmit(OperationState s) => s.ready && !s.busy && s.pending == null;
String? nameError(String? value) =>
    value == null || value.trim().isEmpty || value.trim().runes.length > 60
    ? '请填写 1～60 个字。'
    : null;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../account/presentation/account_widgets.dart';
import '../application/space_controller.dart';
import 'space_widgets.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});
  @override
  ConsumerState<NotificationsPage> createState() => _NoticesState();
}

class _NoticesState extends ConsumerState<NotificationsPage> {
  final cursors = <String?>[null];
  @override
  Widget build(BuildContext context) {
    final provider = noticesProvider(cursors.last);
    final state = ref.watch(operationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
        actions: [
          IconButton(
            tooltip: '刷新通知',
            onPressed: () => ref.invalidate(provider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: PageBody(
        children: [
          const OperationNotice(),
          QueryView(
            value: ref.watch(provider),
            retry: () => ref.invalidate(provider),
            content: (page) => Column(
              children: [
                if (page.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      '暂时没有新通知\n加入申请有进展时，会在这里告诉你。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final n in page.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Surface(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        isThreeLine: true,
                        title: Text(n.summary),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${n.read ? '已读' : '未读'} · ${formatTime(n.time)}\n查看详情',
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: canSubmit(state)
                            ? () async {
                                if (!n.read) {
                                  final out = await ref
                                      .read(operationProvider.notifier)
                                      .submit(
                                        '/v1/notifications/${n.id}/read',
                                        method: 'PUT',
                                      );
                                  if (out == null) return;
                                  ref
                                      .read(operationProvider.notifier)
                                      .dismissResult();
                                }
                                if (!context.mounted) return;
                                switch (n.kind) {
                                  case 'invitation':
                                    await context.push<void>(
                                      '/invitations/${n.resourceId}',
                                    );
                                  case 'space':
                                    await context.push<void>(
                                      '/spaces/${n.spaceId}',
                                    );
                                  default:
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('请更新应用后查看这条通知。'),
                                      ),
                                    );
                                }
                              }
                            : null,
                      ),
                    ),
                  ),
                PageTurn(
                  next: page.next,
                  previous: cursors.length > 1,
                  onNext: () => setState(() => cursors.add(page.next)),
                  onPrevious: () => setState(() => cursors.removeLast()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatTime(DateTime t) {
  final d = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.month}月${d.day}日 ${two(d.hour)}:${two(d.minute)}';
}

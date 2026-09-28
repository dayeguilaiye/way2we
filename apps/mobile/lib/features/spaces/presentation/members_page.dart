import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../account/presentation/account_widgets.dart';
import '../application/space_controller.dart';
import 'space_widgets.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<MembersPage> createState() => _MembersState();
}

class _MembersState extends ConsumerState<MembersPage> {
  final cursors = <String?>[null];
  @override
  Widget build(BuildContext context) {
    final id = widget.id;
    final provider = membersProvider((id: id, cursor: cursors.last));
    final state = ref.watch(operationProvider);
    final uid = ref.watch(sessionProvider).current?.userId;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '空间列表',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/spaces'),
        ),
        title: const Text('成员与空间'),
        actions: [
          IconButton(
            tooltip: '通知',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: PageBody(
        children: [
          QueryView(
            value: ref.watch(spaceNameProvider(id)),
            retry: () => ref.invalidate(spaceNameProvider(id)),
            content: (name) => Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontFamily: 'BrandSerif'),
            ),
          ),
          const SizedBox(height: 20),
          QueryView(
            value: ref.watch(provider),
            retry: () => ref.invalidate(provider),
            content: (page) => Column(
              children: [
                Surface(
                  child: Column(
                    children: [
                      for (final m in page.items) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Text(
                            '${m.name}${m.userId == uid ? '（我）' : ''}',
                          ),
                          subtitle: Text(m.status == 'active' ? '参与中' : '已退出'),
                          trailing: Text('${m.balance} 分'),
                        ),
                        if (m != page.items.last)
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      ],
                    ],
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
          const OperationNotice(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: canSubmit(state)
                ? () => ref
                      .read(operationProvider.notifier)
                      .submit('/v1/spaces/$id/invitations')
                : null,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('邀请伙伴'),
          ),
          const SizedBox(height: 20),
          Surface(
            child: Column(
              children: [
                ListTile(
                  title: const Text('加入申请'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/spaces/$id/invitations'),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                ListTile(
                  title: const Text('我的空间昵称'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/spaces/$id/nickname'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              ref.invalidate(provider);
              ref.invalidate(spaceNameProvider(id));
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('刷新成员'),
          ),
        ],
      ),
    );
  }
}

class NicknamePage extends ConsumerStatefulWidget {
  const NicknamePage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<NicknamePage> createState() => _NicknameState();
}

class _NicknameState extends ConsumerState<NicknamePage> {
  final value = TextEditingController();
  final form = GlobalKey<FormState>();
  @override
  void dispose() {
    value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的空间昵称')),
      body: PageBody(
        children: [
          const Text('这个昵称只用于当前空间。'),
          const SizedBox(height: 24),
          Form(
            key: form,
            child: TextFormField(
              controller: value,
              enabled: canSubmit(state),
              decoration: const InputDecoration(labelText: '新的昵称'),
              validator: nameError,
            ),
          ),
          const SizedBox(height: 24),
          const OperationNotice(),
          FilledButton(
            onPressed: canSubmit(state)
                ? () async {
                    if (!form.currentState!.validate()) return;
                    final result = await ref
                        .read(operationProvider.notifier)
                        .submit(
                          '/v1/spaces/${widget.id}/members/me',
                          method: 'PATCH',
                          data: {'nickname': value.text.trim()},
                        );
                    if (result != null && context.mounted) {
                      ref.read(operationProvider.notifier).dismissResult();
                      context.pop();
                    }
                  }
                : null,
            child: const Text('保存昵称'),
          ),
        ],
      ),
    );
  }
}

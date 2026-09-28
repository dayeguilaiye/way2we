import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../account/application/account_controller.dart';
import '../../account/presentation/account_widgets.dart';
import '../application/space_controller.dart';
import 'space_widgets.dart';

class SpacesPage extends ConsumerStatefulWidget {
  const SpacesPage({super.key});
  @override
  ConsumerState<SpacesPage> createState() => _SpacesState();
}

class _SpacesState extends ConsumerState<SpacesPage> {
  final cursors = <String?>[null];
  @override
  Widget build(BuildContext context) {
    final cursor = cursors.last;
    final provider = spacesProvider(cursor);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => context.push('/me'),
          child: const Text('我的'),
        ),
        title: const Text('空间'),
        actions: [
          IconButton(
            tooltip: '通知',
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          await ref.read(provider.future);
        },
        child: PageBody(
          children: [
            const OperationNotice(),
            QueryView(
              value: ref.watch(provider),
              retry: () => ref.invalidate(provider),
              content: (page) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (page.items.isEmpty) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Botanical(
                        ref.watch(themeProvider),
                        width: 130,
                        height: 150,
                      ),
                    ),
                    Text(
                      '一起，\n留住日常的小事。',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontFamily: 'BrandSerif', height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    const Text('创建一个共同空间，或用对方的邀请加入。'),
                    const SizedBox(height: 36),
                  ],
                  for (final item in page.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Surface(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          title: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            item.status == 'active' ? '参与中' : '已退出 · 历史与余额保留',
                          ),
                          trailing: item.status == 'active'
                              ? const Icon(Icons.chevron_right)
                              : null,
                          onTap: item.status == 'active'
                              ? () => context.push('/spaces/${item.id}')
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
            FilledButton.icon(
              onPressed: () => context.push('/spaces/new'),
              icon: const Icon(Icons.add),
              label: const Text('创建空间'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/join'),
              child: const Text('使用邀请加入'),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateSpacePage extends ConsumerStatefulWidget {
  const CreateSpacePage({super.key});
  @override
  ConsumerState<CreateSpacePage> createState() => _CreateSpaceState();
}

class _CreateSpaceState extends ConsumerState<CreateSpacePage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final nickname = TextEditingController();
  bool initialized = false;
  @override
  void dispose() {
    name.dispose();
    nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationProvider);
    final user = ref.watch(accountProvider).user;
    if (!initialized && user != null) {
      nickname.text = user.name;
      initialized = true;
    }
    final enabled = canSubmit(state);
    return Scaffold(
      appBar: AppBar(title: const Text('创建空间')),
      body: PageBody(
        children: [
          Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '给共同的日常起个名字',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text('每个空间都有独立的成员、积分和小卖部。'),
                const SizedBox(height: 28),
                TextFormField(
                  controller: name,
                  enabled: enabled,
                  decoration: const InputDecoration(
                    labelText: '空间名称',
                    hintText: '例如：一起的小日子',
                  ),
                  validator: nameError,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nickname,
                  enabled: enabled,
                  decoration: const InputDecoration(labelText: '我在这个空间的昵称'),
                  validator: nameError,
                ),
                const SizedBox(height: 28),
                const OperationNotice(),
                FilledButton(
                  onPressed: enabled
                      ? () async {
                          if (!form.currentState!.validate()) return;
                          FocusScope.of(context).unfocus();
                          final out = await ref
                              .read(operationProvider.notifier)
                              .submit(
                                '/v1/spaces',
                                data: {
                                  'name': name.text.trim(),
                                  'nickname': nickname.text.trim(),
                                },
                              );
                          if (out != null && context.mounted) {
                            ref
                                .read(operationProvider.notifier)
                                .dismissResult();
                            context.go(
                              '/spaces/${(out['space'] as Map)['id']}',
                            );
                          }
                        }
                      : null,
                  child: Text(state.busy ? '正在创建…' : '创建空间'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

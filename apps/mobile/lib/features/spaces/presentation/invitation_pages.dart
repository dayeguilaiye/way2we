import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/network/failure.dart';
import '../../account/application/account_controller.dart';
import '../../account/presentation/account_widgets.dart';
import '../application/space_controller.dart';
import '../data/models.dart';
import '../data/space_repository.dart';
import 'space_widgets.dart';

class JoinPage extends ConsumerStatefulWidget {
  const JoinPage({super.key, this.code});
  final String? code;
  @override
  ConsumerState<JoinPage> createState() => _JoinState();
}

class _JoinState extends ConsumerState<JoinPage> {
  final code = TextEditingController(), name = TextEditingController();
  final form = GlobalKey<FormState>();
  InvitePreview? preview;
  String? checkedCode;
  AppFailure? failure;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    code.text = widget.code ?? '';
    name.text = ref.read(accountProvider).user?.name ?? '';
  }

  @override
  void dispose() {
    code.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> check() async {
    if (!form.currentState!.validate()) return;
    final value = invitationCode(code.text)!;
    final gen = ref.read(sessionProvider).generation;
    setState(() {
      loading = true;
      failure = null;
    });
    try {
      final result = await ref.read(spaceRepositoryProvider).preview(value);
      if (mounted && ref.read(sessionProvider).generation == gen) {
        setState(() {
          preview = result;
          checkedCode = value;
        });
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => failure = e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(operationProvider);
    final enabled = canSubmit(state) && !loading;
    return Scaffold(
      appBar: AppBar(title: const Text('加入空间')),
      body: PageBody(
        children: [
          const Text('把对方发来的邀请码或链接粘贴到这里。'),
          const SizedBox(height: 24),
          Form(
            key: form,
            child: Column(
              children: [
                TextFormField(
                  controller: code,
                  enabled: enabled,
                  decoration: const InputDecoration(labelText: '邀请码或链接'),
                  autocorrect: false,
                  validator: (v) => invitationCode(v ?? '') == null
                      ? '请填写完整的邀请码或邀请链接。'
                      : null,
                  onChanged: (_) => setState(() {
                    preview = null;
                    checkedCode = null;
                  }),
                ),
                if (preview != null) ...[
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: name,
                    enabled: enabled,
                    decoration: const InputDecoration(labelText: '我在这个空间的昵称'),
                    validator: nameError,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (preview case final InvitePreview p) ...[
            Surface(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.spaceName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text('${p.inviter} 邀请你加入'),
                    const SizedBox(height: 12),
                    const Text('接受后，等待当前成员全部同意。你的昵称会显示在加入申请中。'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (failure != null) ...[
            FailureNotice(failure!, onRetry: check),
            const SizedBox(height: 16),
          ],
          const OperationNotice(),
          FilledButton(
            onPressed: enabled
                ? () async {
                    if (preview == null) {
                      await check();
                      return;
                    }
                    if (!form.currentState!.validate()) return;
                    FocusScope.of(context).unfocus();
                    final result = await ref
                        .read(operationProvider.notifier)
                        .submit(
                          '/v1/invitations/accept',
                          data: {
                            'invite_code': checkedCode,
                            'nickname': name.text.trim(),
                          },
                        );
                    if (result != null && context.mounted) {
                      ref.read(operationProvider.notifier).dismissResult();
                      context.go('/invitations/${result['id']}');
                    }
                  }
                : null,
            child: Text(
              loading
                  ? '正在查看…'
                  : preview == null
                  ? '查看邀请'
                  : '接受邀请',
            ),
          ),
        ],
      ),
    );
  }
}

class InvitationsPage extends ConsumerStatefulWidget {
  const InvitationsPage({super.key, required this.id});
  final String id;
  @override
  ConsumerState<InvitationsPage> createState() => _InvitationsState();
}

class _InvitationsState extends ConsumerState<InvitationsPage> {
  final cursors = <String?>[null];
  @override
  Widget build(BuildContext context) {
    final provider = invitationsProvider((id: widget.id, cursor: cursors.last));
    return Scaffold(
      appBar: AppBar(
        title: const Text('加入申请'),
        actions: [
          IconButton(
            tooltip: '刷新',
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
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      '暂时没有加入申请。\n可以从成员页面邀请伙伴。',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final v in page.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Surface(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        title: Text(v.name ?? '邀请等待接受'),
                        subtitle: Text(
                          '${v.label} · ${v.approved.length}/${v.required.length} 位成员同意',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/invitations/${v.id}'),
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

class InvitationPage extends ConsumerWidget {
  const InvitationPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = invitationProvider(id);
    final state = ref.watch(operationProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '空间列表',
          onPressed: () => context.go('/spaces'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('加入进度'),
        actions: [
          IconButton(
            tooltip: '刷新进度',
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
            content: (v) {
              final uid = ref.watch(sessionProvider).current?.userId;
              final candidate = v.candidateId == uid;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    v.spaceName,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontFamily: 'BrandSerif'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    v.name == null ? '${v.inviter} 发起的邀请' : '${v.name} 的加入申请',
                  ),
                  const SizedBox(height: 28),
                  Surface(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                v.status == 'joined'
                                    ? Icons.check_circle_outline
                                    : Icons.schedule,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  v.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${v.approved.length} / ${v.required.length} 位成员已同意',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            v.status == 'joined'
                                ? '可以进入空间，开始共同的日常。'
                                : v.status == 'expired'
                                ? '请联系对方重新发起邀请。'
                                : v.required.isEmpty
                                ? '等待原成员恢复参与后继续确认。'
                                : candidate
                                ? '所有当前成员同意后，你就会加入。'
                                : '每位当前成员都同意后，申请人即可加入。',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (v.status == 'joined')
                    FilledButton(
                      onPressed: () => context.go('/spaces/${v.spaceId}'),
                      child: const Text('进入空间'),
                    ),
                  if (!candidate && v.status == 'waiting')
                    QueryView(
                      value: ref.watch(approvalMembersProvider(v.spaceId)),
                      retry: () =>
                          ref.invalidate(approvalMembersProvider(v.spaceId)),
                      content: (page) {
                        final mine = page
                            .where((m) => m.userId == uid)
                            .firstOrNull;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final m in page.where(
                              (m) => v.required.contains(m.id),
                            ))
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(m.name),
                                trailing: Text(
                                  v.approved.contains(m.id) ? '已同意' : '待同意',
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (mine != null && !v.approved.contains(mine.id))
                              FilledButton(
                                onPressed: canSubmit(state)
                                    ? () async {
                                        final c = ref.read(
                                          operationProvider.notifier,
                                        );
                                        final result = await c.submit(
                                          '/v1/spaces/${v.spaceId}/invitations/${v.id}/approve',
                                        );
                                        if (result != null && context.mounted) {
                                          c.dismissResult();
                                        }
                                      }
                                    : null,
                                child: const Text('同意加入'),
                              ),
                          ],
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

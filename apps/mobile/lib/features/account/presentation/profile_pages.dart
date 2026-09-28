import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/network/failure.dart';
import '../application/account_controller.dart';
import 'account_widgets.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountProvider);
    final user = state.user;
    final c = Theme.of(context).extension<BrandColors>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: PageBody(
        children: [
          if (state.loading && user == null)
            const Center(child: CircularProgressIndicator()),
          if (user != null) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: c.tint,
                  foregroundColor: c.primary,
                  child: Text(
                    user.name.characters.first,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '每一天，都有小小的收获。',
                        style: TextStyle(color: c.secondary, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Material(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    minVerticalPadding: 16,
                    leading: const Icon(Icons.person_outline),
                    title: const Text('账号信息'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/me/account'),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    minVerticalPadding: 16,
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('外观'),
                    subtitle: Text(user.theme.label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/me/appearance'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          AccountFeedback(state: state),
          if (!state.loading && user == null && state.failure == null)
            TextButton(
              onPressed: () => ref.read(accountProvider.notifier).load(),
              child: const Text('加载账号信息'),
            ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: state.busy
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('退出登录？'),
                        content: const Text('账号与记录会保留，下次用同一邮箱登录即可恢复。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('留下'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('退出登录'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(accountProvider.notifier).logout();
                    }
                  },
            child: Text(state.busy ? '正在处理…' : '退出登录'),
          ),
        ],
      ),
    );
  }
}

class AccountFeedback extends ConsumerWidget {
  const AccountFeedback({super.key, required this.state});
  final AccountState state;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('正在保存，请稍候…'),
      );
    }
    if (state.pending != null) {
      return FailureNotice(
        state.failure ?? const TimeoutFailure(),
        pending: true,
        onRetry: () => ref.read(accountProvider.notifier).retry(),
      );
    }
    if (state.failure != null) {
      return FailureNotice(
        state.failure!,
        onRetry: () => ref.read(accountProvider.notifier).load(),
      );
    }
    return const SizedBox.shrink();
  }
}

class AccountInfoPage extends ConsumerStatefulWidget {
  const AccountInfoPage({super.key});
  @override
  ConsumerState<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends ConsumerState<AccountInfoPage> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _initialized = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountProvider);
    final user = state.user;
    if (!_initialized && user != null) {
      _name.text = user.name;
      _initialized = true;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('账号信息')),
      body: PageBody(
        children: [
          Text('昵称', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            '这是你的账号昵称，空间里的称呼可以另外设置。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _form,
            child: TextFormField(
              key: const Key('display_name'),
              controller: _name,
              enabled: !state.busy && state.pending == null && user != null,
              decoration: InputDecoration(
                labelText: '账号昵称',
                errorText: fieldMessage(state.failure, 'display_name'),
              ),
              validator: (value) {
                final n = value?.trim().runes.length ?? 0;
                return n > 0 && n <= 60 ? null : '昵称需要 1～60 个字。';
              },
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.busy || state.pending != null || user == null
                ? null
                : () async {
                    if (!_form.currentState!.validate()) return;
                    FocusScope.of(context).unfocus();
                    final ok = await ref.read(accountProvider.notifier).save({
                      'display_name': _name.text.trim(),
                    });
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(content: Text('昵称已保存')));
                      context.pop();
                    }
                  },
            child: const Text('保存昵称'),
          ),
          const SizedBox(height: 16),
          AccountFeedback(state: state),
        ],
      ),
    );
  }
}

class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountProvider);
    final selected = state.user?.theme;
    return Scaffold(
      appBar: AppBar(title: const Text('外观')),
      body: PageBody(
        children: [
          Text('给日常，换一种心情。', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            '点选即保存。所有空间沿用你的选择，对方的外观由对方自己决定。',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 28),
          for (final theme in AppTheme.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ThemeOption(
                theme: theme,
                selected: theme == selected,
                enabled:
                    !state.busy && state.pending == null && selected != null,
                onTap: () async {
                  if (theme == selected) return;
                  final ok = await ref.read(accountProvider.notifier).save({
                    'theme': theme.name,
                  });
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('外观已保存')));
                  }
                },
              ),
            ),
          AccountFeedback(state: state),
        ],
      ),
    );
  }
}

class ThemeOption extends StatelessWidget {
  const ThemeOption({
    super.key,
    required this.theme,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final AppTheme theme;
  final bool selected, enabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final c = BrandColors.forTheme(theme);
    final motif = switch (theme) {
      AppTheme.apricot => '枝叶',
      AppTheme.celadon => '叶影',
      AppTheme.rose => '花枝',
    };
    return Semantics(
      selected: selected,
      button: true,
      label: '${theme.label}主题',
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? c.primary : c.divider,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('theme_${theme.name}'),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Botanical(theme, width: 56, height: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${theme.label} · $motif',
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final color in [c.primary, c.tint, c.background])
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(color: c.outline),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? c.primary : c.outline,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

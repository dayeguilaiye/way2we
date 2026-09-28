import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/failure.dart';
import '../application/diagnostics_controller.dart';

class DiagnosticsPage extends ConsumerStatefulWidget {
  const DiagnosticsPage({super.key});
  @override
  ConsumerState<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends ConsumerState<DiagnosticsPage> {
  final _quantity = TextEditingController(text: '0');
  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<BrandColors>()!;
    final state = ref.watch(diagnosticsProvider);
    final error = state.error;
    final failure = error is AppFailure ? error : null;
    final controller = ref.read(diagnosticsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('连接检查')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('一起的小日子', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(
                    '开发验证页 · 检查服务连接与错误反馈',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<AppTheme>(
                    initialValue: ref.watch(themeProvider),
                    decoration: const InputDecoration(labelText: '界面配色'),
                    items: AppTheme.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(themeProvider.notifier).select(value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: state.isLoading
                        ? null
                        : () =>
                              controller.run((repo) => repo.checkConnection()),
                    child: const Text('检查连接'),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    key: const Key('quantity'),
                    controller: _quantity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '数量',
                      helperText: '输入 0 可检查字段错误；正整数可检查成功响应。',
                      helperMaxLines: 3,
                      errorText: fieldMessage(failure, 'quantity'),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => controller.run(
                            (repo) => repo.validateQuantity(
                              int.tryParse(_quantity.text) ?? 0,
                            ),
                          ),
                    child: const Text('验证数量'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: state.isLoading
                        ? null
                        : () => controller.run(
                            (repo) => repo.checkGenericError(),
                          ),
                    child: const Text('检查通用错误'),
                  ),
                  const SizedBox(height: 24),
                  if (state.isLoading)
                    const Center(
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  if (state.value case final String message)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        message,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.positive,
                        ),
                      ),
                    ),
                  if (failure != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        failureMessage(failure),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.negative,
                        ),
                      ),
                    ),
                    if (failure.requestId case final String id) ...[
                      const SizedBox(height: 12),
                      Text('请求编号', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      SelectableText(
                        id,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.secondary,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

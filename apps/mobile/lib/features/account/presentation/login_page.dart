import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/failure.dart';
import '../application/account_controller.dart';
import 'account_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _form = GlobalKey<FormState>();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final controller = ref.read(loginProvider.notifier);
    if (ref.read(loginProvider).email == null) {
      controller.send(_email.text);
    } else {
      controller.login(_code.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginProvider);
    final verifying = state.email != null;
    final colors = Theme.of(context).extension<BrandColors>()!;
    final remaining = max(
      0,
      (state.resendAt?.difference(DateTime.now()).inMilliseconds ?? 0) / 1000,
    ).ceil();
    return PopScope(
      canPop: !verifying,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !state.busy) {
          ref.read(loginProvider.notifier).editEmail();
          _code.clear();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: verifying
              ? IconButton(
                  tooltip: '修改邮箱',
                  onPressed: state.busy
                      ? null
                      : () {
                          ref.read(loginProvider.notifier).editEmail();
                          _code.clear();
                        },
                  icon: const Icon(Icons.arrow_back),
                )
              : null,
        ),
        body: PageBody(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '一起的小日子',
                          style: TextStyle(
                            fontFamily: 'BrandSerif',
                            fontSize: 28,
                            height: 1.4,
                            color: colors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '平凡的日常，\n也是值得好好记录的生活。',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.9,
                            color: colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Botanical(AppTheme.apricot, width: 82, height: 142),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              verifying ? '查看你的邮箱' : '用邮箱开始',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              verifying
                  ? '请前往 ${state.email} 查收验证码。\n10 分钟内有效，请使用最新一封邮件中的验证码。'
                  : '首次登录将自动创建账号。\n已有账号？使用原来的邮箱即可找回。',
              style: TextStyle(color: colors.secondary, height: 1.7),
            ),
            const SizedBox(height: 28),
            Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!verifying)
                      TextFormField(
                        key: const Key('email'),
                        controller: _email,
                        enabled: !state.busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: '邮箱地址',
                          hintText: 'name@example.com',
                          errorText: fieldMessage(state.failure, 'email'),
                        ),
                        validator: (value) =>
                            RegExp(r'^[^\s@]+@[^\s@]+$')
                                .hasMatch(value?.trim() ?? '')
                            ? null
                            : '请输入有效的邮箱地址。',
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    if (verifying)
                      TextFormField(
                        key: const Key('code'),
                        controller: _code,
                        enabled: !state.busy,
                        keyboardType: TextInputType.number,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: '6 位验证码',
                          errorText: fieldMessage(state.failure, 'code'),
                        ),
                        validator: (value) =>
                            RegExp(r'^\d{6}$').hasMatch(value ?? '')
                            ? null
                            : '请输入 6 位数字验证码。',
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    if (state.failure != null &&
                        fieldMessage(
                              state.failure,
                              verifying ? 'code' : 'email',
                            ) ==
                            null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FailureNotice(state.failure!),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: state.busy || !verifying && remaining > 0
                          ? null
                          : _submit,
                      child: Text(
                        state.busy
                            ? '正在处理…'
                            : verifying
                            ? '登录'
                            : remaining > 0
                            ? '${remaining}s 后可重新获取'
                            : '获取验证码',
                      ),
                    ),
                    if (verifying)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextButton(
                          onPressed: state.busy || remaining > 0
                              ? null
                              : () {
                                  _code.clear();
                                  ref
                                      .read(loginProvider.notifier)
                                      .send(state.email!);
                                },
                          child: Text(
                            remaining > 0 ? '${remaining}s 后可重新发送' : '重新发送验证码',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

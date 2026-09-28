import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/network/failure.dart';

class FailureNotice extends StatelessWidget {
  const FailureNotice(
    this.failure, {
    super.key,
    this.onRetry,
    this.pending = false,
  });
  final AppFailure failure;
  final VoidCallback? onRetry;
  final bool pending;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pending ? '暂未确认保存结果，请联网后继续核对。' : failureMessage(failure),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        if (failure.requestId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SelectableText(
              '请求编号：${failure.requestId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (onRetry != null)
          TextButton(
            onPressed: onRetry,
            child: Text(pending ? '核对保存结果' : '重试'),
          ),
      ],
    ),
  );
}

class Botanical extends StatelessWidget {
  const Botanical(this.theme, {super.key, this.width = 120, this.height = 140});
  final AppTheme theme;
  final double width, height;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/botanicals/${theme.name}.png',
    width: width,
    height: height,
    fit: BoxFit.contain,
    excludeFromSemantics: true,
    errorBuilder: (_, _, _) => SizedBox(width: width, height: height),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: children,
        ),
      ),
    ),
  );
}

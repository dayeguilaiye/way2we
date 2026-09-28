import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/diagnostics_repository.dart';

final diagnosticsProvider =
    NotifierProvider<DiagnosticsController, AsyncValue<String?>>(
      DiagnosticsController.new,
    );

class DiagnosticsController extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() => const AsyncData(null);
  Future<void> run(
    Future<String> Function(DiagnosticsRepository) action,
  ) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => action(DiagnosticsRepository(ref.read(apiProvider))),
    );
    if (ref.mounted) state = result;
  }
}

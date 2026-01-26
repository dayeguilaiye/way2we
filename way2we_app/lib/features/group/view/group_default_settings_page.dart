import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/group/bloc/settings/group_settings_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/theme/theme.dart';

class GroupDefaultSettingsPage extends StatelessWidget {
  const GroupDefaultSettingsPage({
    super.key,
    required this.groupId,
  });

  final int groupId;

  static Route<void> route({required int groupId}) {
    return MaterialPageRoute<void>(
      builder: (_) => GroupDefaultSettingsPage(groupId: groupId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupSettingsBloc(
        groupProvider: context.read<GroupProvider>(),
      )..add(LoadGroupSettings(groupId: groupId)),
      child: _GroupDefaultSettingsView(groupId: groupId),
    );
  }
}

class _GroupDefaultSettingsView extends StatefulWidget {
  const _GroupDefaultSettingsView({required this.groupId});

  final int groupId;

  @override
  State<_GroupDefaultSettingsView> createState() =>
      _GroupDefaultSettingsViewState();
}

class _GroupDefaultSettingsViewState extends State<_GroupDefaultSettingsView> {
  // Local overrides. If null, use value from state.
  bool? _requireConfirmation;
  bool? _autoComplete;
  bool? _autoFulfill;
  double? _incentiveRatio;

  void _save(GroupSettings settings) {
    context.read<GroupSettingsBloc>().add(
      UpdateGroupSettings(
        groupId: widget.groupId,
        settings: {
          'require_confirmation_default':
              _requireConfirmation ?? settings.requireConfirmationDefault,
          'auto_complete_redemption_default':
              _autoComplete ?? settings.autoCompleteRedemptionDefault,
          'auto_fulfill_redemption_default':
              _autoFulfill ?? settings.autoFulfillRedemptionDefault,
          'provider_incentive_ratio':
              (_incentiveRatio ?? settings.providerIncentiveRatio.toDouble())
                  .round(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.defaultSettingsTitle),
      ),
      body: BlocConsumer<GroupSettingsBloc, GroupSettingsState>(
        listener: (context, state) {
          if (state is GroupSettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is GroupSettingsUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.saveSuccess)),
            );
            // Optionally reset local overrides since saved data matches now
            setState(() {
              _requireConfirmation = null;
              _autoComplete = null;
              _autoFulfill = null;
              _incentiveRatio = null;
            });
          }
        },
        builder: (context, state) {
          if (state is GroupSettingsLoading || state is GroupSettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GroupSettingsError && state.settings == null) {
            // If we have no data to show (initial load error)
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePaddingH,
                  vertical: AppSpacing.pagePaddingV,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<GroupSettingsBloc>().add(
                          LoadGroupSettings(groupId: widget.groupId),
                        );
                      },
                      child: Text(l10n.commonRetry),
                    ),
                  ],
                ),
              ),
            );
          }

          GroupSettings? settings;
          if (state is GroupSettingsLoaded) {
            settings = state.settings;
          } else if (state is GroupSettingsUpdating) {
            settings = state.currentSettings;
          } else if (state is GroupSettingsUpdateSuccess) {
            settings = state.settings;
          } else if (state is GroupSettingsError) {
            settings = state.settings;
          }

          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentRequireConfirmation =
              _requireConfirmation ?? settings.requireConfirmationDefault;
          final currentAutoComplete =
              _autoComplete ?? settings.autoCompleteRedemptionDefault;
          final currentAutoFulfill =
              _autoFulfill ?? settings.autoFulfillRedemptionDefault;
          final currentIncentiveRatio =
              _incentiveRatio ?? settings.providerIncentiveRatio.toDouble();

          final isSaving = state is GroupSettingsUpdating;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pagePaddingH,
              vertical: AppSpacing.pagePaddingV,
            ),
            children: [
              SwitchListTile(
                title: Text(l10n.requireConfirmation),
                subtitle: Text(l10n.requireConfirmationDesc),
                value: currentRequireConfirmation,
                onChanged: isSaving
                    ? null
                    : (v) => setState(() => _requireConfirmation = v),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.autoComplete),
                subtitle: Text(l10n.autoCompleteDesc),
                value: currentAutoComplete,
                onChanged: isSaving
                    ? null
                    : (v) => setState(() => _autoComplete = v),
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.autoFulfill),
                subtitle: Text(l10n.autoFulfillDesc),
                value: currentAutoFulfill,
                onChanged: isSaving
                    ? null
                    : (v) => setState(() => _autoFulfill = v),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.providerIncentive),
                    const SizedBox(height: 4),
                    Text(
                      l10n.providerIncentiveDesc(currentIncentiveRatio.round()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Slider(
                      value: currentIncentiveRatio,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: '${currentIncentiveRatio.round()}%',
                      onChanged: isSaving
                          ? null
                          : (v) => setState(() => _incentiveRatio = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              ElevatedButton(
                onPressed: isSaving ? null : () => _save(settings!),
                child: isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

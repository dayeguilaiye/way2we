import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:way2we_app/features/group/bloc/settings/group_settings_bloc.dart';
import 'package:way2we_app/features/group/data/providers/group_provider.dart';
import 'package:way2we_app/l10n/l10n.dart';
import 'package:way2we_app/shared/widgets/w2w.dart';
import 'package:way2we_app/theme/theme.dart';

class GroupDefaultSettingsPage extends StatelessWidget {
  const GroupDefaultSettingsPage({
    required this.groupId,
    super.key,
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
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.defaultSettingsTitle)),
      body: BlocConsumer<GroupSettingsBloc, GroupSettingsState>(
        listener: (context, state) {
          if (state is GroupSettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.semantic.error,
              ),
            );
          } else if (state is GroupSettingsUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.saveSuccess),
                backgroundColor: theme.semantic.success,
              ),
            );
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
            return const _GroupSettingsLoading();
          }

          if (state is GroupSettingsError && state.settings == null) {
            return W2WEmptyState(
              icon: Icons.settings_outlined,
              title: state.message,
              actionLabel: l10n.commonRetry,
              onAction: () {
                context.read<GroupSettingsBloc>().add(
                  LoadGroupSettings(groupId: widget.groupId),
                );
              },
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
            return const _GroupSettingsLoading();
          }
          final currentSettings = settings;

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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePaddingH,
              AppSpacing.pagePaddingV,
              AppSpacing.pagePaddingH,
              AppSpacing.pagePaddingV,
            ),
            children: [
              _SettingsToggleCard(
                title: l10n.requireConfirmation,
                subtitle: l10n.requireConfirmationDesc,
                value: currentRequireConfirmation,
                enabled: !isSaving,
                onChanged: (value) {
                  setState(() => _requireConfirmation = value);
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              _SettingsToggleCard(
                title: l10n.autoComplete,
                subtitle: l10n.autoCompleteDesc,
                value: currentAutoComplete,
                enabled: !isSaving,
                onChanged: (value) {
                  setState(() => _autoComplete = value);
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              _SettingsToggleCard(
                title: l10n.autoFulfill,
                subtitle: l10n.autoFulfillDesc,
                value: currentAutoFulfill,
                enabled: !isSaving,
                onChanged: (value) {
                  setState(() => _autoFulfill = value);
                },
              ),
              const SizedBox(height: AppSpacing.space3),
              W2WCard(
                showBorder: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.providerIncentive,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: AppTypography.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      l10n.providerIncentiveDesc(
                        currentIncentiveRatio.round(),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Slider(
                      value: currentIncentiveRatio,
                      max: 100,
                      divisions: 100,
                      label: '${currentIncentiveRatio.round()}%',
                      onChanged: isSaving
                          ? null
                          : (value) {
                              setState(() => _incentiveRatio = value);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              W2WButton(
                label: l10n.save,
                isLoading: isSaving,
                onPressed: isSaving ? null : () => _save(currentSettings),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsToggleCard extends StatelessWidget {
  const _SettingsToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return W2WCard(
      showBorder: true,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class _GroupSettingsLoading extends StatelessWidget {
  const _GroupSettingsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePaddingH,
        AppSpacing.pagePaddingV,
        AppSpacing.pagePaddingH,
        AppSpacing.pagePaddingV,
      ),
      itemBuilder: (_, index) {
        final isSlider = index == 3;
        return W2WCard(
          showBorder: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const W2WSkeleton(width: 180),
              const SizedBox(height: AppSpacing.space2),
              const W2WSkeleton(height: 12),
              const SizedBox(height: AppSpacing.space3),
              W2WSkeleton(height: isSlider ? 28 : 24),
            ],
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
      itemCount: 4,
    );
  }
}

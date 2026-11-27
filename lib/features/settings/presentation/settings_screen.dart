import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/core/theme/app_tokens.dart';
import 'package:cleancut/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// App-wide information (Clipcraft Settings). CleanCut is dark only, so there
/// is no theme choice; the screen holds the About section.
class SettingsScreen extends StatelessWidget {
  /// Creates the settings screen.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppTokens.gutter,
          16,
          AppTokens.gutter,
          24,
        ),
        children: [
          _SectionHeader(l10n.settingsAboutSection),
          _AboutCard(
            onLicenses: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 10),
      child: Semantics(
        header: true,
        child: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const new({required this.onLicenses});

  final VoidCallback onLicenses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        leading: const AppIcon(AppIcons.info, size: 22),
        title: Text(l10n.settingsLicenses),
        trailing: const AppIcon(AppIcons.chevronRight, size: 18),
        onTap: onLicenses,
      ),
    );
  }
}

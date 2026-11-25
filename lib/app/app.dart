import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:cleancut/app/router.dart';
import 'package:cleancut/app/theme/app_theme.dart';
import 'package:cleancut/features/settings/presentation/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root widget of CleanCut. Must sit below a `ProviderScope`.
class CleanCutApp extends ConsumerWidget {
  /// Creates the root app widget.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ref.watch(themeModeProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

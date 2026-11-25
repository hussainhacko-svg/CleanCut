import 'package:flutter/material.dart';

/// Root widget of CleanCut.
///
/// Placeholder shell for Phase 0. Theme, routing, Riverpod and localization
/// are wired in Phase 1 (see docs/PLAN.md).
class CleanCutApp extends StatelessWidget {
  /// Creates the root app widget.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = Colors.tealAccent.shade400;
    return MaterialApp(
      title: 'CleanCut',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(colorSchemeSeed: seed),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: const Scaffold(body: Center(child: Text('CleanCut'))),
    );
  }
}

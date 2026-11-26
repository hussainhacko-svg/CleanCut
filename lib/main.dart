import 'package:cleancut/app/app.dart';
import 'package:cleancut/app/licenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  registerAssetLicenses();
  runApp(const ProviderScope(child: CleanCutApp()));
}

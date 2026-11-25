import 'package:cleancut/app/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks for a new project name. Completes with the trimmed name, or `null`
/// when cancelled.
Future<String?> showRenameDialog(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (context) => RenameDialog(initialName: current),
    );

/// Text field dialog for renaming a project.
class RenameDialog extends StatefulWidget {
  /// Creates the dialog.
  const new({required this.initialName, super.key});

  /// Pre-filled name.
  final String initialName;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialName.length,
        );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.projectRenameTitle),
      content: ValueListenableBuilder(
        valueListenable: _controller,
        builder: (context, value, _) => TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.projectNameLabel,
            errorText: value.text.trim().isEmpty ? l10n.projectNameEmpty : null,
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        ValueListenableBuilder(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(l10n.commonSave),
          ),
        ),
      ],
    );
  }
}

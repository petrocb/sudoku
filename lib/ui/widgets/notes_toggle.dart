import 'package:flutter/material.dart';

class NotesToggle extends StatelessWidget {
  final bool isOn;
  final VoidCallback onToggle;

  const NotesToggle({
    super.key,
    required this.isOn,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onToggle,
      icon: Icon(isOn ? Icons.edit : Icons.edit_outlined),
      label: Text(isOn ? 'Notes: ON' : 'Notes: OFF'),
    );
  }
}
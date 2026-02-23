import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Show conflicts'),
                  subtitle: const Text('Highlight rule violations in red'),
                  value: settings.showConflicts,
                  onChanged: (v) => settings.setShowConflicts(v),
                ),
                SwitchListTile(
                  title: const Text('Haptics'),
                  subtitle: const Text('Little tap feedback (iOS/Android)'),
                  value: settings.haptics,
                  onChanged: (v) => settings.setHaptics(v),
                ),
                const SizedBox(height: 12),
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => settings.setThemeMode(s.first),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
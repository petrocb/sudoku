import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/game_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/stats_controller.dart';

import 'services/storage_service.dart';
import 'services/sudoku_engine.dart';
import 'services/stats_service.dart';
import 'services/timer_service.dart';

import 'ui/screens/home_screen.dart';

class SudokuRoot extends StatelessWidget {
  const SudokuRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService();
    final engine = SudokuEngine();
    final statsService = StatsService();
    final timerService = TimerService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsController(storage)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => StatsController(storage, statsService)..load(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => GameController(
            storage: storage,
            engine: engine,
            timer: timerService,
            stats: ctx.read<StatsController>(),
            settings: ctx.read<SettingsController>(),
          ),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Sudoku',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.indigo,
              useMaterial3: true,
            ),
            themeMode: settings.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
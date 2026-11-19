import 'package:material_ui/material_ui.dart';

import 'screens/setup_and_land_screen.dart';

void main() => runApp(const RapTrainerApp());

class RapTrainerApp extends StatelessWidget {
  const RapTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rap Trainer',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
      ),
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const SetupAndLandScreen(),
    );
  }
}

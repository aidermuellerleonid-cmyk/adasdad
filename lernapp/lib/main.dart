import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'features/upload/material_state.dart';
import 'features/upload/upload_screen.dart';
import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(const LernApp());
}

class LernApp extends StatelessWidget {
  const LernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MaterialSessionState(),
      child: MaterialApp(
        title: 'Lernhilfe',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const RootShell(),
      ),
    );
  }
}

/// Einfache, gut verständliche Navigation über eine Bottom-Navigation-Bar,
/// die auch auf kleinen Bildschirmen funktioniert.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    UploadScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.upload_file_outlined), label: 'Start'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Verlauf'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Einstellungen'),
        ],
      ),
    );
  }
}

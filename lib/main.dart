import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:mad_revparts/screens/login_screen.dart';
import 'package:mad_revparts/screens/register_screen.dart';
import 'package:mad_revparts/screens/home_screen.dart';
import 'package:mad_revparts/theme/theme_provider.dart';
import 'package:mad_revparts/providers/connectivity_provider.dart';

void main() {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ConnectivityProvider(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: 'RevParts',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            home: Scaffold(
              body: Stack(
                children: [
                  const LoginScreen(),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Consumer<ConnectivityProvider>(
                      builder: (context, connectivity, _) {
                        if (!connectivity.isOnline) {
                          return Container(
                            color: Colors.red,
                            padding: const EdgeInsets.all(8),
                            child: const Text(
                              'No Internet Connection',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
            routes: {
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => HomeScreen(
                    userData: {
                      'name': 'User',
                      'email': 'user@example.com',
                      'role': 'user'
                    },
                  ),
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/signup_screen.dart';
import '../features/navigation/main_nav_wrapper.dart';
import '../splash_screen.dart';

class AppRouter {
  // Route Name Constants
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Log the route change for easier debugging during development
    debugPrint('Navigating to: ${settings.name}');

    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const FBSplashScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case signup:
        return MaterialPageRoute(
          builder: (_) => const SignupScreen(),
          settings: settings,
        );

      case home:
        return MaterialPageRoute(
          builder: (_) => const MainNavWrapper(),
          settings: settings,
        );

      default:
      // Standard "Error 404" screen for the app
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
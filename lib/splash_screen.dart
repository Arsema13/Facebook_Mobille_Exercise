import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'routes/app_router.dart';

class FBSplashScreen extends StatefulWidget {
  const FBSplashScreen({super.key});

  @override
  State<FBSplashScreen> createState() => _FBSplashScreenState();
}

class _FBSplashScreenState extends State<FBSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() {
    // Standard splash delay
    Timer(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        if (user != null) {
          // If logged in, go Home
          Navigator.pushReplacementNamed(context, AppRouter.home);
        } else {
          // If not logged in, go to Login/Landing
          Navigator.pushReplacementNamed(context, AppRouter.login);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Facebook Official Blue
    const Color fbBlue = Color(0xFF1877F2);

    return Scaffold(
      backgroundColor: fbBlue,
      body: Stack(
        children: [
          // 1. Central Logo
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.facebook,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                // Optional: A subtle white loader
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),

          // 2. Meta Branding at Bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'from',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Meta Icon (Using a stylized 'M' or Infinity icon)
                    const Icon(Icons.all_inclusive, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Meta'.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
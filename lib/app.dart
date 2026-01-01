import 'package:flutter/material.dart';
import 'routes/app_router.dart';
import 'core/constants/fb_colors.dart';

class FacebookCloneApp extends StatelessWidget {
  const FacebookCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Facebook Clone',
      theme: ThemeData(
        scaffoldBackgroundColor: FBColors.greyBackground,
        primaryColor: FBColors.blue,
        useMaterial3: true,
      ),
      // Centralized Routing Setup
      initialRoute: AppRouter.login,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
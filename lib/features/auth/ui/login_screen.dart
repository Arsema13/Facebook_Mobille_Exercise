import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../../navigation/main_nav_wrapper.dart';

import 'join_facebook_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthRepository _repo = AuthRepository();
  bool _isPasswordVisible = false;

  void _handleLogin() async {
    final user = await _repo.login(emailController.text, passwordController.text);
    if (user != null && mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainNavWrapper()));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Login Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Facebook's subtle grey background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Facebook Logo
              const Icon(Icons.facebook, size: 80, color: Color(0xFF1877F2)),
              const SizedBox(height: 40),

              // 2. Email Field
              _buildTextField(
                controller: emailController,
                hintText: "Mobile number or email",
              ),
              const SizedBox(height: 12),

              // 3. Password Field
              _buildTextField(
                controller: passwordController,
                hintText: "Password",
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // 4. Log In Button (Solid Blue)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: _handleLogin,
                  child: const Text(
                    "Log In",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 5. Forgot Password
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 20),

              // 6. "OR" Divider
              const Row(
                children: [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),

              const SizedBox(height: 24),

              // 7. GOOGLE LOGIN BUTTON (Branded)
              _buildGoogleButton(),

              const SizedBox(height: 50),

              // 8. Create New Account (Bottom Bordered Button)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1877F2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const JoinFacebookScreen())),
                  child: const Text(
                    "Create New Account",
                    style: TextStyle(color: Color(0xFF1877F2), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom Input Builder to match FB's 2025 Input Style
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCD0D5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCCD0D5)),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
      ),
    );
  }

  // Google Branded Sign-In Button
  Widget _buildGoogleButton() {
    return InkWell(
      onTap: () async {
        final user = await _repo.loginWithGoogle();
        if (user != null && mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MainNavWrapper()));
        }
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF747775)), // Google's standard border color
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using a generic G icon here. You should replace this with a proper Google Logo asset.
            const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
            const SizedBox(width: 10),
            const Text(
              "Continue with Google",
              style: TextStyle(
                color: Color(0xFF1F1F1F),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
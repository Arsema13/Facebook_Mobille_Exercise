import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import '../../navigation/main_nav_wrapper.dart';
import '/../routes/app_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 1. Controllers for essential data
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthRepository _repo = AuthRepository();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    // Basic Validation
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // 2. Register User with all data points
    final user = await _repo.register(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
    );

    if (mounted) Navigator.pop(context); // Remove loading indicator

    if (user != null && mounted) {
      // SUCCESS: Clear navigation stack and go home
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.home,
            (route) => false,
      );
    } else {
      // FAILURE
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup failed. Please check your details.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create account",
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text(
              "Join Facebook",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "We'll help you create a new account in a few easy steps.",
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const SizedBox(height: 25),

            // Full Name Input
            _buildInputField(
              controller: nameController,
              hintText: "Full Name",
              keyboardType: TextInputType.name,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 15),

            // Phone Number Input
            _buildInputField(
              controller: phoneController,
              hintText: "Mobile Number",
              keyboardType: TextInputType.phone,
              icon: Icons.phone_android_outlined,
            ),
            const SizedBox(height: 15),

            // Email Input
            _buildInputField(
              controller: emailController,
              hintText: "Email address",
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 15),

            // Password Input
            _buildInputField(
              controller: passwordController,
              hintText: "Password",
              isPassword: true,
              icon: Icons.lock_outline,
            ),

            const SizedBox(height: 30),

            // Sign Up Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                onPressed: _handleSignup,
                child: const Text(
                  "Sign Up",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // OR Divider
            const Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text("OR", style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),

            const SizedBox(height: 25),

            _buildGoogleSignupButton(),

            const SizedBox(height: 40),

            Center(
              child: Text(
                "By tapping Sign Up, you agree to our Terms, Data Policy and Cookies Policy.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !_isPasswordVisible : false,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: InputBorder.none,
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
      ),
    );
  }

  Widget _buildGoogleSignupButton() {
    return InkWell(
      onTap: () async {
        final user = await _repo.loginWithGoogle();
        if (user != null && mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRouter.home, (route) => false);
        }
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.g_mobiledata, color: Colors.red, size: 35),
            SizedBox(width: 8),
            Text(
              "Sign up with Google",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
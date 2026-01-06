import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:facebook/features/feed/ui/feed_screen.dart';

// Note: Replace with your actual feed or home screen import
// import 'package:facebook/features/feed/ui/feed_screen.dart';

// --- 1. DATA CONTROLLER ---
class RegistrationController {
  static String firstName = "";
  static String lastName = "";
  static DateTime selectedBirthday = DateTime(1995, 11, 19);
  static String selectedGender = "Male";
  static String mobileNumber = "";
  static String emailAddress = "";
  static String password = "";

  // Google Sign-In Helper
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }
}



// --- CONSTANTS ---
const Color kFBBlue = Color(0xFF1877F2);
const Color kFBGray = Color(0xFFF0F2F5);
const Color kFBTextGrey = Color(0xFF65676B);

// --- 2. JOIN FACEBOOK SCREEN ---
class JoinFacebookScreen extends StatelessWidget {
  const JoinFacebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Create account'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/2021_Facebook_icon.svg/2048px-2021_Facebook_icon.svg.png',
                height: 80,
              ),
              const Spacer(),
              const Text('Join Facebook',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 15),
              const Text("We'll help you create a new account\nin a few easy steps.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: kFBTextGrey, height: 1.4)),
              const Spacer(),
              FBPrimaryButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NameInputScreen())),
                text: 'Get Started',
              ),
              const SizedBox(height: 12),
              // --- ADDED GOOGLE BUTTON ---
              FBSecondaryButton(
                onPressed: () async {
                  UserCredential? user = await RegistrationController.signInWithGoogle();
                  if (user != null) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                    );
                  }
                },
                text: 'Continue with Google',
                icon: Icons.login, // You can replace with a Google icon asset
              ),
              const Spacer(flex: 3),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account?',
                    style: TextStyle(color: kFBBlue, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. NAME INPUT SCREEN ---
class NameInputScreen extends StatefulWidget {
  const NameInputScreen({super.key});
  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  final TextEditingController _firstController = TextEditingController();
  final TextEditingController _lastController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Name'),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FBHeading(title: "What's your name?", subtitle: "Enter the name you use in real life."),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: FBTextField(controller: _firstController, label: 'First Name')),
                const SizedBox(width: 12),
                Expanded(child: FBTextField(controller: _lastController, label: 'Last Name')),
              ],
            ),
            const SizedBox(height: 40),
            FBPrimaryButton(
              onPressed: () {
                if (_firstController.text.isNotEmpty && _lastController.text.isNotEmpty) {
                  RegistrationController.firstName = _firstController.text;
                  RegistrationController.lastName = _lastController.text;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BirthdayInputScreen()));
                }
              },
              text: 'Next',
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. BIRTHDAY INPUT SCREEN ---
class BirthdayInputScreen extends StatefulWidget {
  const BirthdayInputScreen({super.key});
  @override
  State<BirthdayInputScreen> createState() => _BirthdayInputScreenState();
}

class _BirthdayInputScreenState extends State<BirthdayInputScreen> {
  DateTime _tempDate = RegistrationController.selectedBirthday;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Birthday'),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const FBHeading(title: "When's your birthday?", subtitle: "You can always make this private later."),
            const SizedBox(height: 40),
            Container(
              height: 200,
              decoration: BoxDecoration(
                  color: kFBGray,
                  borderRadius: BorderRadius.circular(15)
              ),
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _tempDate,
                onDateTimeChanged: (DateTime newDate) => setState(() => _tempDate = newDate),
              ),
            ),
            const SizedBox(height: 40),
            FBPrimaryButton(
              onPressed: () {
                RegistrationController.selectedBirthday = _tempDate;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GenderInputScreen()));
              },
              text: 'Next',
            ),
          ],
        ),
      ),
    );
  }
}

// --- 5. GENDER INPUT SCREEN ---
class GenderInputScreen extends StatefulWidget {
  const GenderInputScreen({super.key});
  @override
  State<GenderInputScreen> createState() => _GenderInputScreenState();
}

class _GenderInputScreenState extends State<GenderInputScreen> {
  String _tempGender = RegistrationController.selectedGender;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Gender'),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const FBHeading(title: "What's your gender?", subtitle: "You can change this later on your profile."),
            const SizedBox(height: 20),
            _buildFBOption("Female"),
            _buildFBOption("Male"),
            _buildFBOption("Custom"),
            const Spacer(),
            FBPrimaryButton(
              onPressed: () {
                RegistrationController.selectedGender = _tempGender;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileInputScreen()));
              },
              text: 'Next',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFBOption(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: RadioListTile<String>(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: title,
        activeColor: kFBBlue,
        groupValue: _tempGender,
        onChanged: (val) => setState(() => _tempGender = val!),
      ),
    );
  }
}

// --- 6. MOBILE NUMBER SCREEN ---
class MobileInputScreen extends StatefulWidget {
  const MobileInputScreen({super.key});
  @override
  State<MobileInputScreen> createState() => _MobileInputScreenState();
}

class _MobileInputScreenState extends State<MobileInputScreen> {
  final TextEditingController _mobile = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Mobile Number'),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const FBHeading(title: "What's your mobile number?", subtitle: "Enter the number where you can be reached."),
            const SizedBox(height: 30),
            FBTextField(controller: _mobile, label: 'Mobile number', keyboard: TextInputType.phone),
            const Spacer(),
            FBPrimaryButton(
              onPressed: () {
                RegistrationController.mobileNumber = _mobile.text;
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailInputScreen()));
              },
              text: 'Next',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- 7. EMAIL ADDRESS SCREEN ---
class EmailInputScreen extends StatefulWidget {
  const EmailInputScreen({super.key});
  @override
  State<EmailInputScreen> createState() => _EmailInputScreenState();
}

class _EmailInputScreenState extends State<EmailInputScreen> {
  final TextEditingController _emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Email'),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const FBHeading(title: "What's your email?", subtitle: "We'll use this to help you log in."),
            const SizedBox(height: 30),
            FBTextField(controller: _emailController, label: 'Email address', keyboard: TextInputType.emailAddress),
            const Spacer(),
            FBPrimaryButton(
              onPressed: () {
                if (_emailController.text.contains("@")) {
                  RegistrationController.emailAddress = _emailController.text.trim();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordInputScreen()));
                }
              },
              text: 'Next',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- 8. PASSWORD INPUT SCREEN ---
class PasswordInputScreen extends StatefulWidget {
  const PasswordInputScreen({super.key});
  @override
  State<PasswordInputScreen> createState() => _PasswordInputScreenState();
}

class _PasswordInputScreenState extends State<PasswordInputScreen> {
  final TextEditingController _pass = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Security'),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const FBHeading(title: "Create a password", subtitle: "Enter at least 6 characters."),
            const SizedBox(height: 30),
            FBTextField(controller: _pass, label: 'Password', isPassword: true),
            const Spacer(),
            FBPrimaryButton(
              onPressed: () {
                if (_pass.text.length >= 6) {
                  RegistrationController.password = _pass.text;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPrivacyScreen()));
                }
              },
              text: 'Next',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// --- 9. TERMS & PRIVACY (SIGN UP) ---
class TermsPrivacyScreen extends StatefulWidget {
  const TermsPrivacyScreen({super.key});
  @override
  State<TermsPrivacyScreen> createState() => _TermsPrivacyScreenState();
}

class _TermsPrivacyScreenState extends State<TermsPrivacyScreen> {
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: RegistrationController.emailAddress,
        password: RegistrationController.password,
      );

      await FirebaseFirestore.instance.collection('users').doc(userCred.user!.uid).set({
        'firstName': RegistrationController.firstName,
        'lastName': RegistrationController.lastName,
        'birthday': RegistrationController.selectedBirthday.toIso8601String(),
        'gender': RegistrationController.selectedGender,
        'mobile': RegistrationController.mobileNumber,
        'email': RegistrationController.emailAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Authentication failed"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildFBAppBar(context, 'Terms & Privacy'),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const FBHeading(title: "Finish Signing Up",
                subtitle: "By tapping Sign Up, you agree to our Terms and Data Policy."),
            const Spacer(),
            _loading ? const CircularProgressIndicator(color: kFBBlue) : FBPrimaryButton(
              onPressed: _register,
              text: 'Sign Up',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}




// --- REUSABLE UI COMPONENTS ---

PreferredSizeWidget _buildFBAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0.5,
    leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context)),
    title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
    centerTitle: true,
  );
}

class FBHeading extends StatelessWidget {
  final String title, subtitle;
  const FBHeading({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: double.infinity),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: kFBTextGrey)),
      ],
    );
  }
}

class FBTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final TextInputType keyboard;
  const FBTextField({super.key, required this.controller, required this.label, this.isPassword = false, this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kFBTextGrey),
        filled: true,
        fillColor: kFBGray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class FBPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const FBPrimaryButton({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kFBBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class FBSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;
  const FBSecondaryButton({super.key, required this.text, required this.onPressed, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.black54),
        label: Text(text, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
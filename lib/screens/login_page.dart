import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'Home_page.dart';
import 'profile_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login),
          label: const Text('Sign in with Google'),
          onPressed: () async {
            final user = await AuthService().signInWithGoogle();
            if (user != null) {
              // Navigate to the CameraPage on successful login
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else {
              // Show an error message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to sign in')),
              );
            }
          },
        ),
      ),
    );
  }
}

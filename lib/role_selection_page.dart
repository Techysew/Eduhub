import 'package:flutter/material.dart';
import 'registration_page.dart'; // ✅ NEW
import 'splash_screen.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildRoleButton(String role, String label) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegistrationPage(role: role),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009639),
          ),
          child: Text(label),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Your Role"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Select your role",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            // STUDENT
            buildRoleButton("student", "Student"),

            const SizedBox(height: 20),

            // TUTOR
            buildRoleButton("tutor", "Tutor / Mentor"),

            const SizedBox(height: 20),

            // CLUB
            buildRoleButton("club", "Club"),

            const SizedBox(height: 20),

            // RECRUITER
            buildRoleButton("recruiter", "Recruiter"),

            const Spacer(),

            // BACK BUTTON
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                "← Back to Login",
                style: TextStyle(fontSize: 16, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

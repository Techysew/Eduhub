import 'package:flutter/material.dart';
import 'student_registration_page.dart';
import 'tutor_registration_page.dart';
import 'club_registration_page.dart';
import 'recruiter_registration_page.dart';
import 'splash_screen.dart'; // ✅ ADD THIS IMPORT

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const StudentRegistrationPage()),
                ),
                child: const Text("Student"),
              ),
            ),

            const SizedBox(height: 20),

            // TUTOR
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TutorRegistrationPage()),
                ),
                child: const Text("Tutor / Mentor"),
              ),
            ),

            const SizedBox(height: 20),

            // CLUB
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ClubRegistrationPage()),
                ),
                child: const Text("Club"),
              ),
            ),

            const SizedBox(height: 20),

            // RECRUITER
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RecruiterRegistrationPage()),
                ),
                child: const Text("Recruiter"),
              ),
            ),

            const Spacer(),

            // 🔥 BACK TO LOGIN BUTTON
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

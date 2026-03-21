import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // ===============================
  // 🔹 Check if username is available
  // ===============================
  static Future<bool> isUsernameAvailable(String username) async {
    final doc = await FirebaseFirestore.instance
        .collection("usernames")
        .doc(username)
        .get();

    return !doc.exists; // if username doc does not exist, it's available
  }

  // ===============================
  // 🔹 Register new user (SECURE)
  // ===============================
  static Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // 1️⃣ Check username availability
      final available = await isUsernameAvailable(username);
      if (!available) return "USERNAME_TAKEN";

      // 2️⃣ Create user in Firebase Auth
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = cred.user;
      if (user == null) return "USER_CREATION_FAILED";

      await user.reload(); // ✅ ensure token is active

      // 3️⃣ Save user data in Firestore (UID-based security)
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "username": username,
        "email": email,
        "roles": [role],
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 4️⃣ Save username in separate collection for availability checks
      await FirebaseFirestore.instance
          .collection("usernames")
          .doc(username)
          .set({"uid": user.uid});

      // 5️⃣ Send verification email
      try {
        await user.sendEmailVerification();
        print("✅ Verification email sent to $email");
      } catch (e) {
        print("⚠️ Email send failed: $e");
      }

      return "SUCCESS";
    } on FirebaseAuthException catch (e) {
      print("🔥 FirebaseAuthException: ${e.code} - ${e.message}");
      if (e.code == "email-already-in-use") return "EMAIL_EXISTS";
      if (e.code == "invalid-email") return "INVALID_EMAIL";
      if (e.code == "weak-password") return "WEAK_PASSWORD";
      return "AUTH_ERROR: ${e.message}";
    } catch (e) {
      print("🔥 Unknown error: $e");
      return "ERROR: $e";
    }
  }

  // ===============================
  // 🔹 Check email verified
  // ===============================
  static Future<bool> isEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    return user.emailVerified;
  }
}

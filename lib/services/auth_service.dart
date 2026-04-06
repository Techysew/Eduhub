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

    return !doc.exists;
  }

  // ===============================
  // 🔹 Register new user
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

      UserCredential cred;

      try {
        // 2️⃣ Try creating new user
        cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (e) {
        // If email already exists → sign in instead
        if (e.code == "email-already-in-use") {
          cred = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
        } else {
          rethrow;
        }
      }

      final user = cred.user;
      if (user == null) return "USER_CREATION_FAILED";

      final userDoc =
          FirebaseFirestore.instance.collection("users").doc(user.uid);

      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // 🔹 User exists → add new role
        List<String> roles =
            List<String>.from(docSnapshot.data()?["roles"] ?? []);

        if (!roles.contains(role)) {
          roles.add(role);
          await userDoc.update({"roles": roles});
        }

        return "ROLE_ADDED";
      } else {
        // 🔹 New user → create Firestore document
        await userDoc.set({
          "username": username,
          "email": email,
          "roles": [role],
          "createdAt": FieldValue.serverTimestamp(),
        });

        // Save username for availability checking
        await FirebaseFirestore.instance
            .collection("usernames")
            .doc(username)
            .set({"uid": user.uid});

        // Send verification email
        await user.sendEmailVerification();

        return "SUCCESS";
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-email") return "INVALID_EMAIL";
      if (e.code == "weak-password") return "WEAK_PASSWORD";
      if (e.code == "wrong-password") return "WRONG_PASSWORD";
      return "AUTH_ERROR";
    } catch (e) {
      return "ERROR";
    }
  }

  // ===============================
  // 🔹 Add new role to existing logged-in user
  // ===============================
  static Future<String?> addRole(String newRole) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return "NOT_LOGGED_IN";

      final userDoc =
          FirebaseFirestore.instance.collection("users").doc(user.uid);

      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) return "USER_DATA_NOT_FOUND";

      List<String> roles =
          List<String>.from(docSnapshot.data()?["roles"] ?? []);

      if (roles.contains(newRole)) {
        return "ROLE_ALREADY_EXISTS";
      }

      roles.add(newRole);

      await userDoc.update({
        "roles": roles,
      });

      return "ROLE_ADDED_SUCCESS";
    } catch (e) {
      return "ERROR";
    }
  }

  // ===============================
  // 🔹 Check if email verified
  // ===============================
  static Future<bool> isEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await user.reload();
    return user.emailVerified;
  }
}

import 'package:flutter/material.dart';

class PasswordStrengthField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final Function(double)? onStrengthChanged; // NEW callback

  const PasswordStrengthField({
    super.key,
    required this.controller,
    this.labelText = "Password",
    this.obscureText = true,
    this.onStrengthChanged,
  });

  @override
  State<PasswordStrengthField> createState() => _PasswordStrengthFieldState();
}

class _PasswordStrengthFieldState extends State<PasswordStrengthField> {
  String hint = "";
  double strength = 0; // 0 to 1
  Color strengthColor = Colors.red;

  void updateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    setState(() {
      strength = score / 5;

      if (strength < 0.4) {
        strengthColor = Colors.red;
        hint = "Weak password";
      } else if (strength < 0.8) {
        strengthColor = Colors.orange;
        hint = "Medium strength";
      } else {
        strengthColor = Colors.green;
        hint = "Strong password";
      }

      if (widget.onStrengthChanged != null) {
        widget.onStrengthChanged!(strength); // callback
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          onChanged: updateStrength,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey[300],
          color: strengthColor,
          minHeight: 5,
        ),
        if (hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              hint,
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

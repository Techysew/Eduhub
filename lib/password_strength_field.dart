import 'package:flutter/material.dart';

class PasswordStrengthField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final Function(double)? onStrengthChanged;

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
  double strength = 0;
  bool _obscure = true;

  // Strength level colors matching dark theme palette
  static const _colors = [
    Color(0xFFEF4444), // weak   — red
    Color(0xFFF59E0B), // medium — amber
    Color(0xFF10B981), // strong — green
  ];

  static const _labels = ['Weak', 'Medium', 'Strong'];

  Color get _strengthColor {
    if (strength < 0.4) return _colors[0];
    if (strength < 0.8) return _colors[1];
    return _colors[2];
  }

  String get _strengthLabel {
    if (strength < 0.4) return _labels[0];
    if (strength < 0.8) return _labels[1];
    return _labels[2];
  }

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  void updateStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    setState(() {
      strength = score / 5;
      hint = password.isEmpty ? '' : _strengthLabel;
    });

    widget.onStrengthChanged?.call(strength);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input field ───────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasText && strength > 0
                  ? _strengthColor.withOpacity(0.35)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscure,
            onChanged: updateStrength,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: widget.labelText,
              labelStyle: TextStyle(
                  color: Colors.white.withOpacity(0.35), fontSize: 13),
              prefixIcon: Icon(Icons.lock_outline_rounded,
                  color: Colors.white.withOpacity(0.3), size: 20),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.3),
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),

        // ── Strength bar ──────────────────────────────
        if (hasText) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              // 5 segment bars
              Expanded(
                child: Row(
                  children: List.generate(5, (i) {
                    final filled = strength * 5 > i;
                    final segColor = filled ? _strengthColor : Colors.white.withOpacity(0.08);
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                        decoration: BoxDecoration(
                          color: segColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: filled
                              ? [
                                  BoxShadow(
                                    color: _strengthColor.withOpacity(0.4),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              // Label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  key: ValueKey(hint),
                  hint,
                  style: TextStyle(
                    color: _strengthColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
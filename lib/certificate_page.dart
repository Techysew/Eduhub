import 'package:flutter/material.dart';
import 'certificate_generator.dart';

class CertificatePage extends StatelessWidget {
  final String courseName;

  const CertificatePage({super.key, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Stack(
        children: [
          // Background blobs for aesthetic consistency
          Positioned(top: -80, right: -60, child: _Blob(color: const Color(0xFF3B82F6).withOpacity(0.13))),
          Positioned(bottom: -100, left: -70, child: _Blob(color: const Color(0xFF8B5CF6).withOpacity(0.1))),

          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
                          child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white.withOpacity(0.8), size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text('Certificate', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),

                // Main Certificate Card
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131929),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium_rounded, size: 80, color: Color(0xFFF59E0B)),
                          const SizedBox(height: 24),
                          const Text(
                            "Certificate of Completion",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Congratulations on successfully completing",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            courseName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          
                          // Download Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () => CertificateGenerator.generate(courseName),
                              child: const Text("Download PDF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Background shape helper
class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});
  @override
  Widget build(BuildContext context) => Container(
      width: 260, 
      height: 260, 
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent]))
  );
}
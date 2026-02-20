import 'package:flutter/material.dart';
import 'certificate_generator.dart';

class CertificatePage extends StatelessWidget {
  final String courseName;

  const CertificatePage({super.key, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Certificate")),
      body: Center(
        child: Card(
          elevation: 8,
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
      const SizedBox(height: 20),
      const Text("Certificate of Completion",
          style:
              TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      const Text("This certifies you completed"),
      Text(courseName,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      const Text("Congratulations 🎉"),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: () {
          CertificateGenerator.generate(courseName);
        },
        child: const Text("Download Certificate PDF"),
      ),
    ],
  ),
),

        ),
      ),
    );
  }
}

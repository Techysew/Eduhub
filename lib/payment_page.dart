import 'package:flutter/material.dart';

class PaymentPage extends StatelessWidget {
  final String courseTitle;
  final double price;

  const PaymentPage({
    super.key,
    required this.courseTitle,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(courseTitle,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Price: \$${price.toStringAsFixed(2)}"),
            const SizedBox(height: 30),
            DropdownButtonFormField(
              items: const [
                DropdownMenuItem(value: "card", child: Text("Credit Card")),
                DropdownMenuItem(value: "payhere", child: Text("PayHere")),
                DropdownMenuItem(value: "sandbox", child: Text("Sandbox")),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(labelText: "Payment Method"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Payment Successful")),
                );
                Navigator.pop(context);
              },
              child: const Text("Confirm Payment"),
            )
          ],
        ),
      ),
    );
  }
}

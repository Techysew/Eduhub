import 'package:flutter/material.dart';

class LessonQuizPage extends StatefulWidget {
  final String lessonName;

  const LessonQuizPage({super.key, required this.lessonName});

  @override
  State<LessonQuizPage> createState() => _LessonQuizPageState();
}

class _LessonQuizPageState extends State<LessonQuizPage> {
  int? selectedAnswer;
  bool showResult = false;

  /// demo question (later you can load from Firestore)
  final question = "What is Flutter?";
  final options = [
    "Programming Language",
    "UI Framework",
    "Database",
    "Operating System"
  ];
  final correctIndex = 1;

  void submitQuiz() {
    setState(() {
      showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...List.generate(options.length, (i) {
              return RadioListTile(
                title: Text(options[i]),
                value: i,
                groupValue: selectedAnswer,
                onChanged: (value) {
                  setState(() => selectedAnswer = value);
                },
              );
            }),
            ElevatedButton(onPressed: submitQuiz, child: const Text("Submit")),
            if (showResult)
              Text(
                selectedAnswer == correctIndex ? "Correct ✅" : "Wrong ❌",
                style: const TextStyle(fontSize: 18),
              )
          ],
        ),
      ),
    );
  }
}

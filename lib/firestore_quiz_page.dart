import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreQuizPage extends StatefulWidget {
  final String courseId;
  final String lessonName;

  const FirestoreQuizPage({
    super.key,
    required this.courseId,
    required this.lessonName,
  });

  @override
  State<FirestoreQuizPage> createState() => _FirestoreQuizPageState();
}

class _FirestoreQuizPageState extends State<FirestoreQuizPage> {
  int? selectedAnswer;
  bool showResult = false;
  bool isCorrect = false;

  /// ===== LOAD QUIZ DOCUMENT =====
  Future<DocumentSnapshot> loadQuiz() {
    return FirebaseFirestore.instance
        .collection("courses")
        .doc(widget.courseId)
        .collection("quizzes")
        .doc(widget.lessonName)
        .get();
  }

  /// ===== SUBMIT QUIZ =====
  void submitQuiz(int correctIndex) {
    if (!mounted) return;
    setState(() {
      showResult = true;
      isCorrect = selectedAnswer == correctIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonName)),
      body: FutureBuilder<DocumentSnapshot>(
        future: loadQuiz(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading quiz"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No quiz for this lesson"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final question = data["question"] ?? "No question found";
          final List options = List.from(data["options"] ?? []);
          final int correctIndex = data["correctIndex"] ?? 0;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ...List.generate(options.length, (i) {
                  return RadioListTile<int>(
                    title: Text(options[i].toString()),
                    value: i,
                    groupValue: selectedAnswer,
                    onChanged: (value) {
                      if (!mounted) return;
                      setState(() => selectedAnswer = value);
                    },
                  );
                }),
                ElevatedButton(
                  onPressed: selectedAnswer == null
                      ? null
                      : () => submitQuiz(correctIndex),
                  child: const Text("Submit"),
                ),
                if (showResult)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      isCorrect ? "Correct ✅" : "Wrong ❌",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

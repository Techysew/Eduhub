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

  Future<DocumentSnapshot> loadQuiz() {
    return FirebaseFirestore.instance
        .collection("courses")
        .doc(widget.courseId)
        .collection("quizzes")
        .doc(widget.lessonName)
        .get();
  }

  void submitQuiz(int correctIndex) {
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
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          if (!snapshot.data!.exists) {
            return const Center(child: Text("No quiz for this lesson"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final question = data["question"];
          final List options = data["options"];
          final int correctIndex = data["correctIndex"];

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...List.generate(options.length, (i) {
                  return RadioListTile(
                    title: Text(options[i]),
                    value: i,
                    groupValue: selectedAnswer,
                    onChanged: (value) =>
                        setState(() => selectedAnswer = value),
                  );
                }),
                ElevatedButton(
                    onPressed: () => submitQuiz(correctIndex),
                    child: const Text("Submit")),
                if (showResult)
                  Text(
                    isCorrect ? "Correct ✅" : "Wrong ❌",
                    style: const TextStyle(fontSize: 18),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}

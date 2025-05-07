import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  final String title;
  final List<String> questions;
  final List<String> notes;
  final List<List<String>> answers;
  final List<int> correctAnswers;

  const QuizPage({
    super.key,
    required this.title,
    required this.questions,
    required this.notes,
    required this.answers,
    required this.correctAnswers,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentIndex = 0;
  int selectedAnswer = -1;
  int correctCount = 0;

@override
Widget build(BuildContext context) {

  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 120, 204, 255),
    appBar: AppBar(
      backgroundColor: const Color.fromARGB(255, 1, 24, 36),
      centerTitle: true,
      title: Text(widget.title),
      titleTextStyle: const TextStyle(fontSize: 20, color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(12),
              color: const Color.fromARGB(255, 1, 24, 36),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentIndex + 1}. Otázka: ${widget.questions[currentIndex]}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Poznámka: ${widget.notes[currentIndex]}",
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20, top: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: selectedAnswer != -1
                  ? () {
                      if (currentIndex < widget.questions.length - 1) {
                        setState(() {
                          currentIndex++;
                          selectedAnswer = -1;
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Color.fromARGB(255, 99, 184, 230),
                            title: const Text("Konec kvízu!", style: TextStyle(color: Colors.white)),
                            content: Text("Vyřešil jsi úspěšně $correctCount/${widget.questions.length} otázek", style: TextStyle(color: Colors.white, fontSize: 18)),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text("Zavřít", style: TextStyle(color: Colors.white, fontSize: 20)),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 1, 40, 61),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                currentIndex == widget.questions.length - 1 ? 'Zobrazit výsledky' : 'Další otázka',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),

        const Spacer(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.25,
            children: List.generate(4, (index) {
            final isCorrect = widget.correctAnswers[currentIndex] == index;
            final isSelected = selectedAnswer == index;

            Color borderColor = Colors.white;
            double borderThickness = 3.0;
            if (selectedAnswer != -1) {
              if (isCorrect) {
                borderColor = const Color.fromARGB(255, 20, 243, 31);
                borderThickness = 5.0;
              } else if (isSelected) {
                borderColor = Colors.red.shade800;
                borderThickness = 5.0;
              }
            }

            return ElevatedButton(
              onPressed: selectedAnswer == -1
                  ? () {
                      setState(() {
                        selectedAnswer = index;
                        if (widget.correctAnswers[currentIndex] == index) {
                          correctCount++;
                        }
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: [
                  const Color(0xFFE53935),
                  const Color.fromARGB(255, 4, 103, 157),
                  const Color(0xFF43A047),
                  const Color.fromARGB(255, 191, 156, 2),
                ][index],
                side: BorderSide(color: borderColor, width: borderThickness),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
              ),
              child: Center(
                child: Text(
                  widget.answers[currentIndex][index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 17, color: Colors.white),
                ),
              ),
            );
          }),
          ),
        ),
      ],
    ),
  );
}


}

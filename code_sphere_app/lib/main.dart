import 'package:flutter/material.dart';
import 'pages/LoadingChapters.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
    dotenv.load(fileName: ".env");
    runApp(const CodeSphere());
}

class CodeSphere extends StatelessWidget {
  const CodeSphere({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Color.fromARGB(255, 99, 184, 230),
        body: Center(
          child: Builder(
            builder: (context) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Code Sphere',
                  style: TextStyle(
                    fontSize: 50,  
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),  // Mezera mezi textem a tlačítkem
                ElevatedButton(
                  child: const Text("Načíst kapitoly"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoadingChaptersPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 1, 24, 36),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                    textStyle: TextStyle(fontSize: 20), 
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

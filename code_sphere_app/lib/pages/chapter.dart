import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'Quiz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChapterPage extends StatefulWidget {
  final String fileName;
  final String xmlContent;
  final Directory localDir;
  final String? mp4FilePath;
  final String selectedRepo;

  const ChapterPage({
    super.key,
    required this.fileName,
    required this.xmlContent,
    required this.localDir,
    required this.mp4FilePath,
    required this.selectedRepo
  });
  @override
  _ChapterPage createState() => _ChapterPage();
}


class _ChapterPage extends State<ChapterPage> {
  String title = "";
  String definitionText = "";
  String definitionNote = "";
  String warningText = "";
  String warningNote = "";
  String codeText = "";
  String codeNote = "";
  String aiPrompt = "";
  String aiNote = "";
  String links = "";
  String linksNote = "";
  String videoFile = "";
  String videoNote = "";
  String fileName = ""; 
  String aiResponse = "";
  List<String> questions = [];
  List<String> notes = [];
  List<List<String>> answers = [];
  List<int> correctAnswers = [];
  String? apiKey ='AIzaSyAAbCZogB2s7lnE5hip2ffOVspl_W7ijQM';
  

  @override
  void initState() {
    super.initState();

  if (widget.xmlContent.isNotEmpty) {
    xmlParser(widget.xmlContent);
    }
  }
  
void _playVideo(String videoPath) async {
  final videoController = VideoPlayerController.file(File(videoPath));

  try {
    await videoController.initialize();
    videoController.play();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
            vertical: MediaQuery.of(context).size.height * 0.05,
          ),
          backgroundColor: Color.fromARGB(255, 99, 184, 230),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Přehrávání $videoFile",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      SizedBox(height: 12),
                      AspectRatio(
                        aspectRatio: videoController.value.aspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: VideoPlayer(videoController),
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              videoController.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Color.fromARGB(255, 1, 24, 36),
                              size: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                if (videoController.value.isPlaying) {
                                  videoController.pause();
                                } else {
                                  videoController.play();
                                }
                              });
                            },
                          ),
                          Expanded(
                            child: ValueListenableBuilder(
                              valueListenable: videoController,
                              builder: (context, VideoPlayerValue value, child) {
                                final duration = value.duration.inMilliseconds;
                                final position = value.position.inMilliseconds;

                                return SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 8,
                                    thumbColor: Color.fromARGB(255, 1, 24, 36),
                                    activeTrackColor: Color.fromARGB(255, 1, 24, 36),
                                    inactiveTrackColor: Colors.grey.shade700,
                                    overlayColor: Color.fromARGB(100, 1, 24, 36),
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  ),
                                  child: Slider(
                                    value: position.clamp(0, duration).toDouble(),
                                    min: 0,
                                    max: duration.toDouble(),
                                    onChanged: (newValue) {
                                      videoController.seekTo(Duration(milliseconds: newValue.toInt()));
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.fullscreen, color: Color.fromARGB(255, 1, 24, 36), size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    backgroundColor: Colors.black,
                                    body: SafeArea(
                                      child: OrientationBuilder(
                                        builder: (context, orientation) {
                                          return Center(
                                            child: Stack(
                                              alignment: Alignment.bottomCenter,
                                              children: [
                                                AspectRatio(
                                                  aspectRatio: videoController.value.aspectRatio,
                                                  child: VideoPlayer(videoController),
                                                ),
                                                Positioned(
                                                  bottom: 16,
                                                  left: 0,
                                                  right: 0,
                                                  child: Row(
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(
                                                          videoController.value.isPlaying
                                                              ? Icons.pause
                                                              : Icons.play_arrow,
                                                          color: Color.fromARGB(255, 1, 24, 36),
                                                          size: 32,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            if (videoController.value.isPlaying) {
                                                              videoController.pause();
                                                            } else {
                                                              videoController.play();
                                                            }
                                                          });
                                                        },
                                                      ),
                                                      Expanded(
                                                        child: ValueListenableBuilder(
                                                          valueListenable: videoController,
                                                          builder: (context, VideoPlayerValue value, child) {
                                                            final duration = value.duration.inMilliseconds;
                                                            final position = value.position.inMilliseconds;

                                                            return SliderTheme(
                                                              data: SliderTheme.of(context).copyWith(
                                                                trackHeight: 8,
                                                                thumbColor: Color.fromARGB(255, 1, 24, 36),
                                                                activeTrackColor: Color.fromARGB(255, 1, 24, 36),
                                                                inactiveTrackColor: Colors.grey.shade700,
                                                                overlayColor: Color.fromARGB(100, 1, 24, 36),
                                                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                                              ),
                                                              child: Slider(
                                                                value: position.clamp(0, duration).toDouble(),
                                                                min: 0,
                                                                max: duration.toDouble(),
                                                                onChanged: (newValue) {
                                                                  videoController.seekTo(Duration(milliseconds: newValue.toInt()));
                                                                },
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.fullscreen_exit, color: Color.fromARGB(255, 1, 24, 36), size: 32),
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      TextButton(
                        child: Text("Zavřít", style: TextStyle(color: Colors.white, fontSize: 20)),
                        onPressed: () {
                          videoController.dispose();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  } catch (e) {
    print('Chyba při načítání videa: $e');
  }
}

  Future<String> sendPromptToGemini(String prompt) async {
    final String url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

    final body = json.encode({
      'contents': [
        {
          'parts': [
            {'text': "$prompt. Jen 150 znaků."}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Správné parsování textu podle skutečné odpovědi
        final candidates = responseBody['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']['parts'];
          if (parts != null && parts.isNotEmpty) {
            final String text = parts[0]['text'];
            return text.trim(); // odstraníme newline
          } else {
            return 'Chyba: Prázdné parts pole.';
          }
        } else {
          return 'Chyba: Žádní kandidáti.';
        }
      } else {
        return 'Chyba při komunikaci s Gemini API: ${response.statusCode}';
      }
    } catch (e) {
      return 'Chyba při posílání požadavku: ${e.toString()}';
    }
  }



  void xmlParser(String xmlContent) {
    final document = xml.XmlDocument.parse(xmlContent);
    final chapter = document.findElements('chapter').first;

    setState(() {
      final titleElement = chapter.getElement('title');
      if (titleElement != null) {
        title = titleElement.text; 
      }

      final definitionElement = chapter.getElement('theory');
      if (definitionElement != null) {
        var textElement = definitionElement.getElement('text');
        if (textElement != null) {
          definitionText = textElement.children.map((e) => e.toXmlString()).join();
        }
        definitionNote = definitionElement.getElement('note')?.text ?? '';
      }
      final warningElement = chapter.getElement('warning');
      if (warningElement != null) {
        warningText = warningElement.getElement('text')?.text ?? '';
        warningNote = warningElement.getElement('note')?.text ?? '';
      }

      final codeElement = chapter.getElement('code');
      if (codeElement != null) {
        codeText = codeElement.getElement('text')?.text ?? '';
        codeNote = codeElement.getElement('note')?.text ?? '';
      }

      final promptElement = chapter.getElement('ai_prompt');
      if (promptElement != null) {
        aiPrompt = promptElement.getElement('prompt')?.text ?? '';
        aiNote = promptElement.getElement('note')?.text ?? '';
      }

      final linksElement = chapter.getElement('links');
      if (linksElement != null) {
        final linksList = linksElement.findElements('link').map((e) => e.text).join(', ');
        links = linksList;
        linksNote = linksElement.getElement('note')?.text ?? '';
      }

      final videoElement = chapter.getElement('video');
      if (videoElement != null) {
        videoFile = videoElement.getElement('file_name')?.text ?? '';
        videoNote = videoElement.getElement('note')?.text ?? '';
      }

      final quizElement = chapter.getElement('quiz');
      if (quizElement != null) {
        questions.clear();
        notes.clear();
        answers.clear();
        correctAnswers.clear();

        final questionElements = quizElement.findElements('question');
        for (var question in questionElements) {
          final qText = question.getElement('text')?.text ?? '';
          final qNote = question.getElement('note')?.text ?? '';

          final answerElements = question.findElements('answer');
          final List<String> answerTexts = [];
          int correctIndex = -1;

          int index = 0;
          for (var answer in answerElements) {
            final answerText = answer.text;
            answerTexts.add(answerText);
            final correctAttr = answer.getAttribute('correct');
            if (correctAttr?.toLowerCase() == 'true') {
              correctIndex = index;
            }
            index++;
          }

          questions.add(qText);
          notes.add(qNote);
          answers.add(answerTexts);
          correctAnswers.add(correctIndex);
        }
      }
    });
  }


  List<TextSpan> parseTaggedText(String input) {
    final tagRegExp = RegExp(r'<(b|i|a|pre)>(.*?)<\/\1>', dotAll: true);
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in tagRegExp.allMatches(input)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: input.substring(lastMatchEnd, match.start)));
      }

      final tag = match.group(1);
      final content = match.group(2);

      TextStyle style;

      switch (tag) {
        case 'b':
          style = TextStyle(fontWeight: FontWeight.bold);
          break;
        case 'i':
          style = TextStyle(fontStyle: FontStyle.italic);
          break;
        case 'a':
          style = TextStyle(decoration: TextDecoration.underline, color: Colors.blue);
          break;
        case 'pre':
          style = TextStyle(fontFamily: 'Courier', backgroundColor: Colors.black12);
          break;
        default:
          style = TextStyle();
      }

      spans.add(TextSpan(text: content, style: style));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < input.length) {
      spans.add(TextSpan(text: input.substring(lastMatchEnd)));
    }

    return spans;
  }


  Future<void> downloadAndSaveZip(String url) async {
  try {
    print('${widget.localDir.path}/${widget.fileName}/$videoFile');
    final response = await http.get(Uri.parse(url));
    
    if (response.statusCode != 200) {
      throw ('Kód: ${response.statusCode}');
    }

    final file = File('${widget.localDir.path}/${widget.fileName}');
    
    if (await file.exists()) {
      throw ('${widget.fileName} již máte stáhlý.');
    }

    await file.writeAsBytes(response.bodyBytes);
    debugPrint('Soubor uložen: ${file.path}');
    
  } catch (e) { 
    if (e.toString().contains('SocketException')) {
      throw 'Nemáš připojení k internetu.';
    } else {
      throw 'Chyba při stahování souboru: $e';
    }
  }
}




@override
Widget build(BuildContext context) {
  final bool isResponseAvailable = aiResponse.isNotEmpty;

  return Scaffold(
    backgroundColor: Color.fromARGB(255, 99, 184, 230),
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 1, 24, 36),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          title,
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.download, color: Colors.white),
          onPressed: () async {
            final url = 'https://raw.githubusercontent.com/Hamzic12/${widget.selectedRepo}/main/${widget.fileName}';
            print(url);
             try {
                    await downloadAndSaveZip(url);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Soubor byl úspěšně stažen.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e ')),
                    );
                  }
                }
        )
      ]
    ),
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            if (definitionText.isNotEmpty)   
              Text("Definice:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    children: parseTaggedText(definitionText),
                  ),
                ),
              ),
              if (definitionNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4),
                  child: Text(
                    "Poznámka: $definitionNote",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                ),
              SizedBox(height: 12),
              if (warningText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    border: Border.all(color: Colors.red[800]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    warningText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[900],
                    ),
                  ),
                ),
              SizedBox(height: 12),
              if (codeText.isNotEmpty) 
                Text("Kód:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  color: Color.fromARGB(255, 1, 24, 36),
                  padding: EdgeInsets.all(8),
                  child: SelectableText(
                    codeText,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 15,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              if (codeNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "Poznámka: $codeNote",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                ),
              SizedBox(height: 12),
              if (links.isNotEmpty)
                Text("Odkazy:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: links
                        .split(RegExp(r',\s*'))
                        .where((link) => link.trim().isNotEmpty)
                        .map((link) => InkWell(
                              onTap: () {
                                final uri = Uri.parse(link.trim());

                                launchUrl(uri, mode: LaunchMode.externalApplication).then((success) {
                                  if (!success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Nepodařilo se otevřít odkaz: $link')),
                                    );
                                  }
                                }).catchError((error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Chyba při otevírání odkazu: $error')),
                                  );
                                });
                              },
                              child: Text(
                                  link,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 0.5,
                                        color: Color.fromARGB(255, 1, 24, 36), 
                                      ),
                                    ],
                                  ),
                                  ),
                            ))
                        .toList(),
                  ),
                ),
              if (linksNote.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4),
                  child: Text(
                    "Poznámka: $linksNote",
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white),
                  ),
                ),
                SizedBox(height: 12),
              if (videoFile.isNotEmpty) ...[
                  const Text(
                    "Video:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        _playVideo(widget.mp4FilePath!);
                      },
                      child: Text(videoFile, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(offset: Offset(0, 2), blurRadius: 0.5, color: Color.fromARGB(255, 1, 24, 36))])),

                    ),
                  ),
                ],
                SizedBox(height: 4),
                if (videoNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Poznámka: $videoNote",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 12),
                if (aiPrompt.isNotEmpty)
                  Text("Gemini prompt:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      children: parseTaggedText(aiPrompt)
                      ),
                    ),
                  ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        String response = await sendPromptToGemini(aiPrompt);
                        response = response.replaceAll(RegExp(r"^`{3}|`{3}$"), "");
                        setState(() {
                          aiResponse = response;
                        });
                      },
                      // ignore: sort_child_properties_last
                      child: Text("Poslat prompt", textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 1, 24, 36),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        return ElevatedButton.icon(
                          onPressed: isResponseAvailable
                              ? () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: Color.fromARGB(255, 99, 184, 230),
                                        title: Text("Odpověď od Gemini", style: TextStyle(color: Colors.white)),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("Prompt:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                              SizedBox(height: 4),
                                              Text(aiPrompt, style: TextStyle(color: Colors.white)),
                                              SizedBox(height: 6),
                                              Text("Odpověď:",  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 10)),
                                              SizedBox(height: 12),
                                              Container(
                                                color: Color.fromARGB(255, 1, 24, 36),
                                                padding: EdgeInsets.all(8),
                                                child: SelectableText(
                                                  aiResponse,
                                                  style: TextStyle(
                                                    fontFamily: 'Courier',
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                              if (aiNote.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 12.0),
                                                  child: Text(
                                                    "Poznámka: $aiNote",
                                                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white, fontSize: 12),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            child: Text("Zavřít", style: TextStyle(color: Colors.white)),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              : null,
                          icon: Icon(Icons.chat_bubble_outline),
                          label: Text("Zobrazit odpověď", textAlign: TextAlign.center),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isResponseAvailable
                                ? Color.fromARGB(255, 1, 24, 36)
                                : Colors.grey,
                            foregroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                     onPressed: () {
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(
                            questions: questions,
                            notes: notes,
                            answers: answers,
                            correctAnswers: correctAnswers,
                          ),
                        ));
                      },
                      // ignore: sort_child_properties_last
                      child: Text("Spustit kvíz", textAlign: TextAlign.center),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 1, 24, 36),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
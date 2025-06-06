// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Chapter.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoadingChaptersPage extends StatefulWidget {
  const LoadingChaptersPage({super.key});
  
  @override
  _LoadingChaptersPage createState() => _LoadingChaptersPage();
}

class _LoadingChaptersPage extends State<LoadingChaptersPage> {
  List<String> zipFilesList = [];
  String fileName = "";
  String xmlContent = "";
  String filesContents = "";
  dynamic uri;
  String? mp4FilePath;
  String repoName = "";
  late Directory localDir;
  List<String> localZipFiles = [];
  List<String> repoList = [];
  
  @override
  void initState() {
    super.initState();
    getBaseDir();
    Future.delayed(const Duration(milliseconds: 500), () async {
      await loadRepoList();
      setState(() {
        if (repoList.isNotEmpty) {
          repoName = repoList.first;
        }
      });
      fetchFileNames();
    });
  }


 void zipParser(dynamic zipSource, String zipName, Function callback) async {
  late List<int> bytes;
  if (zipSource.startsWith('http')) {
    
    try {
       
      final response = await http.get(Uri.parse(zipSource));
      if (response.statusCode == 200) {
        bytes = response.bodyBytes;
      } else {
        filesContents = "Nepodařilo se stáhnout ZIP soubor z GitHubu.";
        callback();
        return;
      }
    } catch (e) {
      filesContents = "Chyba při stahování ZIP souboru: $e";
      callback();
      return;
    }
  } else if (zipSource is String) {
    try {
      final file = File(zipSource);
      bytes = await file.readAsBytes();
    } catch (e) {
      filesContents = "Chyba při čtení ZIP souboru: $e";
      callback();
      return;
    }
  } else {
    filesContents = "Neplatný typ pro zipSource.";
    callback();
    return;
  }

  final archive = ZipDecoder().decodeBytes(bytes);
  filesContents = archive.map((file) => file.name).join('\n');
  fileName = zipName;

  for (var file in archive) {
    if (file.name.endsWith('.xml')) {
      final xmlString = utf8.decode(file.content);
      xmlContent = xmlString;
    } else if (file.name.endsWith('.mp4')) {
      if (zipSource is String && zipSource.startsWith('http')) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(file.content);
        mp4FilePath = tempFile.path;
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${file.name}');
        await tempFile.writeAsBytes(file.content);
        mp4FilePath = tempFile.path;
      }
    }
  }

    callback();
  }



  Future<void> getBaseDir() async {
    Directory? newDir;

    if (Platform.isAndroid) {
      final directoryPath = '/storage/emulated/0/Documents/CS_chapters';
      newDir = Directory(directoryPath);

      if (!(await newDir.exists())) {
        await newDir.create(recursive: true);
        debugPrint('Složka vytvořena: ${newDir.path}');
      } else {
        debugPrint('Složka již existuje: ${newDir.path}');
      }
    } else if (Platform.isIOS) {
      final baseDir = await getApplicationDocumentsDirectory();
      final directoryPath = '${baseDir.path}/CS_Chapters';
      newDir = Directory(directoryPath);

      if (!(await newDir.exists())) {
        await newDir.create(recursive: true);
        debugPrint('Složka vytvořena: ${newDir.path}');
      } else {
        debugPrint('Složka již existuje: ${newDir.path}');
      }
    } else {
      throw UnsupportedError('Nepodporovaná platforma');
    }


    final repoFile = File('${newDir.path}/repo.txt');
    bool repoFileExists = await repoFile.exists();

    if (!repoFileExists) {
      await repoFile.writeAsString('Code-Sphere-Chapters\n', mode: FileMode.write);
      debugPrint('Soubor repo.txt vytvořen v: ${repoFile.path}');
    } else {
      debugPrint('Soubor repo.txt již existuje: ${repoFile.path}');
    }

    setState(() {
      localDir = newDir!; 
    });
  }

  Future<void> fetchFileNames() async {
    String githubURL = "https://api.github.com/repos/Hamzic12/$repoName/contents/";
    try {
      await getBaseDir();

      localZipFiles.clear();
      zipFilesList.clear();

      final localzip = localDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.zip'))
          .map((file) => file.uri.pathSegments.last)
          .toList();

      localzip.sort((a, b) {
        return extractNumberFromFileName(a).compareTo(extractNumberFromFileName(b));
      });

      setState(() {
        localZipFiles = localzip;
        zipFilesList = List.from(localzip);  // duplikace jako nový list
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Načítají se soubory z Github repozitáře: $repoName'),
        duration: Duration(milliseconds: 1000),
        )
      );

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none || repoName.isNotEmpty) {
        final response = await http.get(Uri.parse(githubURL));

        if (response.statusCode == 200) {
          final List<dynamic> files = json.decode(response.body);
          final remoteZipFiles = files
              .where((f) => f['name'].toString().endsWith('.zip'))
              .map((f) => f['name'] as String)
              .toList();

          for (var file in remoteZipFiles) {
            if (!zipFilesList.contains(file)) {
              zipFilesList.add(file);
            }
          }

        
        } 
        else {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.statusCode == 404
                  ? 'Chyba: repozitář neexistuje'
                  : 'Chyba při načítání Github souborů: ${response.statusCode}',
              ),
              duration: Duration(milliseconds: 1200),
            ),
          );
        }
      }

      zipFilesList.sort((a, b) {
        return extractNumberFromFileName(a).compareTo(extractNumberFromFileName(b));
      });

      setState(() {
        zipFilesList;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'))
      );
    }
  }

  int extractNumberFromFileName(String fileName) {
    final match = RegExp(r'^(\d+)').firstMatch(fileName);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  Future<void> loadRepoList() async {
    final file = File('${localDir.path}/repo.txt');
    if (await file.exists()) {
      final lines = await file.readAsLines();
      setState(() {
        repoList = lines.where((line) => line.trim().isNotEmpty).toList();
      });
    }
  }

  void deleteSelectedRepo() async {
    try {
      final file = File('${localDir.path}/repo.txt');
      if (!await file.exists()) return;

      List<String> lines = await file.readAsLines();
      int deletedIndex = repoList.indexOf(repoName);

      lines.removeWhere((line) => line.trim() == repoName.trim());
      await file.writeAsString(lines.join('\n') + '\n');

      setState(() {
        if (deletedIndex >= 0 && deletedIndex < repoList.length) {
          repoList.removeAt(deletedIndex);
        }

        if (repoList.isNotEmpty) {
          if (deletedIndex < repoList.length) {
            repoName = repoList[deletedIndex]; 
          } else if (deletedIndex - 1 >= 0) {
            repoName = repoList[deletedIndex - 1];
          } else {
            repoName = '';
          }
          fetchFileNames();
        } else {
          repoName = '';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chyba při mazání')),
      );
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final TextEditingController _repoController = TextEditingController();

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 99, 184, 230),
      appBar:AppBar(
      backgroundColor: Color.fromARGB(255, 1, 24, 36),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 50.0),
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Color.fromARGB(255, 99, 184, 230),
                  title: const Text('Vyberte repozitář', style: TextStyle(color: Colors.white)),
                  content: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Repozitáře", style: TextStyle(color: Colors.black)),
                    value: null,
                    dropdownColor: Color.fromARGB(255, 1, 24, 36),
                    iconEnabledColor: Colors.white,
                    items: repoList.map((repo) {
                      return DropdownMenuItem<String>(
                        value: repo,
                        child: Text(repo, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          repoName = value;
                          loadRepoList();
                          fetchFileNames();
                        });
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              );
            },
            child: const Text(
              "Kapitoly",
              style: TextStyle(color: Colors.white, fontSize: 25, decoration: TextDecoration.underline,decorationColor: Colors.white, decorationThickness: 2.0),
            ),
          ),
        ),
      ],
    ),
  actions: [
    IconButton(
      icon: Icon(
        Icons.delete,
        color: repoList.isEmpty ? Color.fromARGB(255, 1, 24, 36) : Colors.redAccent,
      ),
      iconSize: 25,
      onPressed: repoList.isEmpty
          ? null
          : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Color.fromARGB(255, 99, 184, 230),
                  title: const Text('Potvrzení smazání', style: TextStyle(color: Colors.white)),
                  content: Text('Chcete smazat odkaz k repozitáři: $repoName?', style: const TextStyle(color: Colors.white)),
                  actions: [
                    TextButton(
                      onPressed: () {
                        deleteSelectedRepo();
                        Navigator.pop(context);
                      },
                      child: const Text('Smazat', style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Zavřít', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
                    ),
                  ],
                ),
              );
            },
          ),
    const SizedBox(width: 10),
    IconButton(
      icon: const Icon(Icons.refresh, color: Colors.white),
      onPressed: () async {
        try {
          await fetchFileNames();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chyba při aktualizaci souboru: $e')),
          );
        }
      },
    ),
  ],
),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: zipFilesList.length,
        itemBuilder: (context, index) {
          String chapter = zipFilesList[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 1, 24, 36),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                if (localZipFiles.contains(chapter)) {
                  uri = '${localDir.path}/$chapter';
                } else {
                  uri = "https://raw.githubusercontent.com/Hamzic12/$repoName/main/$chapter";
                }

                zipParser(uri, chapter, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChapterPage(
                        fileName: fileName,
                        xmlContent: xmlContent,
                        mp4FilePath: mp4FilePath,
                        localDir: localDir,
                        selectedRepo: repoName,
                      ),
                    ),
                  ).then((_) {
                    fetchFileNames();
                  });
                });
              },
              child: Text(
                chapter.replaceAll('.zip', ''),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 1, 24, 36),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: Color.fromARGB(255, 99, 184, 230),
                title: const Text(
                  "Přidat repozitář",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nápověda: github.com/Username/nazev-repozitráře",
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _repoController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        hintText: 'Zadejte nazev-repozitráře',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final input = _repoController.text.trim();
                      if (input.isNotEmpty) {
                        try {
                          final file = File('${localDir.path}/repo.txt');
                          await file.writeAsString('$input\n', mode: FileMode.append);
                          repoName = input;
                          fetchFileNames();

                          setState(() {
                            repoList.add(input);
                          });

                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chyba: $e')),
                          );
                        }
                      }
                    },
                    child: const Text("Přidat", style: TextStyle(fontSize: 16,color: Colors.white)),
                  )
                ],
              );
            },
          );
        },
      ),
    );
  }

}
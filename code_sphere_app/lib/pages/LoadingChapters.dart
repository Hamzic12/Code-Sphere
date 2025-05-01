// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chapter.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
    fetchFileNames(); 
    requestStoragePermission();
    loadRepoList();
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


Future<void> requestStoragePermission() async {
  bool permissionGranted = false;

  if (Platform.isAndroid) {
    if (await Permission.manageExternalStorage.isGranted ||
        await Permission.storage.isGranted) {
      permissionGranted = true;
    } else {
      var status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        permissionGranted = true;
      } else {
        // fallback pro starší verze
        var legacyStatus = await Permission.storage.request();
        permissionGranted = legacyStatus.isGranted;
      }
    }
  } else if (Platform.isIOS) {
    permissionGranted = true;
  }

  if (permissionGranted) {
    await getBaseDir();
  } else {
    debugPrint('Oprávnění nebylo uděleno.');
  }
}


Future<void> getBaseDir() async {
  Directory? newDir;

  if (Platform.isAndroid) {
    final directoryPath = '/storage/emulated/0/Documents/CS_chapters';
    newDir = Directory(directoryPath);

    // Pokud složka neexistuje, vytvoříme ji
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

    // Pokud složka neexistuje, vytvoříme ji
    if (!(await newDir.exists())) {
      await newDir.create(recursive: true);
      debugPrint('Složka vytvořena: ${newDir.path}');
    } else {
      debugPrint('Složka již existuje: ${newDir.path}');
    }
  } else {
    throw UnsupportedError('Nepodporovaná platforma');
  }

   // Zkontrolujeme existenci souboru repo.txt
  final repoFile = File('${newDir.path}/repo.txt');
  bool repoFileExists = await repoFile.exists();

  // Pokud soubor neexistuje, vytvoříme nový soubor
  if (!repoFileExists) {
    await repoFile.writeAsString('');
    debugPrint('Soubor repo.txt vytvořen v: ${repoFile.path}');
  } else {
    debugPrint('Soubor repo.txt již existuje: ${repoFile.path}');
  }

  setState(() {
    localDir = newDir!;  // Nastavení hodnoty pro localDir
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
      zipFilesList = List.from(localzip);  // důležité - duplikace jako nový list
    });

    debugPrint('Lokální soubory: ${localZipFiles.join(', ')}');
    
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      final response = await http.get(Uri.parse(githubURL));

      if (response.statusCode == 200) {
        final List<dynamic> files = json.decode(response.body);
        final remoteZipFiles = files
            .where((f) => f['name'].toString().endsWith('.zip'))
            .map((f) => f['name'] as String)
            .toList();

        // Přidej jen nové soubory z GitHubu
        for (var file in remoteZipFiles) {
          if (!zipFilesList.contains(file)) {
            zipFilesList.add(file);
          }
        }

        debugPrint('Přidané z GitHubu: ${remoteZipFiles.join(', ')}');
      } else {
        debugPrint('Chyba při načítání GitHub souborů: ${response.statusCode}');
      }
    }

    zipFilesList.sort((a, b) {
      return extractNumberFromFileName(a).compareTo(extractNumberFromFileName(b));
    });

    debugPrint('Finální seřazené: ${zipFilesList.join(', ')}');

    setState(() {
      zipFilesList;
    });
  } catch (e) {
    debugPrint('Chyba: $e');
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


@override
Widget build(BuildContext context) {
  final TextEditingController _repoController = TextEditingController();
  String selectedRepo = repoList.isNotEmpty ? repoList.first : 'Seznam kapitol';

   return Scaffold(
      backgroundColor: const Color.fromARGB(255, 99, 184, 230),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 24, 36),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Row(
  children: [

    Container(
  width: 210, // Šířka samotného tlačítka
  child: DropdownButtonHideUnderline(
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 1, 24, 36),
      borderRadius: BorderRadius.circular(8),
    ),
    child: DropdownButton<String>(
      isExpanded: true,
      hint: const Text("Kapitoly", style: TextStyle(color: Colors.white,fontSize: 20)),
      value: null, // nezobrazuj aktuální hodnotu
      dropdownColor: const Color.fromARGB(255, 1, 24, 36),
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
            selectedRepo = value;
            repoName = selectedRepo;
            loadRepoList();
            fetchFileNames();
          });
        }
      },
    ),
  ),
),
    ),
  ],
),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: fetchFileNames,
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
              backgroundColor: const Color.fromARGB(255, 1, 24, 36),
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
      backgroundColor: const Color.fromARGB(255, 1, 24, 36),
      child: const Icon(Icons.add, color: Colors.white),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 99, 184, 230),
              title: const Text("Přidat záznam", style: TextStyle(color: Colors.white)),
              content: TextField(
                controller: _repoController,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(
                  hintText: 'Zadej název',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final input = _repoController.text.trim();
                    if (input.isNotEmpty) {
                      final file = File('${localDir.path}/repo.txt');
                      await file.writeAsString('$input\n', mode: FileMode.append);
                      setState(() {
                        repoList.add(input);
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Přidat", style: TextStyle(color: Colors.white)),
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
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
  String githubURL = "https://api.github.com/repos/Hamzic12/Code-Sphere-Chapters/contents/";
  String fileName = "";
  String xmlContent = "";
  String filesContents = "";
  dynamic uri;
  String? mp4FilePath;
  late Directory localDir;
  List<String> localZipFiles = [];
  @override
  void initState() {
    super.initState();
    fetchFileNames(); 
    requestStoragePermission();
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
    setState(() {
      localDir = newDir!;
    });

    }

bool checkZips(String chapterName) {
  for (var file in localZipFiles){
    if (file == chapterName){
      return true;
    }
  }
  return false;
}

Future<void> fetchFileNames() async {
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 99, 184, 230), // Světle modré pozadí
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 1, 24, 36), // Tmavě modrá
        foregroundColor: Colors.white,
        title: Text(
          "Seznam kapitol",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
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
                } 
                else {
                  uri = "https://raw.githubusercontent.com/Hamzic12/Code-Sphere-Chapters/main/$chapter";
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
    );
  }
}

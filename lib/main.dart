// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:process_run/shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'wow_torrent.dart';

const String title = 'Arena-Tournament.net Launcher';
final closeButtonColors = WindowButtonColors(
    mouseOver: const Color.fromARGB(51, 255, 255, 255),
    mouseDown: const Color.fromARGB(51, 255, 255, 255),
    iconNormal: Colors.white,
    iconMouseOver: Colors.white);

void main() {
  runApp(const MyApp());
  // Add this code below
  doWhenWindowReady(() {
    final win = appWindow;
    const initialSize = Size(415, 270);
    win.minSize = initialSize;
    win.maxSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = title;
    win.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color.fromARGB(255, 39, 39, 39),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(backgroundColor: Colors.indigo),
        appBarTheme: const AppBarTheme(
          color: Colors.indigo,
        ),
        cardColor: const Color(0xFF202020),
      ),
      debugShowCheckedModeBanner: false,
      home: WindowBorder(
          color: Colors.black,
          width: 0.5,
          child: const MyHomePage(title: title)),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late String installPath;
  late String downloadProgress;
  late String downloadSpeed;
  late String eta;
  late double progress;
  late bool downloading;
  late bool fileAlloc;
  late bool initDownload;
  late bool paused;

  Future<SharedPreferences> _getPrefs() async {
    return (await SharedPreferences.getInstance());
  }

  bool isPlayable() {
    return !initDownload &&
        !downloading &&
        !fileAlloc &&
        File("$installPath\\Wow.exe").existsSync();
  }

  String getAria2cExe() {
    String mainPath = Platform.resolvedExecutable;
    mainPath = mainPath.substring(0, mainPath.lastIndexOf("\\"));
    return "$mainPath\\data\\flutter_assets\\assets\\exe\\aria2cj.exe";
  }

  void setInstallPath(String path) {
    setState(() {
      installPath = path;
      _getPrefs().then((sp) => {sp.setString("installPath", installPath)});
    });
  }

  @override
  void initState() {
    super.initState();
    downloadProgress = "0mb/0gb(0%)";
    downloadSpeed = "0mb/s";
    eta = "0m0s";
    progress = 0;
    installPath = "";
    downloading = false;
    fileAlloc = false;
    initDownload = false;
    paused = false;
    _getPrefs().then((sp) => {getInstallPath(sp)});
  }

  void getInstallPath(SharedPreferences sp) {
    setState(() {
      installPath = sp.getString("installPath") ?? "";
      if (installPath != "") {
        if (resumeable()) {
          downloading = true;
          paused = true;
        }
      }
    });
  }

  void _setRealmlist() async {
    var shell = Shell(stdout: null, verbose: false);
    var command = "echo set realmlist logon.arena-tournament.net>";
    var enUS = "$installPath\\Data\\enUS\\Realmlist.wtf";
    var enGB = "$installPath\\Data\\enGB\\Realmlist.wtf";
    try {
      if (await File(enUS).exists()) {
        await shell.run('''$command "$enUS"''');
      } else if (await File(enGB).exists()) {
        await shell.run('''$command "$enGB"''');
      }
    } on ShellException catch (_) {
      // We might get a shell exception
    }
  }

  bool resumeable() {
    return File(
            "${File(installPath).parent.path}\\World of Warcraft 3.3.5a.aria2")
        .existsSync();
  }

  void _launchGame() async {
    _setRealmlist();
    var controller = ShellLinesController();
    var shell = Shell(stdout: controller.sink, verbose: false);
    try {
      await shell.run('''"$installPath\\Wow.exe"''');
    } on ShellException catch (_) {
      // We might get a shell exception
    }
  }

  void _startDownload() async {
    if (installPath.contains("World of Warcraft 3.3.5a")) {
      setInstallPath(installPath.replaceAll("\\World of Warcraft 3.3.5a", ""));
    }
    var downloadPath = installPath;
    setInstallPath("$installPath\\World of Warcraft 3.3.5a");

    var controller = ShellLinesController();
    var shell =
        Shell(stdout: controller.sink, verbose: false, runInShell: false);
    bool wasPaused = paused;
    setState(() {
      paused = false;
      initDownload = true;
      progress = 0;
    });
    bool killed = false;
    controller.stream.listen((event) {
      print(event);

      if (killed) {
        return;
      }
      // Handle output

      setState(() {
        if (event.contains("FileAlloc:") ||
            event.contains("Allocating disk space")) {
          // we are allocating disk space
          fileAlloc = true;
          downloading = true;
          initDownload = false;
        } else if (event.contains("ETA:")) {
          // downloading
          downloading = true;
          fileAlloc = false;
          initDownload = false;
          downloadProgress = event
              .split(" ")[1]
              .replaceAll("KiB", "kb")
              .replaceAll("MiB", "mb")
              .replaceAll("GiB", "gb");
          var percString = downloadProgress.split("(")[1].replaceAll("%)", "");
          progress = int.parse(percString) / 100;
          downloadSpeed = event
              .split(" ")[4]
              .replaceAll("DL:", "")
              .replaceAll("KiB", "kb/s")
              .replaceAll("MiB", "mb/s")
              .replaceAll("GiB", "gb/s");
          eta = event.split(" ")[5].replaceAll("ETA:", "").replaceAll("]", "");
        } else if (paused ||
            event.contains(" SEED(") ||
            event.contains("Exception caught")) {
          // done
          downloading = paused;
          fileAlloc = false;
          initDownload = false;
          killed = true;
          shell.kill(ProcessSignal.sigint);
          downloadSpeed = "0mb/s";
          eta = "Paused";
        }
      });
    });
    try {
      var path = getAria2cExe();
      var link = WowTorrent.getMagnetLink();
      var command = path;
      command += " $link";
      command += ' -d "$downloadPath"';
      command += ' --auto-file-renaming=false';
      command += ' --auto-save-interval=1';
      command += ' --stop-with-process=$pid';
      command += wasPaused ? ' --continue=true' : '';
      await shell.run(command);
    } on ShellException catch (_) {
      // We might get a shell exception
    }
  }

  void _selectNewFolder() async {
    _selectFolder("Select a folder to download to", false);
  }

  void _selectExistingFolder() async {
    _selectFolder("Select an existing folder containing Wow.exe", true);
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text(
                    style: TextStyle(fontWeight: FontWeight.w400),
                    'Invalid client folder\nWow.exe not found'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Okay'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _selectFolder(String dialogTitle, bool existing) async {
    String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath(dialogTitle: dialogTitle);

    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      if (selectedDirectory != null) {
        if (existing && !File("$selectedDirectory\\Wow.exe").existsSync()) {
          _showMyDialog();
        } else {
          setInstallPath(selectedDirectory);
          if (!existing) {
            _startDownload();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return MoveWindow(
        child: Container(
            alignment: Alignment.centerLeft,
            child: Scaffold(
              appBar: AppBar(
                flexibleSpace: MoveWindow(),
                // Here we take the value from the MyHomePage object that was created by
                // the App.build method, and use it to set our appbar title.
                title: const Text(title),
                actions: [CloseWindowButton(colors: closeButtonColors)],
              ),
              body:
                  Column(mainAxisAlignment: MainAxisAlignment.start, children: <
                      Widget>[
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        if (!isPlayable()) ...[
                          Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Tooltip(
                                  message:
                                      "Download the World of Warcraft 3.3.5a Client",
                                  child: ElevatedButton(
                                      onPressed: File("$installPath\\Wow.exe")
                                              .existsSync()
                                          ? null
                                          : _selectNewFolder,
                                      child: const Text("Download Client")))),
                          Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Tooltip(
                                  message:
                                      "Select an existing client folder containing Wow.exe (3.3.5a)",
                                  child: ElevatedButton(
                                      onPressed: !downloading && !isPlayable()
                                          ? _selectExistingFolder
                                          : null,
                                      child: const Text("Choose Client")))),
                        ]
                      ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Tooltip(
                            message:
                                "Open Wow.exe (3.3.5a) using the Arena-Tournament.net realmlist",
                            child: ElevatedButton(
                                onPressed: isPlayable() ? _launchGame : null,
                                child:
                                    const Text("Launch Arena-Tournament.net"))),
                        PopupMenuButton<int>(
                            tooltip: "Options",
                            splashRadius: 15,
                            iconSize: 25,
                            icon: const Icon(Icons.settings),
                            onSelected: (c) {},
                            position: PopupMenuPosition.under,
                            enabled: isPlayable(),
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<int>>[
                                  PopupMenuItem(
                                    value: 0,
                                    onTap: () {
                                      setState(() {
                                        setInstallPath("");
                                      });
                                    },
                                    child: const Text("Forget Client Path"),
                                  )
                                ]),
                      ]),
                ),
                Flex(direction: Axis.vertical, children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            if (initDownload) ...[
                              const Flexible(
                                child: Text(
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                    "Initializing Download"),
                              )
                            ],
                            if (fileAlloc && !initDownload) ...[
                              const Flexible(
                                child: Text(
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                    "Allocating Disk Space"),
                              )
                            ],
                            if (downloading && !initDownload && !fileAlloc) ...[
                              Flexible(
                                child: Text(
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.end,
                                    "$downloadProgress | $downloadSpeed | ETA: $eta"),
                              )
                            ]
                          ])),
                  if (downloading || initDownload) ...[
                    Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: LinearProgressIndicator(
                                  semanticsLabel: "Download Progress",
                                  minHeight: 15,
                                  value: progress,
                                ),
                              ),
                              IconButton(
                                  splashRadius: 12,
                                  iconSize: 20,
                                  onPressed:
                                      (downloading || initDownload || fileAlloc)
                                          ? () {
                                              if (paused) {
                                                _startDownload();
                                              } else {
                                                paused = true;
                                              }
                                            }
                                          : null,
                                  icon: paused
                                      ? const Icon(Icons.play_arrow)
                                      : const Icon(Icons.cancel))
                            ]))
                  ],
                ]),
                const Spacer(),
              ]), // This trailing comma makes auto-formatting nicer for build methods.
            )));
  }
}

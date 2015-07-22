library dartnow.dartnow_manager;

import 'package:http/http.dart';
import 'dart:async';
import 'dart:convert';
import 'package:dartnow_cli/dart_snippet.dart';
import 'package:github/server.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:prompt/prompt.dart';

main() async {
  var manager = new DartNowManager();

  await manager.updateAllSnippets();
}

class DartNowManager {
  String playgroundDir;

  String outputDir;

  Map config;
  Authentication auth;
  GitHub gitHub;

  DartNowManager() {
    config = new File('dartnow.json').existsSync()
        ? JSON.decode(new File('dartnow.json').readAsStringSync())
        : null;
    String username, password;
    if (config != null) {
      username = config['username'];
      password = config['password'];
      playgroundDir = config['playgroundDir'];
      outputDir = config['outputDir'];
    } else {
      username = askSync(new Question('Github Username'));
      password = askSync(new Question('Github Password', secret: true));
      playgroundDir = askSync(new Question('PlaygroundDir'));
      outputDir = askSync(new Question('PlaygroundDir'));
    }
    auth = new Authentication.basic(username, password);
    gitHub = createGitHubClient(auth: auth);
  }

  updateAllSnippets() async {
    List<String> ids = await getGistIds();
    for (String id in ids) {
      await updateSnippet(id);
    }
  }

  updateSnippet(String id) async {
    Gist gist = await getGist(id);
    print(gist.id);
    DartSnippet snippet = new DartSnippet.fromGist(gist);
    await snippet.addToFireBase();
    await snippet.updateReadme();
    await snippet.updateGistDescription();
    await snippet.updatePubSpec();
  }

  Future<List<String>> getGistIds() async {
    Response response = await get(
        'https://dartnow.firebaseio.com/gists.json?auth=l9UAg0tt6zlx1wuoaikhg32Q2YcLHgRycBwa2QH4');
    var ids = JSON.decode(response.body).keys.toList();
    File config = new File('dartnow.json');
    Map json = JSON.decode(config.readAsStringSync());
    json['gists'] = ids;
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    config.writeAsStringSync(encoder.convert(json));
    return ids;
  }

  cloneGist(String snippetName, String url) {
    String outputDir = '/Users/test/dartnow_gists/${snippetName}';
    // clone the gist to the outputdir
    Process.runSync('git', ['clone', url, outputDir]);
    Process.runSync('pub', ['get'], workingDirectory: outputDir);
  }

  Future<Gist> createGist(String inputDir) async {
    // fetch the gist
    Directory dir = new Directory('/Users/test/dartnow_gists/playground');

    if (!dir.existsSync()) {
      throw 'Directory doesnt exists...';
    }

    List<FileSystemEntity> allFiles = dir.listSync();
    allFiles.removeWhere((file) => file is Directory);
    allFiles.removeWhere((file) => file.path.contains('pubspec.lock'));
    allFiles.removeWhere((file) => file.path.contains('.packages'));

    Map<String, String> files = new Map.fromIterable(allFiles,
        key: (File file) => path.basename(file.path),
        value: (File file) => file.readAsStringSync());

    Gist gist = await gitHub.gists.createGist(files, public: true);
    print('Gist created at ${gist.htmlUrl}');
    return gist;
  }

  void resetPlayground() {
    new File('$playgroundDir/pubspec.yaml').writeAsStringSync('''
name:${' '}
description: |
  ''');
    new File('$playgroundDir/main.dart').writeAsStringSync('''
main() {
${'  '}
}''');
    new File('$playgroundDir/index.html').writeAsStringSync('''
<!doctype html>
<html>
  <head>
  </head>
  <body>
    <script type="application/dart" src="main.dart"></script>
  </body>
</html>
''');
    if (new File('$playgroundDir/styles.css').existsSync()) {
      new File('$playgroundDir/styles.css').deleteSync();
    }

    if (new File('$playgroundDir/pubspec.lock').existsSync()) {
      new File('$playgroundDir/pubspec.lock').deleteSync();
    }
    if (new File('$playgroundDir/.packages').existsSync()) {
      new File('$playgroundDir/.packages').deleteSync();
    }
    if (new Directory('$playgroundDir/.pub').existsSync()) {
      new Directory('$playgroundDir/.pub').deleteSync(recursive: true);
    }
    if (new Directory('$playgroundDir/packages').existsSync()) {
      new Directory('$playgroundDir/packages').deleteSync(recursive: true);
    }
    print('Playground has been reset.');
  }

  Future<Gist> getGist(String id) async => await gitHub.gists.getGist(id);
}

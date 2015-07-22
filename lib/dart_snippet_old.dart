library dartnow.dart_snippet;

import 'package:yaml/yaml.dart';
import 'dart:io';
import 'package:github/server.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:analyzer/analyzer.dart';

class DartSnippet {
  // TODO make this customizable
  String githubUserName = 'kasperpeulen';
  String playgroundDir;
  String inputDir;
  String name;
  String description;

  // TODO add all libraries, allElements
  String mainElements = "";
  String mainLibrary = "";
  String tags = "";
  Map dependencies;
  List<String> libraries;

  String pubspecString;
  String htmlString;
  String dartString;
  String cssString;
  String readmeString;
  Gist gist;
  String id;

  GitHub gitHub;

  String createdAt;
  String updatedAt;

  AnalyzerUtil analyzerUtil;

  Map<String, String> files;
  PubSpec _pubspec;
  int _libraryEndIndex;

  Future onReady;

  DartSnippet.fromPlayground([this.playgroundDir = 'playground']) {
    _getFilesFromInputDir(playgroundDir);
    init();
  }

  DartSnippet.fromGitDir(this.inputDir) {
    _getFilesFromInputDir(inputDir);
    init();
  }

  DartSnippet.fromId(this.id) {
    onReady = () async {
      final Authentication auth =
          new Authentication.basic(githubUserName, _getPassword());
      final GitHub gitHub = createGitHubClient(auth: auth);

      // fetch the gist
      gist = await gitHub.gists.getGist(id);
      createdAt = gist.createdAt.toIso8601String();
      updatedAt = gist.updatedAt.toIso8601String();
      _getFilesFromGist();
      init();
      await _updateReadme();
    }();
  }

  init() {
    _pubspec = new PubSpec.fromString(loadYaml(pubspecString));
    name = _pubspec.name;
    description = _pubspec.description;
    dependencies = _pubspec.dependencies;
    _libraryEndIndex = _getLibraryEndIndex();
    mainLibrary = name.substring(0, _libraryEndIndex).replaceAll('.', ':');
    _findMainElementsAndTags();
    files = _files;

    analyzerUtil = new AnalyzerUtil(dartString);
    libraries = analyzerUtil.libraries;
    final Authentication auth =
        new Authentication.basic(githubUserName, _getPassword());
    gitHub = createGitHubClient(auth: auth);
  }

  void _getFilesFromGist() {
    List<GistFile> gistFiles = gist.files;
    pubspecString =
        gistFiles.firstWhere((file) => file.name == 'pubspec.yaml').content;
    htmlString =
        gistFiles.firstWhere((file) => file.name == 'index.html').content;
    cssString =
        gistFiles.firstWhere((file) => file.name == 'styles.css').content;
    dartString =
        gistFiles.firstWhere((file) => file.name == 'main.dart').content;
    readmeString =
        gistFiles.firstWhere((file) => file.name == 'README.md').content;
  }

  Map<String, String> get _files {
    Map<String, String> files = {};

    files['pubspec.yaml'] = pubspecString;
    files['main.dart'] = dartString;
    if (htmlString != null) files['index.html'] = htmlString;
    if (cssString != null) files['styles.css'] = cssString;

    return files;
  }

  _updateReadme() async {
    String newReadme = _getReadmeString();
    if (readmeString != newReadme) {
      await gitHub.gists.editGist(gist.id, {'README.md': newReadme});
    }
  }

  String get gistUrl => 'https://gist.github.com/${githubUserName}/$id';
  String get dartpadUrl => 'https://dartpad.dartlang.org/$id';

  Future<Gist> createGist() async {
    final Authentication auth =
        new Authentication.basic(githubUserName, _getPassword());
    final GitHub gitHub = createGitHubClient(auth: auth);
    // fetch the gist
    gist = await gitHub.gists.createGist(files,
        description: description, public: true);
    id = gist.id;
    createdAt = gist.createdAt.toIso8601String();
    updatedAt = gist.updatedAt.toIso8601String();
    print('Gist created at ${gistUrl}');
    return gist;
  }

  cloneGist([String outputDir]) {
    if (outputDir == null) {
      outputDir = name;
    }

    // clone the gist to the outputdir
    Process.runSync('git', ['clone', gist.htmlUrl, outputDir]);

    // add the gist url to the pubspec
    pubspecString = _addGistUrlToPubSpec();
    new File('$outputDir/pubspec.yaml').writeAsStringSync(pubspecString);

    readmeString = _getReadmeString();
    new File('$outputDir/README.md').writeAsStringSync(readmeString);

    Process.runSync('git', ['add', 'pubspec.yaml'],
        workingDirectory: outputDir);
    Process.runSync('git', ['add', 'README.md'], workingDirectory: outputDir);
    Process.runSync('git', ['commit', '-m \'.\''], workingDirectory: outputDir);
    Process.runSync('git', ['push'], workingDirectory: outputDir);

    print('Gist cloned in $outputDir');

    Process.runSync('pub', ['get'], workingDirectory: outputDir);

    _resetPlayground();
  }

  updateGist() async {
    final String githubPassword = _getPassword();

    final Authentication auth =
        new Authentication.basic(githubUserName, githubPassword);
    final GitHub gitHub = createGitHubClient(auth: auth);
    // fetch the gist

    id = _pubspec.homepage.substring(_pubspec.homepage.lastIndexOf('/') + 1);

    print(id);
    gist = await gitHub.gists.getGist(id);

    createdAt = gist.createdAt.toIso8601String();
    updatedAt = gist.updatedAt.toIso8601String();

    readmeString = _getReadmeString();
    new File('$inputDir/README.md').writeAsStringSync(readmeString);

    Process.runSync('git', ['add', 'pubspec.yaml'], workingDirectory: inputDir);
    Process.runSync('git', ['add', 'README.md'], workingDirectory: inputDir);
    if (htmlString != null) {
      Process.runSync('git', ['add', 'index.html'], workingDirectory: inputDir);
    }
    if (cssString != null) {
      Process.runSync('git', ['add', 'styles.css'], workingDirectory: inputDir);
    }
    if (dartString != null) {
      Process.runSync('git', ['add', 'main.dart'], workingDirectory: inputDir);
    }

    Process.runSync('git', ['commit', '-m \'.\''], workingDirectory: inputDir);
    Process.runSync('git', ['push'], workingDirectory: inputDir);

    await patch(
        'https://dartnow.firebaseio.com/gists.json?auth=l9UAg0tt6zlx1wuoaikhg32Q2YcLHgRycBwa2QH4',
        body: JSON.encode({id: toJSON()}));
  }

  addToFireBase() async {
    await patch(
        'https://dartnow.firebaseio.com/gists.json?auth=l9UAg0tt6zlx1wuoaikhg32Q2YcLHgRycBwa2QH4',
        body: JSON.encode({id: toJSON()}));
    print('Snippet added to https://dartnow.firebaseio.com/gists');
  }

  Map toJSON() {
    return {
      'name': name,
      'author': gist.owner.login,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'description': description,
      'mainLibrary': mainLibrary,
      'mainElements': mainElements,
      'tags': tags,
      'files': {
        'pubspec': pubspecString,
        'html': htmlString,
        'css': cssString,
        'dart': dartString,
      },
      'libraries': libraries,
      'id': id,
      'gistUrl': gistUrl,
      'dartpadUrl': dartpadUrl,
      'dependencies': dependencies
    };
  }

  String _getReadmeString() {
    return '''
#${mainLibrary} example

${description}

**Main library:** ${mainLibrary}<br>
**Main element${mainElements.contains(' ') ? 's' : ''}:** ${mainElements}<br>
**Gist:** $gistUrl<br>${mainLibrary.contains('dart') ?
  '\n**DartPad:** $dartpadUrl<br>' : ''}
${tags.length == 0 ? "" :
    '**Tags:** ${tags.trim().split(' ').map((t) => '#$t').join(' ')}<br>'}
''';
  }

  int _getLibraryEndIndex() {
    if (name.contains('__')) {
      return name.indexOf('__');
    } else if (name.contains('_')) {
      return name.indexOf('_');
    } else {
      return 0;
    }
  }

  void _findMainElementsAndTags() {
    StringBuffer buffer = new StringBuffer();
    bool skipUnderscore = false;
    for (int i = _libraryEndIndex; i < name.length; i++) {
      if (name[i] != '_' || skipUnderscore) buffer.write(name[i]);
      if (name[i] == "'") {
        skipUnderscore = !skipUnderscore;
      }
      if ((name[i] == '_' || i == name.length - 1) && !skipUnderscore) {
        // add the buffer to the tags or mainElements
        if (buffer.length > 1) {
          String string = '$buffer ';
          if (string.contains("'")) {
            tags += string.replaceAll("'", '');
          } else {
            mainElements += string;
          }
          // create a new buffer
          buffer = new StringBuffer();
        }
      }
    }
    mainElements = mainElements.trim();
    tags = tags.trim();
  }

  _getFilesFromInputDir(String inputDir) {
    final File pubSpecFile = new File('${inputDir}/pubspec.yaml');
    final File htmlFile = new File('${inputDir}/index.html');
    final File dartFile = new File('${inputDir}/main.dart');
    final File cssFile = new File('${inputDir}/styles.css');

    final Map files = {};
    if (!pubSpecFile
        .existsSync()) throw 'Oh noes ! I couldn\'t find your pubspec.yaml file!';
    pubspecString = pubSpecFile.readAsStringSync();
    if (htmlFile.existsSync()) htmlString = htmlFile.readAsStringSync();
    if (dartFile.existsSync()) dartString = dartFile.readAsStringSync();
    if (cssFile.existsSync()) cssString = cssFile.readAsStringSync();
  }

  String _getPassword() {
    final ProcessResult r = Process.runSync(
        'security', ['find-internet-password', '-wa', githubUserName]);
    return (r.stdout as String).trim();
  }

  String _addGistUrlToPubSpec() {
    List<String> pubSpecAsList = pubspecString.split('\n');
    if (pubSpecAsList.every((s) => !s.startsWith('environment'))) {
      List<String> addHomePageAndEnvironment = '''
homepage: ${gistUrl}
environment:
  sdk: '>=1.0.0 <2.0.0'
'''.split('\n')..removeLast();
      if (pubSpecAsList.every((s) => !s.startsWith('dependencies'))) {
        pubSpecAsList.addAll(addHomePageAndEnvironment);
      } else {
        pubSpecAsList.insertAll(pubSpecAsList.indexOf(pubSpecAsList
                .firstWhere((s) => s.trim().startsWith('dependencies'))),
            addHomePageAndEnvironment);
      }
    } else {
      var environmentIndex = pubSpecAsList.indexOf(
          pubSpecAsList.firstWhere((s) => s.startsWith('environment:')));
      pubSpecAsList.insert(environmentIndex, 'homepage: ${gistUrl}');
    }
    return pubSpecAsList.join('\n');
  }

  String _addDartPadUrlToReadme() {
    List<String> readmeList = readmeString.split('\n');
    readmeList.removeLast();
    readmeList.insert(readmeList.length - 1,
        '''**Gist:** $gistUrl<br>${mainLibrary.contains('dart') ?
    '''
**DartPad:** $dartpadUrl<br>''' : ''}''');
    return readmeList.join('\n');
  }

  void _resetPlayground() {
    new File('$playgroundDir/pubspec.yaml').writeAsStringSync('''
name:${' '}
description: >
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
    print('Playground has been reset.');
  }
}

class PubSpec {
  final String name;
  final String description;
  final String homepage;
  final Map dependencies;
  final String mainLibrary;
  final String mainElements;
  final String tags;
  final Map yaml;

  PubSpec.fromString(String string) : this._fromMap(loadYaml(string));

  PubSpec._fromMap(Map yaml)
      : this.yaml = yaml,
        name = yaml['name'],
        description = yaml['description'],
        homepage = yaml['homepage'],
        dependencies = yaml['dependencies'],
        tags = yaml['tags'],
        mainElements = yaml['main_elements'],
        mainLibrary = yaml['main_library'];
}

class AnalyzerUtil {
  String dartFile;
  List<String> libraries;
  AnalyzerUtil(this.dartFile) {
    libraries = _findLibraries();
  }

  List<String> _findLibraries() {
    // Parse the dart string
    CompilationUnit compilationUnit = parseCompilationUnit(dartFile);

    // directive ::= [ExportDirective] | [ImportDirective] | [LibraryDirective] |
    // [PartDirective] | [PartOfDirective]
    List<Directive> directives = compilationUnit.directives;

    // only retain the imports
    directives.retainWhere((directive) => directive is ImportDirective);

    // Convert the ImportDirective object to a good looking string.
    List<String> libraries = directives.map(_beautifyImportDirective).toList();

    return libraries;
  }

  String _beautifyImportDirective(ImportDirective import) {
    String uri = import.uri.stringValue;
    if (uri.startsWith('dart')) return uri;

    if (uri.startsWith('package:')) return uri
        .replaceAll('package:', '')
        .replaceFirst('/', ':')
        .replaceAll('/', '.')
        .replaceAll('.dart', '');

    if (uri.startsWith('packages/')) return uri
        .replaceAll('packages/', '')
        .replaceFirst('/', ':')
        .replaceAll('/', '.')
        .replaceAll('.dart', '');

    throw 'Oh noes! I could not extract the library from $uri... My bad!';
  }
}

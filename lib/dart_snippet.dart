import 'package:github/server.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:dartnow_cli/pubspec.dart';
import 'package:dartnow_cli/anayzer_util.dart';


Authentication auth = new Authentication.basic('kasperpeulen', 'K19PEul90');
GitHub gitHub = createGitHubClient(auth: auth);

class DartSnippet {
  Gist _gist;

  DartSnippet.fromGist(this._gist);

  PubSpec get _pubspec => new PubSpec.fromString(pubspecString);
  String get name => _pubspec.name;
  String get description => _pubspec.description;
  String get shortDescription {
    if (description.indexOf('\n') == -1) {
      return description;
    } else {
      return description.substring(0, description.indexOf('\n'));
    }
  }
  String get mainLibrary => _pubspec.mainLibrary;
  String get mainElements => _pubspec.mainElements;
  String get tags => _pubspec.tags;

  String get id => _gist.id;
  String get author => _gist.owner.login;
  String get updatedAt => _gist.updatedAt.toIso8601String();
  String get createdAt => _gist.updatedAt.toIso8601String();
  String get gistUrl => 'https://gist.github.com/${author}/$id';
  String get dartpadUrl => 'https://dartpad.dartlang.org/$id';

  List<GistFile> get _gistFiles => _gist.files;
  String get pubspecString => _fileString('pubspec.yaml');
  String get htmlString => _fileString('index.html');
  String get dartString => _fileString('main.dart');
  String get cssString => _fileString('styles.css');
  String get oldReadmeString => _fileString('README.md');

  List<String> get libraries => new AnalyzerUtil().findLibraries(dartString);

  String _fileString(String fileName) {
    if (_gistFiles.any((file) => file.name == fileName)) {
      return _gistFiles.firstWhere((file) => file.name == fileName).content;
    } else {
      return null;
    }
  }

  Map toJson() {
    return {
      'name': _pubspec.name,
      'author': _gist.owner.login,
      'createdAt': _gist.createdAt.toIso8601String(),
      'updatedAt': _gist.updatedAt.toIso8601String(),
      'description': _pubspec.description,
      'mainLibrary': _pubspec.mainLibrary,
      'mainElements': _pubspec.mainElements,
      'tags': _pubspec.tags,
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
      'dependencies': _pubspec.dependencies
    };
  }

  updatePubSpec() async {
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
    await gitHub.gists.editGist(id, files: {'pubspec.yaml': pubSpecAsList.join('\n')});
  }

  updateReadme() async {
    if (oldReadmeString != newReadmeString) {
      await gitHub.gists.editGist(id, files: {'README.md': newReadmeString});
    }
  }

  String get newReadmeString => '''
#${mainLibrary} example

${description}

**Main library:** ${mainLibrary}<br>
**Main element${mainElements.contains(' ') ? 's' : ''}:** ${mainElements}<br>
**Gist:** $gistUrl<br>${displayDartPadLink ? '\n**DartPad:** $dartpadUrl<br>' : ''}
${tags.length == 0 ? "" : '**Tags:** ${tagsWithHashTag}<br>'}
''';

  String get tagsWithHashTag =>
      tags.trim().split(' ').map((t) => '#$t').join(' ');

  bool get displayDartPadLink {
    return libraries.every((l) => l.startsWith('dart'));
  }

  updateGistDescription() {
    gitHub.gists.editGist(id, description: shortDescription);
  }

  addToFireBase() async {
    await patch(
        'https://dartnow.firebaseio.com/gists.json?auth=l9UAg0tt6zlx1wuoaikhg32Q2YcLHgRycBwa2QH4',
        body: JSON.encode({id: toJson()}));
    print('Snippet added to https://dartnow.firebaseio.com/gists');
  }
}


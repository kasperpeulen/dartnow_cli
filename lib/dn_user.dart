import 'package:github/server.dart';
import 'package:dartnow_cli/dartnow_manager.dart';
import 'dart:async';


Authentication auth = new Authentication.basic('kasperpeulen', 'K19PEul90');
GitHub gitHub = createGitHubClient(auth: auth);
GistsService gistService = gitHub.gists;

main() async {
  User user = await gitHub.users.getUser('kasperpeulen');
  DNUser dnUser = new DNUser(user);
  await dnUser.onReady;
  Map json = dnUser.toJson();
  print(json);
}

class DNUser {

  User user;

  DartNowManager manager = new DartNowManager();

  List<String> gists;

  Future onReady;

  DNUser(this.user) {
    onReady = new Future(() async {
      gists = await _gists;
    });
  }

  String get avatarUrl => user.avatarUrl;
  String get name => user.name;
  int get id => user.id;
  String get email => user.email;
  String get username => user.login;

  Map toJson() => {
    'name': name,
    'avatarUrl': avatarUrl,
    'id': id,
    'email': email,
    'username': username,
    'gist': gists,
    'gistCount': gists.length
  };

  Future<List<String>> get _gists async {
    List<String> gistIds = await manager.getGistIds();
    List<String> userIds = [];
    for (String id in gistIds) {
      Gist gist = await manager.getGist(id);
      if (gist.owner.login == user.login) {
        userIds.add(id);
      }
    }
    return userIds;
  }
}
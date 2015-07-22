import 'package:dartnow_cli/dart_snippet.dart';
import 'package:github/server.dart';
import 'package:dartnow_cli/dartnow_manager.dart';

main() async {

  DartNowManager manager = new DartNowManager();
  Gist gist = await manager.createGist(null);

  DartSnippet snippet = new DartSnippet.fromGist(gist);
  await snippet.updateReadme();
  await snippet.updateGistDescription();
  await snippet.updatePubSpec();
  print('snippet fetched');

  manager.cloneGist(snippet.name, gist.htmlUrl);

  print('Gist cloned in ${snippet.name}');

  await snippet.addToFireBase();
  manager.resetPlayground();
}

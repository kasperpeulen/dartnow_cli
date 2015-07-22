import 'package:dartnow_cli/dart_snippet.dart';
import 'package:github/server.dart';
import 'package:dartnow_cli/dartnow_manager.dart';

main() async {

  DartNowManager manager = new DartNowManager();
  await manager.updateAllSnippets();
}

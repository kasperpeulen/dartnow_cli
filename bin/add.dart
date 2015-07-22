import 'package:dartnow_cli/dartnow_manager.dart';

main(List<String> arguments) async {

  String id = arguments[0];

  DartNowManager manager = new DartNowManager();

  manager.updateSnippet(id);
}

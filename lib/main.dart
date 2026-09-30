import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/storage/session_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionStorage = await SessionStorage.init();
  final token = sessionStorage.getToken();
  final tokenPresent = token != null && token.isNotEmpty;
  final role = sessionStorage.getSelectedRole();
  debugPrint('''
[APP DEBUG - URL STRATEGY & ROUTING]
Browser URI: ${Uri.base}
Browser Path: ${Uri.base.path}
Browser Fragment (Hash): ${Uri.base.fragment}
Active URL Strategy: HashUrlStrategy (default - routes must use /#/<path>)
Session initialized: true
Token present: $tokenPresent
Selected role: $role
''');
  runApp(AceEdxApp(sessionStorage: sessionStorage));
}

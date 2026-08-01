// Rebrands this Flutter project for one academy: app name, logo, and
// default tenant base URL. Run from the project root:
//
//   dart run tool/brand_app.dart --name "Daniel's Academy" \
//     --base-url https://daniel.probahi.com \
//     --logo https://example.com/daniel-logo.png
//
// or with a JSON config file (see tool/example_academy.json):
//
//   dart run tool/brand_app.dart --config tool/example_academy.json
//
// See tool/README.md for the full option list and what each step edits.
//
// ignore_for_file: avoid_print — a CLI tool reports progress on stdout.

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'create_placeholder_logo.dart';

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'config',
      abbr: 'c',
      help: 'Path to a JSON file with name/base_url/logo/color/lock_server.',
    )
    ..addOption('name', abbr: 'n', help: 'App display name.')
    ..addOption(
      'base-url',
      abbr: 'u',
      help: 'Tenant base URL, e.g. https://daniel.probahi.com',
    )
    ..addOption(
      'logo',
      abbr: 'l',
      help: 'Logo image: an http(s) URL or a local file path. '
          'If omitted, a placeholder is generated.',
    )
    ..addOption(
      'color',
      help: 'Splash screen background color as 6-digit hex. Default FAFAFA.',
    )
    ..addFlag(
      'allow-server-override',
      defaultsTo: false,
      help: 'Keep the in-app "Academy / server" screen enabled instead of '
          'locking the app to --base-url.',
    )
    ..addFlag(
      'skip-icons',
      defaultsTo: false,
      help: 'Skip regenerating launcher icons and splash screens.',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    _fail('${e.message}\n\n${_usage(parser)}');
  }

  if (args['help'] as bool) {
    print(_usage(parser));
    return;
  }

  if (!File('pubspec.yaml').existsSync()) {
    _fail('Run this from the project root (where pubspec.yaml lives).');
  }

  final fileConfig = <String, dynamic>{};
  final configPath = args['config'] as String?;
  if (configPath != null) {
    final file = File(configPath);
    if (!file.existsSync()) _fail('Config file not found: $configPath');
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map<String, dynamic>) {
      _fail('$configPath must contain a JSON object.');
    }
    fileConfig.addAll(decoded);
  }

  final name =
      (args['name'] as String?) ??
      fileConfig['name'] as String? ??
      fileConfig['app_name'] as String?;
  final baseUrl = (args['base-url'] as String?) ?? fileConfig['base_url'] as String?;
  final logo = (args['logo'] as String?) ?? fileConfig['logo'] as String?;
  final colorInput =
      (args['color'] as String?) ?? fileConfig['color'] as String? ?? 'FAFAFA';
  final allowOverride = args.wasParsed('allow-server-override')
      ? args['allow-server-override'] as bool
      : fileConfig['lock_server'] == false;
  final skipIcons = args['skip-icons'] as bool;

  if (name == null || name.trim().isEmpty) {
    _fail('Missing app name. Pass --name or set "name" in --config.\n\n${_usage(parser)}');
  }
  if (baseUrl == null || baseUrl.trim().isEmpty) {
    _fail(
      'Missing base URL. Pass --base-url or set "base_url" in --config.\n\n${_usage(parser)}',
    );
  }
  if (!RegExp(r'^https?://').hasMatch(baseUrl)) {
    _fail('--base-url must start with http:// or https:// (got "$baseUrl").');
  }
  final hex = colorInput.replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) {
    _fail('--color must be a 6-digit hex value, e.g. 0B5FFF (got "$colorInput").');
  }
  final color = '#${hex.toUpperCase()}';

  print('Branding as "$name"');
  print('  base URL:         $baseUrl');
  print('  logo:             ${logo ?? '(placeholder)'}');
  print('  splash color:     $color');
  print('  server override:  $allowOverride');
  print('');

  await _resolveLogo(logo);
  _patchConfigDart(
    appName: name,
    baseUrl: baseUrl,
    allowOverride: allowOverride,
    hasLogo: true,
  );
  _patchPubspec(description: name, color: color);
  _patchAndroidManifest(label: name);
  _patchIosInfoPlist(name: name);

  print('\nRunning flutter pub get...');
  _run('flutter', ['pub', 'get']);

  if (!skipIcons) {
    print('\nGenerating launcher icons...');
    _run('dart', ['run', 'flutter_launcher_icons']);
    print('\nGenerating splash screens...');
    _run('dart', ['run', 'flutter_native_splash:create']);
  }

  print('\nDone.');
  print('  flutter run                    try it locally');
  print('  flutter build apk --release    Android build');
  print('  flutter build ipa --release    iOS build (needs a signing team configured)');
  print(
    '\nThis only rebrands name/logo/base URL/splash color. Publishing this academy\'s '
    'app as a separate App Store / Play Store listing also needs a unique application '
    'id / bundle id (android/app/build.gradle.kts "applicationId", the iOS Runner '
    'target\'s Bundle Identifier) — not handled by this script.',
  );
}

Future<void> _resolveLogo(String? logo) async {
  final dest = File(p.join('assets', 'branding', 'logo.png'));
  dest.parent.createSync(recursive: true);

  if (logo == null) {
    print('No --logo given; writing a placeholder.');
    createPlaceholderLogo(outputPath: dest.path);
    return;
  }

  if (logo.startsWith('http://') || logo.startsWith('https://')) {
    print('Downloading logo from $logo ...');
    try {
      await Dio().download(logo, dest.path);
    } catch (e) {
      _fail('Could not download logo from $logo: $e');
    }
  } else {
    final source = File(logo);
    if (!source.existsSync()) _fail('Logo file not found: $logo');
    source.copySync(dest.path);
  }
}

void _patchConfigDart({
  required String appName,
  required String baseUrl,
  required bool allowOverride,
  required bool hasLogo,
}) {
  final file = File(p.join('lib', 'core', 'config.dart'));
  var content = file.readAsStringSync();

  content = _replaceOnce(
    content,
    RegExp(r"static const String appName = '.*?';"),
    "static const String appName = '${_dartEscape(appName)}';",
    'appName',
    file.path,
  );
  content = _replaceOnce(
    content,
    RegExp(r"static const String defaultBaseUrl = '.*?';"),
    "static const String defaultBaseUrl = '${_dartEscape(baseUrl)}';",
    'defaultBaseUrl',
    file.path,
  );
  content = _replaceOnce(
    content,
    RegExp(r'static const bool allowServerOverride = (true|false);'),
    'static const bool allowServerOverride = $allowOverride;',
    'allowServerOverride',
    file.path,
  );
  content = _replaceOnce(
    content,
    RegExp(r'static const bool hasLogo = (true|false);'),
    'static const bool hasLogo = $hasLogo;',
    'hasLogo',
    file.path,
  );

  file.writeAsStringSync(content);
  print('Updated ${file.path}');
}

void _patchPubspec({required String description, required String color}) {
  final file = File('pubspec.yaml');
  var content = file.readAsStringSync();

  content = _replaceOnce(
    content,
    RegExp(r'^description:.*$', multiLine: true),
    'description: "$description mobile app"',
    'description',
    file.path,
  );

  // Both flutter_native_splash's root `color:` and its `android_12.color:`
  // should track the same value.
  final splashColorPattern = RegExp(r'color: "#[0-9A-Fa-f]{6}"');
  if (!splashColorPattern.hasMatch(content)) {
    _fail('Could not find flutter_native_splash color: in ${file.path}');
  }
  content = content.replaceAll(splashColorPattern, 'color: "$color"');

  file.writeAsStringSync(content);
  print('Updated ${file.path}');
}

void _patchAndroidManifest({required String label}) {
  final file = File(p.join('android', 'app', 'src', 'main', 'AndroidManifest.xml'));
  var content = file.readAsStringSync();
  content = _replaceOnce(
    content,
    RegExp(r'android:label="[^"]*"'),
    'android:label="${_xmlEscape(label)}"',
    'android:label',
    file.path,
  );
  file.writeAsStringSync(content);
  print('Updated ${file.path}');
}

void _patchIosInfoPlist({required String name}) {
  final file = File(p.join('ios', 'Runner', 'Info.plist'));
  var content = file.readAsStringSync();
  content = _replacePlistString(content, 'CFBundleDisplayName', name, file.path);
  content = _replacePlistString(content, 'CFBundleName', name, file.path);
  file.writeAsStringSync(content);
  print('Updated ${file.path}');
}

String _replacePlistString(String content, String key, String value, String path) {
  final pattern = RegExp('<key>$key</key>\\s*<string>[^<]*</string>');
  return _replaceOnce(
    content,
    pattern,
    '<key>$key</key>\n\t<string>${_xmlEscape(value)}</string>',
    key,
    path,
  );
}

String _replaceOnce(
  String content,
  RegExp pattern,
  String replacement,
  String label,
  String path,
) {
  if (!pattern.hasMatch(content)) {
    _fail('Could not find $label in $path — has the file structure changed?');
  }
  return content.replaceFirst(pattern, replacement);
}

String _dartEscape(String value) =>
    value.replaceAll('\\', '\\\\').replaceAll("'", "\\'");

String _xmlEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

void _run(String executable, List<String> arguments) {
  final result = Process.runSync(executable, arguments, runInShell: true);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    _fail('${[executable, ...arguments].join(' ')} failed with exit code ${result.exitCode}');
  }
}

Never _fail(String message) {
  stderr.writeln('Error: $message');
  exit(1);
}

String _usage(ArgParser parser) =>
    'Usage: dart run tool/brand_app.dart --name "Academy Name" '
    '--base-url https://sub.probahi.com [options]\n\n${parser.usage}';

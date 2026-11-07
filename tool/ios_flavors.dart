// Adds dev/staging/prod build configurations and schemes to the iOS project.
//
// Usage: dart run tool/ios_flavors.dart                 add flavors (idempotent)
//        dart run tool/ios_flavors.dart --flavor-icons  use AppIcon-<flavor> per flavor
//
// Each flavor gets Debug-<f>, Release-<f>, Profile-<f> configs (what
// `flutter run --flavor <f>` expects), a shared scheme named <f>, a bundle id
// suffix and its own display name via the APP_DISPLAY_NAME build setting.
// Run --flavor-icons after `make icons` has created the AppIcon-<flavor> sets.
import 'dart:io';
import 'dart:math';

const baseBundleId = 'latif.safayet.riverpod-clean-architecture';

const flavors = <String, ({String suffix, String displayName})>{
  'dev': (suffix: '.dev', displayName: 'Riverpod CA Dev'),
  'staging': (suffix: '.staging', displayName: 'Riverpod CA Stg'),
  'prod': (suffix: '', displayName: 'Riverpod CA'),
};

const buildTypes = ['Debug', 'Release', 'Profile'];

void main(List<String> args) {
  final pbxFile = File('ios/Runner.xcodeproj/project.pbxproj');
  final raw = pbxFile.readAsStringSync();
  final crlf = raw.contains('\r\n');
  var pbx = raw.replaceAll('\r\n', '\n');

  if (args.contains('--flavor-icons')) {
    for (final flavor in flavors.keys) {
      pbx = pbx.replaceAllMapped(
        RegExp(
          // Stay inside one config block (they end with "\n\t\t};"): project-level
          // and test configs have no icon setting and must be left alone.
          '(\\t\\t[0-9A-F]{24} /\\* \\w+-$flavor \\*/ = \\{\\n(?:(?!\\n\\t\\t\\};).)*?)'
          'ASSETCATALOG_COMPILER_APPICON_NAME = [^;]+;',
          dotAll: true,
        ),
        (m) => '${m[1]}ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon-$flavor";',
      );
    }
    pbxFile.writeAsStringSync(crlf ? pbx.replaceAll('\n', '\r\n') : pbx);
    stdout.writeln('Each flavor now uses its AppIcon-<flavor> icon set.');
    return;
  }

  if (pbx.contains('/* Debug-dev */')) {
    stdout.writeln('iOS flavors already configured, nothing to do.');
    return;
  }

  final usedIds = RegExp(r'\b[0-9A-F]{24}\b').allMatches(pbx).map((m) => m[0]!).toSet();
  final random = Random.secure();
  String newId() {
    while (true) {
      final id = List.generate(
        24,
        (_) => random.nextInt(16).toRadixString(16),
      ).join().toUpperCase();
      if (usedIds.add(id)) return id;
    }
  }

  // Existing Debug/Release/Profile configuration blocks.
  final blockPattern = RegExp(
    r'\t\t([0-9A-F]{24}) /\* (Debug|Release|Profile) \*/ = \{\n\t\t\tisa = XCBuildConfiguration;\n.*?\n\t\t\};\n',
    dotAll: true,
  );
  final blocks = blockPattern.allMatches(pbx).toList();
  if (blocks.length != 9) {
    stderr.writeln('Expected 9 build configurations, found ${blocks.length}. Aborting.');
    exit(1);
  }

  // Original id → ids of its flavor copies, used to extend configuration lists.
  final copies = <String, List<(String, String)>>{};
  final newBlocks = StringBuffer();

  for (final block in blocks) {
    final id = block[1]!;
    final type = block[2]!;
    final text = block[0]!;
    final isRunner = text.contains('INFOPLIST_FILE = Runner/Info.plist;');
    final isTests = text.contains('RunnerTests');

    for (final MapEntry(key: flavor, value: cfg) in flavors.entries) {
      final copyId = newId();
      final name = '$type-$flavor';
      var copy = text
          .replaceFirst('$id /* $type */', '$copyId /* $name */')
          .replaceFirst('\t\t\tname = $type;', '\t\t\tname = $name;');
      if (isRunner) {
        copy = _setBundleId(copy, '$baseBundleId${cfg.suffix}');
        copy = _addSetting(copy, 'APP_DISPLAY_NAME', '"${cfg.displayName}"');
      } else if (isTests) {
        copy = _setBundleId(copy, '$baseBundleId${cfg.suffix}.RunnerTests');
      }
      newBlocks.write(copy);
      (copies[id] ??= []).add((copyId, name));
    }

    // Plain Debug/Release/Profile behave like prod.
    var updated = text;
    if (isRunner) {
      updated = _addSetting(
        _setBundleId(updated, baseBundleId),
        'APP_DISPLAY_NAME',
        '"Riverpod CA"',
      );
    } else if (isTests) {
      updated = _setBundleId(updated, '$baseBundleId.RunnerTests');
    }
    pbx = pbx.replaceFirst(text, updated);
  }

  pbx = pbx.replaceFirst(
    '/* End XCBuildConfiguration section */',
    '$newBlocks/* End XCBuildConfiguration section */',
  );

  for (final MapEntry(key: id, value: list) in copies.entries) {
    final line = RegExp('(\\t\\t\\t\\t$id /\\* \\w+ \\*/,\\n)');
    final extra = list.map((c) => '\t\t\t\t${c.$1} /* ${c.$2} */,\n').join();
    pbx = pbx.replaceFirstMapped(line, (m) => '${m[1]}$extra');
  }

  pbxFile.writeAsStringSync(crlf ? pbx.replaceAll('\n', '\r\n') : pbx);

  // Schemes: copy Runner.xcscheme and point each action at the flavor configs.
  final schemeDir = Directory('ios/Runner.xcodeproj/xcshareddata/xcschemes');
  final runnerScheme = File('${schemeDir.path}/Runner.xcscheme').readAsStringSync();
  for (final flavor in flavors.keys) {
    var scheme = runnerScheme;
    for (final type in buildTypes) {
      scheme = scheme.replaceAll(
        'buildConfiguration = "$type"',
        'buildConfiguration = "$type-$flavor"',
      );
    }
    File('${schemeDir.path}/$flavor.xcscheme').writeAsStringSync(scheme);
  }

  // Display name comes from the build setting.
  final plist = File('ios/Runner/Info.plist');
  plist.writeAsStringSync(
    plist.readAsStringSync().replaceFirstMapped(
      RegExp(r'(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)'),
      (m) => '${m[1]}\$(APP_DISPLAY_NAME)${m[2]}',
    ),
  );

  stdout.writeln('Added ${flavors.length} iOS flavors: ${flavors.keys.join(', ')}.');
}

String _setBundleId(String block, String id) => block.replaceFirst(
  RegExp(r'PRODUCT_BUNDLE_IDENTIFIER = [^;]+;'),
  'PRODUCT_BUNDLE_IDENTIFIER = "$id";',
);

String _addSetting(String block, String key, String value) => block.replaceFirst(
  '\t\t\tbuildSettings = {\n',
  '\t\t\tbuildSettings = {\n\t\t\t\t$key = $value;\n',
);

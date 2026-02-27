import 'dart:io';

import 'package:dart_inspect/dart_inspect.dart';

Future<void> main(List<String> args) async {
  // Directory to inspect.
  final directory = args.isEmpty ? Directory.current : Directory(args.first);

  if (!await directory.exists()) {
    stderr.writeln('** Directory not found: ${directory.path}');
    exit(1);
  }

  // Configure inspection behavior.
  const options = DartInspectOptions(
    markdown: true,
    noPrimitives: false,
    privateOnly: false,
  );

  final inspector = DartInspect(options);

  stdout.writeln('# Dart Inspect Example');
  stdout.writeln();
  stdout.writeln('Directory: ${directory.path}');
  stdout.writeln();

  if (options.options.isNotEmpty) {
    stdout.writeln('Options:');
    for (final opt in options.options) {
      stdout.writeln('  $opt');
    }
    stdout.writeln();
  }

  String? lastFile;

  await for (final report in inspector.scanDirectory(directory)) {
    final filePath = report.filePath;

    // Print file section only when it changes.
    if (filePath != null && filePath != lastFile) {
      lastFile = filePath;

      if (options.markdown) {
        stdout.writeln('---');
        stdout.writeln();
        stdout.writeln('## $filePath');
        stdout.writeln();
      } else {
        stdout.writeln('\n==================================================');
        stdout.writeln(filePath);
        stdout.writeln('==================================================');
      }
    }

    if (options.markdown) {
      stdout.writeln(report.toMarkdown(withFilePath: false));
    } else {
      stdout.writeln(report.toString(withFilePath: false));
    }
  }
}

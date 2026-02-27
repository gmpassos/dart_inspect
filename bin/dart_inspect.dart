import 'dart:io';

import 'package:dart_inspect/dart_inspect.dart';

const _usage = '''
dart_inspect <directory> [options]

Options:
  --private-only     Show only private fields
  --no-primitives    Ignore primitive fields
  --final-only       Show only final fields
  --no-final         Ignore final fields
  --no-imports       Do not show file imports
  --no-classes       Do not show class fields

  --markdown         Markdown output
  --simple           Simple output (default)

  -h, --help         Show this help
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    print(_usage);
    exit(0);
  }

  final dirPath = args.first;
  final optionsSet = args.skip(1).toSet();

  const validOptions = {
    '--private-only',
    '--no-primitives',
    '--final-only',
    '--no-final',
    '--no-imports',
    '--no-classes',
    '--markdown',
    '--simple',
  };

  final unknown = optionsSet.difference(validOptions);

  if (unknown.isNotEmpty) {
    stderr.writeln('** Unknown option(s): ${unknown.join(', ')}');
    stderr.writeln(_usage);
    exit(64);
  }

  final markdown = optionsSet.contains('--markdown');
  final simple = optionsSet.contains('--simple');

  if (simple && markdown) {
    stderr.writeln(
      '** Options --simple and --markdown cannot be used together.',
    );
    stderr.writeln(_usage);
    exit(64);
  }

  final inspectOptions = DartInspectOptions(
    privateOnly: optionsSet.contains('--private-only'),
    noPrimitives: optionsSet.contains('--no-primitives'),
    finalOnly: optionsSet.contains('--final-only'),
    noFinal: optionsSet.contains('--no-final'),
    noImports: optionsSet.contains('--no-imports'),
    noClasses: optionsSet.contains('--no-classes'),
    markdown: markdown,
  );

  final root = Directory(dirPath);

  if (!await root.exists()) {
    stderr.writeln('** Directory not found: $dirPath');
    exit(66);
  }

  final inspector = DartInspect(inspectOptions);

  String? lastPath;

  if (markdown) {
    stdout.writeln('# Dart Inspect Report');
    stdout.writeln();

    stdout.writeln('## Configuration');
    stdout.writeln();

    stdout.writeln('- Directory: `$dirPath`');

    stdout.writeln(
      '- Format: ${inspectOptions.markdown ? 'markdown' : 'simple'}',
    );

    final opts = inspectOptions.options;
    if (opts.isEmpty) {
      stdout.writeln('- Options: (none)');
    } else {
      stdout.writeln('- Options:');
      for (final o in opts) {
        stdout.writeln('  $o');
      }
    }

    stdout.writeln();
  } else {
    stdout.writeln('dart_inspect');
    stdout.writeln('─' * 60);

    stdout.writeln('Directory : $dirPath');

    stdout.writeln(
      'Format    : ${inspectOptions.markdown ? 'markdown' : 'simple'}',
    );

    final opts = inspectOptions.options;
    stdout.writeln('Options   : ${opts.isEmpty ? '(none)' : opts.join(', ')}');

    stdout.writeln();
  }

  await for (final report in inspector.scanDirectory(root)) {
    if (report.filePath != lastPath) {
      lastPath = report.filePath;

      if (markdown) {
        stdout.writeln('-' * 80);
        stdout.writeln();
        stdout.writeln('## ${report.filePath}');
        stdout.writeln();
      } else {
        stdout.writeln('=' * 80);
        stdout.writeln(report.filePath);
        stdout.writeln();
      }
    }

    if (report is DartFileImports) {
      if (markdown) {
        stdout.writeln(report.toMarkdown(withFilePath: false));
        stdout.writeln();
      } else {
        stdout.writeln('Imports:');
        for (final imp in report.imports) {
          stdout.write('  ');
          stdout.writeln(imp.toString(withFilePath: false));
        }
        stdout.writeln();
      }
    } else if (report is DartClassFields) {
      if (markdown) {
        stdout.writeln(report.toMarkdown(withFilePath: false));
      } else {
        stdout.writeln(report.toString(withFilePath: false));
      }
    }
  }
}

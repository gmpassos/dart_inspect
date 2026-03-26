import 'dart:io';

import 'package:dart_inspect/dart_inspect.dart';

const _usage = '''
dart_inspect <directory|file> [options]

Options:
  --private-only      Show only private fields
  --no-primitives     Ignore primitive fields
  --final-only        Show only final fields
  --no-final          Ignore final fields
  --no-imports        Do not show file imports
  --no-classes        Do not show class fields
  --no-empty-classes  Do not include empty classes

  --markdown          Markdown output
  --mermaid           Mermaid output
  --simple            Simple output (default)

  --sort-entries      Sort fields and classes alphabetically (default: false)

  -h, --help          Show this help
''';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('-h') || args.contains('--help')) {
    print(_usage);
    exit(0);
  }

  final path = args.first;
  final optionsSet = args.skip(1).toSet();

  const validOptions = {
    '--private-only',
    '--no-primitives',
    '--final-only',
    '--no-final',
    '--no-imports',
    '--no-classes',
    '--no-empty-classes',
    '--markdown',
    '--mermaid',
    '--simple',
    '--sort-entries',
  };

  final unknown = optionsSet.difference(validOptions);

  if (unknown.isNotEmpty) {
    stderr.writeln('** Unknown option(s): ${unknown.join(', ')}');
    stderr.writeln(_usage);
    exit(64);
  }

  final markdown = optionsSet.contains('--markdown');
  final mermaid = optionsSet.contains('--mermaid');
  final simple =
      optionsSet.contains('--simple') || (!markdown && !mermaid); // default

  // Validate mutually exclusive formats
  final formats = [markdown, mermaid, simple].where((e) => e).length;
  if (formats > 1) {
    stderr.writeln(
      '** Options --simple, --markdown and --mermaid are mutually exclusive.',
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
    noEmptyClasses: optionsSet.contains('--no-empty-classes'),
    markdown: markdown,
    mermaid: mermaid,
    sortEntries: optionsSet.contains('--sort-entries'),
  );

  final pathType = await FileSystemEntity.type(path);

  final FileSystemEntity root;

  switch (pathType) {
    case FileSystemEntityType.file:
      {
        root = File(path);
      }
    case FileSystemEntityType.directory:
      {
        root = Directory(path);
      }
    case FileSystemEntityType.notFound:
      {
        stderr.writeln('** Path not found: $path');
        exit(66); // EX_NOINPUT
      }
    default:
      {
        stderr.writeln("** Can't handle path type `$pathType`: $path");
        exit(69); // EX_UNAVAILABLE
      }
  }

  final inspector = DartInspect(inspectOptions);

  // Select reporter
  final DartInspectReporter reporter;
  if (markdown) {
    reporter = DartInspectReporterMarkdown(path, inspectOptions);
  } else if (mermaid) {
    reporter = DartInspectReporterMermaid(path, inspectOptions);
  } else {
    reporter = DartInspectReporterSimple(path, inspectOptions);
  }

  var scan = switch (root) {
    File() => inspector.scanFile(root),
    Directory() => inspector.scanDirectory(root),
    _ => throw StateError("Invalid root: $root"),
  };

  // Build and print output
  final output = await reporter.build(scan);

  stdout.write(output);
}

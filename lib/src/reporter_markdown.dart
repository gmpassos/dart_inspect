import 'dart_inspect_base.dart';
import 'report_info.dart';

/// A Markdown reporter for DartInspect.
///
/// This implementation consumes a stream of [ReportInfo] and generates
/// a structured Markdown report describing Dart files, including
/// imports and class fields.
///
/// The output is organized by file, with a configuration section
/// at the top and per-file sections separated by horizontal rules.
///
/// Example output structure:
/// - Header
/// - Configuration
/// - File sections:
///   - Imports
///   - Class fields
class DartInspectReporterMarkdown extends DartInspectReporter {
  /// Creates a Markdown reporter.
  ///
  /// [directory] defines the base path of the analysis.
  /// [options] controls filtering and formatting behavior.
  DartInspectReporterMarkdown(super.directory, super.options);

  /// Builds the Markdown report from a stream of [ReportInfo].
  ///
  /// The stream is processed incrementally, grouping entries by file.
  /// Each file generates its own section in the output.
  ///
  /// Supported report types:
  /// - [DartFileImports]: rendered as import lists
  /// - [DartClassFields]: rendered as class field descriptions
  ///
  /// Returns the full Markdown report as a [String].
  @override
  Future<String> build(Stream<ReportInfo> stream) async {
    final b = StringBuffer();

    // Group by file
    final files = <String, List<ReportInfo>>{};

    await for (final report in stream) {
      final path = report.filePath ?? '';
      files.putIfAbsent(path, () => []).add(report);
    }

    // Header
    b.writeln('# Dart Inspect Report');
    b.writeln();

    b.writeln('## Configuration');
    b.writeln();

    b.writeln('- Directory: `$directory`');
    b.writeln('- Format: markdown');

    final opts = options.options;
    if (opts.isEmpty) {
      b.writeln('- Options: (none)');
    } else {
      b.writeln('- Options:');
      for (final o in opts) {
        b.writeln('  $o');
      }
    }

    b.writeln();

    // Files (sorted for deterministic output)
    final sortedPaths = files.keys.toList()..sort();

    for (final path in sortedPaths) {
      b.writeln('---');
      b.writeln();
      b.writeln('## $path');
      b.writeln();

      final reports = files[path]!;

      // stable ordering inside file
      reports.sort(
        (a, b) => a.runtimeType.toString().compareTo(b.runtimeType.toString()),
      );

      for (final report in reports) {
        if (report is DartFileImports) {
          b.writeln(report.toMarkdown(withFilePath: false));
          b.writeln();
        } else if (report is DartClassInfo) {
          b.writeln(report.toMarkdown(withFilePath: false));
          b.writeln();
        }
      }
    }

    return b.toString();
  }
}

import 'dart_inspect_base.dart';
import 'report_info.dart';

class DartInspectReporterSimple extends DartInspectReporter {
  DartInspectReporterSimple(super.directory, super.options);

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
    b.writeln('dart_inspect');
    b.writeln('─' * 60);

    b.writeln('Directory : $directory');
    b.writeln('Format    : simple');

    final opts = options.options;
    b.writeln('Options   : ${opts.isEmpty ? '(none)' : opts.join(', ')}');

    b.writeln();

    // Files (sorted)
    final sortedPaths = files.keys.toList()..sort();

    for (final path in sortedPaths) {
      b.writeln('=' * 80);
      b.writeln(path);
      b.writeln();

      final reports = files[path]!;

      // deterministic order
      reports.sort((a, b) {
        if (a is DartClassInfo && b is DartClassInfo) {
          return a.className.compareTo(b.className);
        }
        return a.runtimeType.toString().compareTo(b.runtimeType.toString());
      });

      for (final report in reports) {
        if (report is DartFileImports) {
          b.writeln('Imports:');
          for (final imp in report.imports) {
            b.writeln('  ${imp.toString(withFilePath: false)}');
          }
          b.writeln();
        } else if (report is DartClassInfo) {
          b.writeln(report.toString(withFilePath: false));
          b.writeln();
        }
      }
    }

    return b.toString();
  }
}

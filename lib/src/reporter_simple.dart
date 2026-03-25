import 'dart_inspect_base.dart';
import 'report_info.dart';

class DartInspectReporterSimple extends DartInspectReporter {
  DartInspectReporterSimple(super.directory, super.options);

  @override
  Future<String> build(Stream<ReportInfo> stream) async {
    final b = StringBuffer();

    String? lastPath;

    // Header
    b.writeln('dart_inspect');
    b.writeln('─' * 60);

    b.writeln('Directory : $directory');
    b.writeln('Format    : simple');

    final opts = options.options;
    b.writeln('Options   : ${opts.isEmpty ? '(none)' : opts.join(', ')}');

    b.writeln();

    // Stream processing
    await for (final report in stream) {
      if (report.filePath != lastPath) {
        lastPath = report.filePath;

        b.writeln('=' * 80);
        b.writeln(report.filePath);
        b.writeln();
      }

      if (report is DartFileImports) {
        b.writeln('Imports:');
        for (final imp in report.imports) {
          b.write('  ');
          b.writeln(imp.toString(withFilePath: false));
        }
        b.writeln();
      } else if (report is DartClassFields) {
        b.writeln(report.toString(withFilePath: false));
      }
    }

    return b.toString();
  }
}

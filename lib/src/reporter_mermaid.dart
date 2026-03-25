import 'dart_inspect_base.dart';
import 'report_info.dart';

/// A [DartInspectReporter] implementation that generates a
/// Mermaid `classDiagram` representation of the inspected Dart code.
///
/// This reporter consumes a stream of [ReportInfo] objects and builds
/// a textual Mermaid diagram describing:
///
/// - Classes and their fields
/// - Relationships between classes based on field types
///
/// The output can be rendered using Mermaid-compatible tools.
///
/// ### Features
/// - Deduplicates fields per class
/// - Sorts classes and fields for stable output
/// - Detects simple relationships (`A --> B`) when a field type
///   references another known class
/// - Escapes generic types (`<T>`) for Mermaid compatibility
///
/// ### Example Output
/// ```mermaid
/// classDiagram
///
///   class User {
///     String name
///     Address address
///   }
///
///   class Address {
///     String street
///   }
///
///   User --> Address
/// ```
///
/// ### Usage
/// ```dart
/// final reporter = DartInspectReporterMermaid(
///   directory: './lib',
///   options: DartInspectOptions(...),
/// );
///
/// final output = await reporter.build(stream);
/// print(output);
/// ```
///
/// The resulting string can be pasted into:
/// - https://mermaid.live
/// - Markdown files with Mermaid support
///
/// ### Notes
/// - Only [DartClassFields] reports are currently used
/// - Generic types like `List<Foo>` are resolved to `Foo`
/// - Nullable types (`Foo?`) are normalized to `Foo`
///
/// ### Limitations
/// - Does not detect inheritance (`extends`, `implements`)
/// - Does not distinguish between composition and aggregation
/// - Only supports simple generic extraction (`<T>`)
class DartInspectReporterMermaid extends DartInspectReporter {
  DartInspectReporterMermaid(super.directory, super.options);

  final _classes = <String, List<DartFieldInfo>>{};

  @override
  @override
  Future<String> build(Stream<ReportInfo> stream) async {
    final b = StringBuffer();

    // Header
    b.writeln('%% Dart Inspect - Mermaid Report');
    b.writeln('%% Directory: $directory');
    b.writeln(
      '%% Options: ${options.options.join(', ').isEmpty ? '(none)' : options.options.join(', ')}',
    );
    b.writeln();

    // Collect data
    await for (final report in stream) {
      if (report is DartClassFields) {
        final list = _classes.putIfAbsent(report.className, () => []);
        list.addAll(report.fields);
      }
    }

    b.writeln('classDiagram');
    b.writeln();

    // Classes
    final classNames = _classes.keys.toList()..sort();

    for (final name in classNames) {
      final fields = _classes[name]!;

      b.writeln('  class $name {');

      final seen = <String>{};
      final sortedFields =
          fields.map((f) => '${_sanitize(f.type)} ${f.name}').toSet().toList()
            ..sort();

      for (final field in sortedFields) {
        if (!seen.add(field)) continue;
        b.writeln('    $field');
      }

      b.writeln('  }');
      b.writeln(); // spacing between classes
    }

    // Relationships
    final relations = <String>{};

    for (final entry in _classes.entries) {
      final from = entry.key;

      for (final f in entry.value) {
        final to = _extractTypeName(f.type);

        if (_classes.containsKey(to)) {
          relations.add('  $from --> $to');
        }
      }
    }

    if (relations.isNotEmpty) {
      b.writeln('  %% Relationships');
      for (final r in relations.toList()..sort()) {
        b.writeln(r);
      }
      b.writeln();
    }

    return b.toString();
  }

  String _sanitize(String t) =>
      t.replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  String _extractTypeName(String t) {
    final cleaned = t.replaceAll('?', '');

    final match = RegExp(r'<(\w+)>').firstMatch(cleaned);
    if (match != null) return match.group(1)!;

    return cleaned.split('.').last;
  }
}

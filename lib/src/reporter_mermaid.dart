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

  @override
  Future<String> build(Stream<ReportInfo> stream) async {
    final b = StringBuffer();

    final classes = <String, DartClassInfo>{};

    // Header
    b.writeln('%% Dart Inspect - Mermaid Report');
    b.writeln('%% Directory: $directory');
    b.writeln(
      '%% Options: ${options.options.join(', ').isEmpty ? '(none)' : options.options.join(', ')}',
    );
    b.writeln();

    // Collect data
    await for (final report in stream) {
      if (report is DartClassInfo) {
        final existing = classes[report.className];

        if (existing == null) {
          classes[report.className] = report;
        } else {
          // merge fields only (keep first metadata)
          classes[report.className] = DartClassInfo(
            report.className,
            [...existing.fields, ...report.fields],
            isAbstract: existing.isAbstract,
            isInterface: existing.isInterface,
            isMixin: existing.isMixin,
            superClass: existing.superClass,
            interfaces: existing.interfaces,
            mixins: existing.mixins,
            filePath: existing.filePath,
          );
        }
      }
    }

    b.writeln('classDiagram');
    b.writeln();

    final classNames = classes.keys.toList()..sort();

    // Classes (with fields)
    for (final name in classNames) {
      final c = classes[name]!;

      final stereotypes = [
        if (c.isAbstract) 'abstract',
        if (c.isInterface) 'interface',
        if (c.isMixin) 'mixin',
      ];

      if (stereotypes.isNotEmpty) {
        b.writeln('  class $name <<${stereotypes.join(', ')}>> {');
      } else {
        b.writeln('  class $name {');
      }

      final seen = <String>{};
      final sortedFields =
          c.fields.map((f) => '${_sanitize(f.type)} ${f.name}').toSet().toList()
            ..sort();

      for (final field in sortedFields) {
        if (!seen.add(field)) continue;
        b.writeln('    $field');
      }

      b.writeln('  }');
      b.writeln();
    }

    final relations = <String>{};

    // Field-based relationships
    for (final c in classes.values) {
      for (final f in c.fields) {
        final to = _extractTypeName(f.type);

        if (classes.containsKey(to)) {
          relations.add('  ${c.className} --> $to');
        }
      }
    }

    // Hierarchy relationships
    for (final c in classes.values) {
      final from = c.className;

      if (c.superClass != null && c.superClass!.isNotEmpty) {
        relations.add('  ${_extractClassName(c.superClass!)} <|-- $from');
      }

      for (final i in c.interfaces) {
        relations.add('  ${_extractClassName(i)} <|.. $from');
      }

      for (final m in c.mixins) {
        relations.add('  ${_extractClassName(m)} ..> $from');
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

  static final _regExpClassName = RegExp(r'^(\w+)<?');

  String _extractClassName(String t) {
    final cleaned = t.replaceAll('?', '');

    final match = _regExpClassName.firstMatch(cleaned);
    if (match != null) return match.group(1)!;

    return cleaned.split('.').last;
  }

  static final _regExpTypeName = RegExp(r'<(\w+)>');

  String _extractTypeName(String t) {
    final cleaned = t.replaceAll('?', '');

    final match = _regExpTypeName.firstMatch(cleaned);
    if (match != null) return match.group(1)!;

    return cleaned.split('.').last;
  }
}

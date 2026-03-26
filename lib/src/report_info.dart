import 'package:collection/collection.dart';

/// Base information used by report entries produced during Dart source analysis.
///
/// A report may optionally be associated with a [filePath], allowing results
/// to be traced back to the originating file.
///
/// Implementations must provide structured serialization via [toJson] and
/// human-readable representations through [toMarkdown] and [toString].
abstract class ReportInfo implements Comparable<ReportInfo> {
  /// Path of the file associated with this report entry, if available.
  final String? filePath;

  const ReportInfo({this.filePath});

  /// Converts this report entry into a JSON-serializable structure.
  Map<String, Object?> toJson();

  /// Returns a Markdown representation of this report.
  ///
  /// When [withFilePath] is `true`, the associated file path is included
  /// when available.
  String toMarkdown({bool withFilePath = true});

  String toMermaid();

  /// Returns a human-readable textual representation of this report.
  ///
  /// When [withFilePath] is `true`, the associated file path is included
  /// when available.
  @override
  String toString({bool withFilePath = true});

  @override
  int compareTo(ReportInfo other) {
    var fp1 = filePath;
    var fp2 = other.filePath;

    if (fp1 != null) {
      if (fp2 != null) {
        return fp1.compareTo(fp2);
      } else {
        return -1;
      }
    }
    if (fp2 != null) {
      return 1;
    } else {
      return 0;
    }
  }
}

/// Describes a Dart class field.
///
/// Stores the field [name] and its declared Dart [type].
class DartFieldInfo implements Comparable<DartFieldInfo> {
  /// Field name.
  final String name;

  /// Declared Dart type of the field.
  final String type;

  const DartFieldInfo(this.name, this.type);

  /// Converts this field description into JSON.
  Map<String, Object?> toJson() => {'name': name, 'type': type};

  /// Returns the field formatted as `type name`.
  @override
  String toString() => '$type $name';

  @override
  int compareTo(DartFieldInfo other) {
    var cmp = name.compareTo(other.name);
    if (cmp == 0) {
      cmp = type.compareTo(other.type);
    }
    return cmp;
  }
}

/// Report describing a Dart class, including its fields and hierarchy.
///
/// This report consolidates all relevant structural information about a class:
/// - Declared [fields]
/// - Inheritance via [superClass]
/// - Implemented interfaces via [interfaces]
///
/// This unified model simplifies reporting and diagram generation by keeping
/// all class-related data in a single structure.
///
/// The report supports serialization to JSON, Markdown, Mermaid, and
/// human-readable text formats.
class DartClassInfo extends ReportInfo {
  /// Name of the analyzed class.
  final String className;

  /// Fields declared in the class.
  final List<DartFieldInfo> fields;

  /// Name of the superclass (from `extends`), if any.
  final String? superClass;

  /// List of implemented interfaces (from `implements`).
  final List<String> interfaces;

  /// List of implemented mixins (from `implements`).
  final List<String> mixins;

  /// Whether this class is declared as `abstract`.
  final bool isAbstract;

  /// Whether this class is declared as an `interface class`.
  final bool isInterface;

  /// Whether this declaration is a `mixin`.
  final bool isMixin;

  const DartClassInfo(
    this.className,
    this.fields, {
    this.isAbstract = false,
    this.isMixin = false,
    this.isInterface = false,
    this.superClass,
    this.interfaces = const [],
    this.mixins = const [],
    super.filePath,
  });

  /// Converts this class report into JSON format.
  ///
  /// Includes fields and hierarchy information.
  @override
  Map<String, Object?> toJson() => {
    'className': className,
    'filePath': filePath,
    'fields': fields.map((f) => f.toJson()).toList(),
    'abstract': isAbstract,
    'interface': isInterface,
    'mixin': isMixin,
    'superClass': superClass,
    'interfaces': interfaces,
    'mixins': mixins,
  };

  /// Returns a Markdown section describing the class.
  ///
  /// Includes:
  /// - Class name
  /// - Optional file path
  /// - Inheritance (`extends`)
  /// - Implemented interfaces (`implements`)
  /// - Declared fields
  ///
  /// Example:
  /// ```md
  /// ### User
  ///
  /// File: lib/user.dart
  ///
  /// Extends: Person
  /// Implements: Serializable
  ///
  /// - String name
  /// - int age
  /// ```
  @override
  String toMarkdown({bool withFilePath = true}) {
    final out = StringBuffer();

    final modifiers = [
      if (isAbstract) 'abstract',
      if (isInterface) 'interface',
      if (isMixin) 'mixin',
    ].join(' ');

    out.writeln('### ${modifiers.isNotEmpty ? '$modifiers ' : ''}$className');

    final filePath = this.filePath;
    if (withFilePath && filePath != null && filePath.isNotEmpty) {
      out.write('\nFile: $filePath\n');
    }

    var classKind = false;

    if (superClass != null && superClass!.isNotEmpty) {
      classKind = true;
      out.writeln('\nExtends: $superClass');
    }

    if (interfaces.isNotEmpty) {
      if (!classKind) out.writeln();
      classKind = true;
      out.writeln('Implements: ${interfaces.join(', ')}');
    }

    if (mixins.isNotEmpty) {
      if (!classKind) out.writeln();
      classKind = true;
      out.writeln('With: ${mixins.join(', ')}');
    }

    out.writeln();

    for (final field in fields) {
      out.writeln('- $field');
    }

    return out.toString();
  }

  /// Returns a Mermaid representation of this class, including hierarchy.
  ///
  /// Produces:
  /// - A `class` block with fields
  /// - Inheritance (`extends`) using `<|--`
  /// - Interface implementation (`implements`) using `<|..`
  ///
  /// This output is intended to be composed with other Mermaid fragments
  /// under a single `classDiagram` block.
  ///
  /// Example output:
  /// ```mermaid
  /// class User {
  ///   String name
  /// }
  ///
  /// Person <|-- User
  /// Serializable <|.. User
  /// ```
  @override
  String toMermaid() {
    final b = StringBuffer();

    final classId = className.toMermaidId();

    // Class declaration with stereotypes
    final stereotypes = [
      if (isAbstract) 'abstract',
      if (isInterface) 'interface',
      if (isMixin) 'mixin',
    ];

    if (stereotypes.isNotEmpty) {
      b.writeln('class $classId <<${stereotypes.join(', ')}>> {');
    } else {
      b.writeln('class $classId {');
    }

    for (final f in fields) {
      b.writeln('  ${f.type} ${f.name}');
    }

    b.writeln('}');

    // Inheritance
    if (superClass != null && superClass!.isNotEmpty) {
      final parentId = superClass!.toMermaidId();
      b.writeln('$parentId <|-- $classId');
    }

    // Interfaces
    for (final i in interfaces) {
      final interfaceId = i.toMermaidId();
      b.writeln('$interfaceId <|.. $classId');
    }

    // Mixins (no native support → dependency style)
    for (final m in mixins) {
      final mixinId = m.toMermaidId();
      b.writeln('$mixinId ..> $classId');
    }

    return b.toString();
  }

  /// Returns a readable multiline description of the class.
  ///
  /// Includes hierarchy and fields.
  ///
  /// Optionally includes the source file path.
  @override
  @override
  String toString({bool withFilePath = true}) {
    final str = StringBuffer();

    final modifiers = [
      if (isAbstract) 'abstract',
      if (isInterface) 'interface',
      if (isMixin) 'mixin',
    ].join(' ');

    str.write('${modifiers.isNotEmpty ? '$modifiers ' : ''}$className');

    final filePath = this.filePath;
    if (withFilePath && filePath != null && filePath.isNotEmpty) {
      str.write(' ($filePath)');
    }

    str.writeln();

    if (superClass != null && superClass!.isNotEmpty) {
      str.writeln('  extends $superClass');
    }

    if (interfaces.isNotEmpty) {
      str.writeln('  implements ${interfaces.join(', ')}');
    }

    if (mixins.isNotEmpty) {
      str.writeln('  with ${mixins.join(', ')}');
    }

    for (final field in fields) {
      str.writeln('  - $field');
    }

    return str.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DartClassInfo &&
          runtimeType == other.runtimeType &&
          className == other.className &&
          superClass == other.superClass &&
          ListEquality().equals(interfaces, other.interfaces) &&
          ListEquality().equals(mixins, other.mixins) &&
          filePath == other.filePath;

  @override
  int get hashCode => Object.hash(className, superClass, filePath);

  @override
  int compareTo(ReportInfo other) {
    var cmp = super.compareTo(other);
    if (cmp != 0) return cmp;

    if (other is DartClassInfo) {
      return className.compareTo(other.className);
    }

    return cmp;
  }
}

/// Describes a Dart `import` directive found in a file.
class DartImportInfo extends ReportInfo {
  /// Imported URI.
  final String uri;

  /// Optional import prefix (`as prefix`).
  final String? prefix;

  /// Whether this import is marked as `deferred`.
  final bool isDeferred;

  const DartImportInfo(
    this.uri, {
    this.prefix,
    this.isDeferred = false,
    super.filePath,
  });

  /// Converts this import description into JSON.
  @override
  Map<String, Object?> toJson() => {
    'uri': uri,
    'prefix': prefix,
    'deferred': isDeferred,
  };

  /// Returns a Markdown list entry describing the import.
  @override
  String toMarkdown({bool withFilePath = true}) {
    final buf = StringBuffer('- `$uri`');

    if (prefix != null) {
      buf.write(' as $prefix');
    }

    if (isDeferred) {
      buf.write(' (deferred)');
    }

    return buf.toString();
  }

  /// Returns a Mermaid representation of this import.
  ///
  /// Produces a dependency edge suitable for a `classDiagram`,
  /// connecting the source file to the imported URI.
  ///
  /// The source node is derived from [filePath] when available,
  /// or `'unknown'` otherwise. Both source and target identifiers
  /// are sanitized to be valid Mermaid node IDs.
  ///
  /// If a prefix (`as`) or `deferred` modifier is present,
  /// they are included as an edge label.
  ///
  /// Example output:
  /// ```mermaid
  /// my_file_dart --> dart_async
  /// my_file_dart -->|as http| package_http_http_dart
  /// my_file_dart -->|deferred| some_lib
  /// ```
  @override
  String toMermaid() {
    final from = (filePath ?? 'unknown').toMermaidId();
    final to = uri.toMermaidId();

    final label = StringBuffer();
    if (prefix != null) label.write('as $prefix');
    if (isDeferred) {
      if (label.isNotEmpty) label.write(', ');
      label.write('deferred');
    }

    if (label.isEmpty) {
      return '$from --> $to';
    }

    return '$from -->|${label.toString()}| $to';
  }

  /// Returns a readable textual representation of the import.
  @override
  String toString({bool withFilePath = true}) {
    final buf = StringBuffer(uri);

    if (prefix != null) {
      buf.write(' as $prefix');
    }

    if (isDeferred) {
      buf.write(' (deferred)');
    }

    return buf.toString();
  }

  @override
  int compareTo(ReportInfo other) {
    var cmp = super.compareTo(other);
    if (cmp != 0) return cmp;

    if (other is DartImportInfo) {
      return uri.compareTo(other.uri);
    }

    return cmp;
  }
}

/// Report describing all imports declared in a Dart file.
class DartFileImports extends ReportInfo {
  /// List of imports found in the file.
  final List<DartImportInfo> imports;

  const DartFileImports(this.imports, {super.filePath});

  /// Converts this imports report into JSON format.
  @override
  Map<String, Object?> toJson() => {
    'filePath': filePath,
    'imports': imports.map((e) => e.toJson()).toList(),
  };

  /// Returns a Markdown section listing all imports.
  ///
  /// Optionally includes the source file path.
  @override
  String toMarkdown({bool withFilePath = true}) {
    final out = StringBuffer();

    out.writeln('### Imports');

    final filePath = this.filePath;
    if (withFilePath && filePath != null) {
      out.writeln('\nFile: $filePath');
    }

    out.writeln();

    for (final imp in imports) {
      out.writeln(imp.toMarkdown());
    }

    return out.toString();
  }

  /// Returns a Mermaid representation of this file's imports.
  ///
  /// Produces a set of relationships suitable for a `classDiagram`,
  /// where the current file is represented as a node and each import
  /// is rendered as a dependency edge to the imported URI.
  ///
  /// The file is identified using a sanitized version of [filePath]
  /// when available, or `'unknown'` otherwise.
  ///
  /// Each import is delegated to [DartImportInfo.toMermaid], allowing
  /// prefixes (`as`) and `deferred` modifiers to be included as edge labels.
  ///
  /// Example output:
  /// ```mermaid
  /// classDiagram
  /// class my_file_dart
  /// my_file_dart --> dart_async
  /// my_file_dart -->|as http| package_http_http_dart
  /// ```
  @override
  String toMermaid() {
    final b = StringBuffer();

    final fileId = (filePath ?? 'unknown').toMermaidId();

    // Represent file as a class-like node
    b.writeln('class $fileId');

    for (final imp in imports) {
      b.writeln(imp.toMermaid());
    }

    return b.toString();
  }

  /// Returns a readable multiline representation of file imports.
  ///
  /// Optionally includes the source file path.
  @override
  String toString({bool withFilePath = true}) {
    final out = StringBuffer();

    out.write('Imports');

    final filePath = this.filePath;
    if (withFilePath && filePath != null) {
      out.write(' ($filePath)');
    }

    out.writeln();

    for (final imp in imports) {
      out.writeln('  $imp');
    }

    return out.toString();
  }

  @override
  int compareTo(ReportInfo other) {
    var cmp = super.compareTo(other);
    if (cmp != 0) return cmp;

    if (other is! DartFileImports) {
      return -1;
    }

    return cmp;
  }
}

extension _MermaidSanitize on String {
  String toMermaidId() => replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
}

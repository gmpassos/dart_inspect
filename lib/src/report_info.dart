/// Base information used by report entries produced during Dart source analysis.
///
/// A report may optionally be associated with a [filePath], allowing results
/// to be traced back to the originating file.
///
/// Implementations must provide structured serialization via [toJson] and
/// human-readable representations through [toMarkdown] and [toString].
abstract class ReportInfo {
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

  /// Returns a human-readable textual representation of this report.
  ///
  /// When [withFilePath] is `true`, the associated file path is included
  /// when available.
  @override
  String toString({bool withFilePath = true});
}

/// Describes a Dart class field.
///
/// Stores the field [name] and its declared Dart [type].
class DartFieldInfo {
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
}

/// Report describing the fields declared in a Dart class.
class DartClassFields extends ReportInfo {
  /// Name of the analyzed class.
  final String className;

  /// Fields declared in the class.
  final List<DartFieldInfo> fields;

  const DartClassFields(this.className, this.fields, {super.filePath});

  /// Converts this class report into JSON format.
  @override
  Map<String, Object?> toJson() => {
    'className': className,
    'filePath': filePath,
    'fields': fields.map((f) => f.toJson()).toList(),
  };

  /// Returns a Markdown section listing all class fields.
  ///
  /// Optionally includes the source file path.
  @override
  String toMarkdown({bool withFilePath = true}) {
    final out = StringBuffer();

    out.writeln('### $className');

    final filePath = this.filePath;
    if (withFilePath && filePath != null && filePath.isNotEmpty) {
      out.write('\nFile: $filePath\n');
    }

    out.writeln();

    for (final field in fields) {
      out.writeln('- $field');
    }

    return out.toString();
  }

  /// Returns a readable multiline description of the class and its fields.
  ///
  /// Optionally includes the source file path.
  @override
  String toString({bool withFilePath = true}) {
    final str = StringBuffer();

    str.write(className);

    final filePath = this.filePath;
    if (withFilePath && filePath != null && filePath.isNotEmpty) {
      str.write(' ($filePath)');
    }

    str.writeln();

    for (final field in fields) {
      str.writeln('  $field');
    }

    return str.toString();
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
}

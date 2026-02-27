import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'report_info.dart';

/// Configuration options used by [DartInspect] to control what is
/// discovered and emitted in inspection reports.
///
/// These options allow filtering of classes, fields, and imports,
/// as well as selecting the output format.
class DartInspectOptions {
  /// Include only private fields (names starting with `_`).
  final bool privateOnly;

  /// Exclude fields whose types are considered primitive or common
  /// built-in Dart types.
  final bool noPrimitives;

  /// Include only `final` fields.
  ///
  /// Cannot be used together with [noFinal].
  final bool finalOnly;

  /// Exclude `final` fields.
  ///
  /// Cannot be used together with [finalOnly].
  final bool noFinal;

  /// Do not include class fields in the report.
  final bool noClasses;

  /// Do not include file imports in the report.
  final bool noImports;

  /// Output report in Markdown format.
  final bool markdown;

  /// Creates inspection options.
  ///
  /// The assertion prevents incompatible configurations where both
  /// [finalOnly] and [noFinal] are enabled.
  const DartInspectOptions({
    this.privateOnly = false,
    this.noPrimitives = false,
    this.finalOnly = false,
    this.noFinal = false,
    this.noClasses = false,
    this.noImports = false,
    this.markdown = false,
  }) : assert(!(finalOnly && noFinal), 'Cannot use finalOnly with noFinal');

  /// Returns `true` when using the simple (non-Markdown) output mode.
  bool get simple => !markdown;

  /// Internal flag names representing enabled options.
  ///
  /// Intended mainly for debugging and diagnostics.
  List<String> get flags => <String>[
    if (privateOnly) 'privateOnly',
    if (noPrimitives) 'noPrimitives',
    if (finalOnly) 'finalOnly',
    if (noFinal) 'noFinal',
    if (noClasses) 'noClasses',
    if (noImports) 'noImports',
    if (markdown) 'markdown',
  ];

  /// CLI-style option names corresponding to enabled flags.
  ///
  /// Useful for displaying command-line configuration summaries.
  List<String> get options => <String>[
    if (privateOnly) '--private-only',
    if (noPrimitives) '--no-primitives',
    if (finalOnly) '--final-only',
    if (noFinal) '--no-final',
    if (noClasses) '--no-classes',
    if (noImports) '--no-imports',
    if (markdown) '--markdown',
  ];

  @override
  String toString() {
    final flags = this.flags;

    return flags.isEmpty
        ? 'DartInspectOptions(default)'
        : 'DartInspectOptions(${flags.join(', ')})';
  }
}

/// Primitive Dart types used to optionally filter fields.
const _primitiveTypes = {
  'String',
  'int',
  'num',
  'double',
  'bool',
  'Object',
  'dynamic',
  'DateTime',
};

/// Extended primitive representations including nullable and
/// `Future<T>` variants.
final _primitiveTypesExtended = {
  ..._primitiveTypes,
  ..._primitiveTypes.map((e) => '$e?'),
  ..._primitiveTypes.map((e) => 'Future<$e>'),
  ..._primitiveTypes.map((e) => 'Future<$e?>'),
};

/// Scans Dart source code to extract structured information such as
/// imports and class fields.
///
/// The inspection process can operate on directories, files,
/// or raw source code strings.
class DartInspect {
  /// Inspection behavior configuration.
  final DartInspectOptions options;

  /// Creates a new inspector using the provided [options].
  const DartInspect(this.options);

  /// Recursively scans a directory for `.dart` files and emits
  /// discovered report entries.
  ///
  /// Symbolic links are not followed.
  Stream<ReportInfo> scanDirectory(Directory root) async* {
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }

      yield* scanFile(entity);
    }
  }

  /// Scans a single Dart [file].
  ///
  /// The file content is read and forwarded to [scanCode].
  Stream<ReportInfo> scanFile(File file) async* {
    final content = await file.readAsString();
    yield* scanCode(content, filePath: file.path);
  }

  /// Analyzes Dart source [content] and emits discovered report data.
  ///
  /// Optionally associates results with a [filePath].
  ///
  /// The analyzer AST is used to detect:
  /// - import directives
  /// - class declarations
  /// - instance field definitions
  Stream<ReportInfo> scanCode(String content, {String? filePath}) async* {
    final result = parseString(
      content: content,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );

    final unit = result.unit;

    // Inspect imports.
    if (!options.noImports) {
      final imports = <DartImportInfo>[];

      // Collect import directives.
      for (final directive in unit.directives) {
        if (directive is ImportDirective) {
          imports.add(
            DartImportInfo(
              directive.uri.stringValue ?? '',
              prefix: directive.prefix?.name,
              isDeferred: directive.deferredKeyword != null,
            ),
          );
        }
      }

      // Emit file imports if present.
      if (imports.isNotEmpty) {
        yield DartFileImports(imports, filePath: filePath);
      }
    }

    // Inspect class declarations.
    if (!options.noClasses) {
      for (final decl in unit.declarations) {
        if (decl is! ClassDeclaration) continue;

        final fields = <DartFieldInfo>[];

        var body = decl.body as BlockClassBody;

        // Inspect instance fields.
        for (final member in body.members) {
          if (member is! FieldDeclaration) continue;
          if (member.isStatic) continue;

          final fieldList = member.fields;
          final isFinal = fieldList.isFinal;

          if (options.finalOnly && !isFinal) continue;
          if (options.noFinal && isFinal) continue;

          final type = fieldList.type?.toSource() ?? 'dynamic';

          if (options.noPrimitives && _primitiveTypesExtended.contains(type)) {
            continue;
          }

          for (final variable in fieldList.variables) {
            final name = variable.name.lexeme;

            if (options.privateOnly && !name.startsWith('_')) {
              continue;
            }

            fields.add(DartFieldInfo(name, type));
          }
        }

        if (fields.isEmpty) continue;

        final className = decl.namePart.typeName.lexeme;

        yield DartClassFields(className, fields, filePath: filePath);
      }
    }
  }
}

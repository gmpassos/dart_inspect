## 1.0.6

- CLI (`bin/dart_inspect.dart`):
  - Added `--ignore-generated` option to ignore generated Dart files (e.g., `.g.dart`, `.freezed.dart`).

- `DartInspectOptions` (`lib/src/dart_inspect_base.dart`):
  - Added `ignoreGenerated` boolean option to control ignoring generated files.
  - Updated `flags` and `options` getters to include `ignoreGenerated`.

- `DartInspect` (`lib/src/dart_inspect_base.dart`):
  - Added `generatedFilesExtension` list with common generated file suffixes.
  - Added `isGeneratedFile` method to detect generated files by suffix.
  - Updated `scanCode` to skip processing files identified as generated when `ignoreGenerated` is enabled.

## 1.0.5

- CLI (`bin/dart_inspect.dart`):
  - Updated usage to accept either a directory or a file as input path.
  - Improved path handling in `main`:
    - Detects if input path is a file or directory.
    - Handles non-existent paths and unsupported path types with appropriate error messages and exit codes.

- `DartInspectReporter` and subclasses (`reporter_markdown.dart`, `reporter_mermaid.dart`, `reporter_simple.dart`):
  - Renamed constructor parameter from `directory` to `path` to reflect that input can be a file or directory.
  - Updated all references and documentation accordingly.
  - Updated output headers to use `Path` instead of `Directory`.

## 1.0.4

- `DartInspectReporterMermaid`:
  - `buildReport`:
    - Sanitized class names in Mermaid output to replace special characters `$`, `(`, `)`, `{`, `}` with underscores.
    - Limited class stereotypes to show only the last stereotype instead of multiple.
    - Sanitized class names in relationship arrows.
  - `_sanitize`:
    - Extended to replace additional special characters `$`, `(`, `)`, `{`, `}` with underscores.

## 1.0.3

- CLI (`bin/dart_inspect.dart`):
  - Added new option `--no-empty-classes` to exclude empty classes from the report.
  - Added new option `--sort-entries` to sort fields and classes alphabetically (default: false).

- `DartInspectOptions` (`lib/src/dart_inspect_base.dart`):
  - Added `noEmptyClasses` boolean option to exclude empty classes.
  - Updated constructor, flags, and options getters to support `noEmptyClasses`.

- Refactor `DartClassFields` to `DartClassInfo`:
  - Added fields: `interfaces`, `mixins`, `superClass`, `isAbstract`, `isInterface`, `isMixin`.
  - Updated JSON, Markdown, Mermaid, and string serialization to include class hierarchy and modifiers.
  - Added equality, hashCode, and comparison operators for sorting and deduplication.
  - Updated `DartInspect` to yield `DartClassInfo` with inheritance and interface info.
  - Updated tests to use `DartClassInfo`.

- `DartInspect`:
  - Extracts and reports class `superClass`, `interfaces`, and `mixins`.
  - Yields `DartClassInfo` instead of `DartClassFields`.
  - Updated class scanning logic to skip empty classes when `noEmptyClasses` is enabled.

- `DartInspectReporterMarkdown`:
  - Groups reports by file path for stable output.
  - Supports rendering `DartClassInfo` with hierarchy and modifiers.

- `DartInspectReporterMermaid`:
  - Collects full `DartClassInfo` objects keyed by class name.
  - Renders class stereotypes (`abstract`, `interface`, `mixin`).
  - Renders inheritance (`extends`), interface implementation (`implements`), and mixins as Mermaid relationships.
  - Deduplicates fields in Mermaid output.

- `DartInspectReporterSimple`:
  - Groups reports by file path.
  - Sorts and renders `DartClassInfo` with hierarchy info.

- `ReportInfo`:
  - Implements `Comparable` for sorting by file path and class name.

- `DartImportInfo`:
  - Implements `Comparable` for sorting by URI.

- collection: ^1.19.1

## 1.0.2

- Added Mermaid output format support:
  - CLI option `--mermaid` to generate Mermaid class diagrams.
  - `DartInspectOptions` includes `mermaid` flag with validation against `markdown`.
  - `DartInspectReporterMermaid` reporter generates Mermaid `classDiagram` output with classes, fields, and relationships.
  - `ReportInfo` subclasses (`DartClassFields`, `DartImportInfo`, `DartFileImports`) implement `toMermaid()` for Mermaid serialization.
  - CLI enforces mutually exclusive output formats: `--simple` (default), `--markdown`, `--mermaid`.
  - README updated with Mermaid usage instructions, examples, and format notes.

- Refactored reporters:
  - Introduced abstract base class `DartInspectReporter` for output format implementations.
  - `DartInspectReporterSimple` and `DartInspectReporterMarkdown` refactored to use the new base class.

- `dart_inspect.dart` CLI:
  - Simplified output logic by delegating to reporter classes.
  - Added validation for mutually exclusive format options.
  - Added Mermaid format support.

- `DartInspectOptions`:
  - Added `mermaid` boolean flag.
  - Updated `simple` getter to exclude `mermaid` and `markdown`.
  - Added assertions to prevent incompatible options (`markdown` and `mermaid`).

- `ReportInfo` classes:
  - Added `toMermaid()` method to support Mermaid output.
  - `DartClassFields.toMermaid()` outputs Mermaid class with fields.
  - `DartImportInfo.toMermaid()` outputs Mermaid dependency edges with optional labels.
  - `DartFileImports.toMermaid()` outputs Mermaid class node and import edges.

- Updated `pubspec.yaml` dependencies:
  - `test` to ^1.31.0
  - `dependency_validator` to ^5.0.5

## 1.0.1

- `bin/dart_inspect.dart`:
  - Reduced Markdown output separator from 80 dashes to 3 dashes to save tokens.

## 1.0.0

- Initial version.

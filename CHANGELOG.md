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

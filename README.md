# dart_inspect

[![pub package](https://img.shields.io/pub/v/dart_inspect.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/dart_inspect)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/dart_inspect?logo=git&logoColor=white)](https://github.com/gmpassos/dart_inspect/releases)
[![Last Commit](https://img.shields.io/github/last-commit/gmpassos/dart_inspect?logo=github&logoColor=white)](https://github.com/gmpassos/dart_inspect/commits/main)
[![License](https://img.shields.io/github/license/gmpassos/dart_inspect?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/dart_inspect/blob/main/LICENSE)

`dart_inspect` is a Dart source analysis tool for **discovering and reporting project structure**.

It analyzes Dart code using the official analyzer AST to extract:

* 📦 File imports
* 🧩 Class declarations
* 🏷 Instance fields and types

The tool can be used both as a **CLI utility** and as a **programmatic inspection library**, making it useful for:

* architecture inspection
* dependency auditing
* documentation generation
* CI validation
* large codebase exploration

---

## Usage

## CLI

Activate globally:

```bash
dart pub global activate dart_inspect
````

Run inspection:

```bash
dart_inspect [directory] [options]
```

### Options

* `--private-only`
  Include only private fields (`_field`).

* `--final-only`
  Include only `final` fields.

* `--no-final`
  Exclude `final` fields.

* `--no-primitives`
  Ignore primitive/common Dart types such as `String`, `int`, `bool`, etc.

* `--no-classes`
  Do not report class fields.

* `--no-imports`
  Do not report imports.

* `--markdown`
  Output report in Markdown format.

* `-h`, `--help`
  Show help message.

---

### Examples

Inspect the current project:

```bash
dart_inspect
```

Inspect another directory:

```bash
dart_inspect ../backend
```

Generate a Markdown architecture report:

```bash
dart_inspect lib --markdown
```

Inspect only private state fields:

```bash
dart_inspect lib --private-only
```

Show only non-primitive domain fields:

```bash
dart_inspect lib --no-primitives
```

---

## Example Output

### Simple Output

```
lib/src/user.dart

User
  int id
  String name
  Token _token
```

---

### Markdown Output

```md
## lib/src/user.dart

### Imports

- `dart:async`
- `package:http/http.dart`

### User

- int id
- String name
- Token _token
```

Perfect for:

* GitHub documentation
* architecture reports
* automated CI artifacts
* AI input

---

## Programmatic Usage

`dart_inspect` can be embedded directly into Dart tools and automation workflows.

```dart
import 'dart:io';
import 'package:dart_inspect/dart_inspect.dart';

Future<void> main() async {
  const options = DartInspectOptions(
    markdown: true,
    noPrimitives: true,
  );

  final inspector = DartInspect(options);

  await for (final report
      in inspector.scanDirectory(Directory('lib'))) {
    print(report.toMarkdown());
  }
}
```

You can also analyze raw source code:

```dart
final inspect = DartInspect(
  const DartInspectOptions(),
);

await for (final report in inspect.scanCode(source)) {
  print(report);
}
```

---

## How It Works

1. Parses Dart files using the analyzer AST
2. Collects import directives
3. Detects class declarations
4. Extracts instance fields and types
5. Emits structured reports as a stream

This allows inspection of very large projects efficiently.

---

## Issues & Feature Requests

Please report issues or request features via the
[issue tracker][tracker].

[tracker]: https://github.com/gmpassos/dart_inspect/issues

---

## Author

Graciliano M. Passos: [gmpassos@GitHub][github]

[github]: https://github.com/gmpassos

---

## License

Dart free & open-source [license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).


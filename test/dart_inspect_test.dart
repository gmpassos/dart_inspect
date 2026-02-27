import 'dart:io';

import 'package:dart_inspect/dart_inspect.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('Model objects', () {
    test('DartFieldInfo serialization', () {
      const field = DartFieldInfo('id', 'int');

      expect(field.toString(), 'int id');
      expect(field.toJson(), {'name': 'id', 'type': 'int'});
    });

    test('DartImportInfo formatting', () {
      const imp = DartImportInfo(
        'dart:async',
        prefix: 'async',
        isDeferred: true,
      );

      expect(imp.toString(), 'dart:async as async (deferred)');

      expect(imp.toMarkdown(), '- `dart:async` as async (deferred)');
    });
  });

  group('DartInspectOptions', () {
    test('default configuration', () {
      const opts = DartInspectOptions();

      expect(opts.simple, isTrue);
      expect(opts.flags, isEmpty);
      expect(opts.options, isEmpty);
    });

    test('CLI flags generation', () {
      const opts = DartInspectOptions(
        privateOnly: true,
        markdown: true,
        noImports: true,
      );

      expect(
        opts.options,
        containsAll(['--private-only', '--markdown', '--no-imports']),
      );
    });

    test('invalid combination throws', () {
      expect(
        () => DartInspectOptions(finalOnly: true, noFinal: true),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('scanCode()', () {
    const source = '''
import 'dart:io';
import 'dart:async' as async;

class User {
  final int id = 0;
  String name = '';
  final String? email = null;
  final String _token = '';

  static int ignored = 0;
}
''';

    Future<List<ReportInfo>> scan(DartInspectOptions options) {
      final inspect = DartInspect(options);

      return inspect.scanCode(source, filePath: 'test.dart').toList();
    }

    test('emits imports first', () async {
      final results = await scan(const DartInspectOptions());

      expect(results.first, isA<DartFileImports>());
    });

    test('imports contain prefix', () async {
      final imports = (await scan(
        const DartInspectOptions(),
      )).whereType<DartFileImports>().single;

      expect(imports.imports.length, 2);

      expect(imports.imports.any((i) => i.prefix == 'async'), isTrue);
    });

    test('class detection', () async {
      final cls = (await scan(
        const DartInspectOptions(),
      )).whereType<DartClassFields>().single;

      expect(cls.className, 'User');
      expect(cls.filePath, 'test.dart');
    });

    test('ignores static fields', () async {
      final cls = (await scan(
        const DartInspectOptions(),
      )).whereType<DartClassFields>().single;

      expect(cls.fields.any((f) => f.name == 'ignored'), isFalse);
    });

    test('privateOnly filter', () async {
      final cls = (await scan(
        const DartInspectOptions(privateOnly: true),
      )).whereType<DartClassFields>().single;

      expect(cls.fields.length, 1);
      expect(cls.fields.first.name, '_token');
    });

    test('finalOnly filter', () async {
      final cls = (await scan(
        const DartInspectOptions(finalOnly: true),
      )).whereType<DartClassFields>().single;

      expect(
        cls.fields.map((e) => e.name),
        containsAll(['id', 'email', '_token']),
      );

      expect(cls.fields.map((e) => e.name), isNot(contains('name')));
    });

    test('noFinal filter', () async {
      final cls = (await scan(
        const DartInspectOptions(noFinal: true),
      )).whereType<DartClassFields>().single;

      expect(cls.fields.length, 1);
      expect(cls.fields.first.name, 'name');
    });

    test('noPrimitives removes primitive fields', () async {
      final results = await scan(const DartInspectOptions(noPrimitives: true));

      expect(results.whereType<DartClassFields>(), isEmpty);
    });

    test('noImports option (expected behavior)', () async {
      final results = await scan(const DartInspectOptions(noImports: true));

      expect(results.whereType<DartFileImports>(), isEmpty);
    });
  });

  group('Markdown output', () {
    test('class markdown format stable', () {
      const report = DartClassFields('User', [
        DartFieldInfo('id', 'int'),
      ], filePath: 'a.dart');

      final md = report.toMarkdown();

      expect(md, contains('### User'));
      expect(md, contains('- int id'));
      expect(md, contains('File: a.dart'));
    });

    test('imports markdown format', () {
      const report = DartFileImports([
        DartImportInfo('dart:io'),
      ], filePath: 'file.dart');

      final md = report.toMarkdown();

      expect(md, contains('### Imports'));
      expect(md, contains('dart:io'));
    });
  });

  group('Filesystem scanning', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = _createTempDir();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('scanFile propagates filePath', () async {
      final file = File(path.join(tempDir.path, 'a.dart'));

      await file.writeAsString('''
class A {
  int x = 0;
}
''');

      const inspect = DartInspect(DartInspectOptions());

      final results = await inspect.scanFile(file).toList();

      final cls = results.whereType<DartClassFields>().single;

      expect(cls.filePath, file.path);
    });

    test('scanDirectory finds dart files recursively', () async {
      final sub = Directory(path.join(tempDir.path, 'lib'))..createSync();

      final file = File(path.join(sub.path, 'model.dart'));

      await file.writeAsString('''
class Model {
  int id = 0;
}
''');

      const inspect = DartInspect(DartInspectOptions());

      final results = await inspect.scanDirectory(tempDir).toList();

      expect(results.whereType<DartClassFields>(), isNotEmpty);
    });
  });
}

Directory _createTempDir() {
  var tempDir = Directory(
    Directory.systemTemp.path,
  ).createTempSync('dart_inspect_test_');
  return Directory(tempDir.resolveSymbolicLinksSync());
}

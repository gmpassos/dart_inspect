import 'package:dart_inspect/dart_inspect.dart';
import 'package:test/test.dart';

void main() {
  group('DartFieldInfo', () {
    test('toJson', () {
      final f = DartFieldInfo('name', 'String');

      expect(f.toJson(), {'name': 'name', 'type': 'String'});
    });

    test('toString', () {
      final f = DartFieldInfo('age', 'int');
      expect(f.toString(), 'int age');
    });
  });

  group('DartClassInfo', () {
    final fields = [
      DartFieldInfo('name', 'String'),
      DartFieldInfo('age', 'int'),
    ];

    test('toJson', () {
      final c = DartClassInfo('User', fields, filePath: 'user.dart');

      expect(c.toJson(), {
        'className': 'User',
        'filePath': 'user.dart',
        'fields': [
          {'name': 'name', 'type': 'String'},
          {'name': 'age', 'type': 'int'},
        ],
      });
    });

    test('toMarkdown with filePath', () {
      final c = DartClassInfo('User', fields, filePath: 'user.dart');

      final md = c.toMarkdown();

      expect(md, contains('### User'));
      expect(md, contains('File: user.dart'));
      expect(md, contains('- String name'));
      expect(md, contains('- int age'));
    });

    test('toMarkdown without filePath', () {
      final c = DartClassInfo('User', fields);

      final md = c.toMarkdown();

      expect(md, isNot(contains('File:')));
    });

    test('toMermaid', () {
      final c = DartClassInfo('User', fields);

      final m = c.toMermaid();

      expect(m, contains('class User'));
      expect(m, contains('String name'));
      expect(m, contains('int age'));
    });

    test('toString', () {
      final c = DartClassInfo('User', fields, filePath: 'user.dart');

      final s = c.toString();

      expect(s, contains('User (user.dart)'));
      expect(s, contains('  String name'));
      expect(s, contains('  int age'));
    });

    test('toJson with inheritance', () {
      final c = DartClassInfo(
        'User',
        fields,
        filePath: 'user.dart',
        superClass: 'Person',
        interfaces: ['Serializable', 'Equatable'],
        mixins: ['Logger', 'Validator'],
      );

      expect(c.toJson(), {
        'className': 'User',
        'filePath': 'user.dart',
        'superClass': 'Person',
        'interfaces': ['Serializable', 'Equatable'],
        'mixins': ['Logger', 'Validator'],
        'fields': [
          {'name': 'name', 'type': 'String'},
          {'name': 'age', 'type': 'int'},
        ],
      });
    });

    test('toMarkdown with inheritance', () {
      final c = DartClassInfo(
        'User',
        fields,
        superClass: 'Person',
        interfaces: ['Serializable'],
        mixins: ['Logger'],
      );

      final md = c.toMarkdown();

      expect(md, contains('### User'));
      expect(md, contains('extends Person'));
      expect(md, contains('implements Serializable'));
      expect(md, contains('with Logger'));
    });

    test('toMermaid with inheritance', () {
      final c = DartClassInfo(
        'User',
        fields,
        superClass: 'Person',
        interfaces: ['Serializable'],
        mixins: ['Logger'],
      );

      final m = c.toMermaid();

      // inheritance
      expect(m, contains('Person <|-- User'));

      // interface
      expect(m, contains('Serializable <|.. User'));

      // mixin (commonly represented similarly to interface or dependency)
      expect(m, contains('Logger <|.. User'));
    });

    test('toString with inheritance', () {
      final c = DartClassInfo(
        'User',
        fields,
        filePath: 'user.dart',
        superClass: 'Person',
        interfaces: ['Serializable'],
        mixins: ['Logger'],
      );

      final s = c.toString();

      expect(s, contains('User (user.dart)'));
      expect(s, contains('extends Person'));
      expect(s, contains('implements Serializable'));
      expect(s, contains('with Logger'));
    });
  });

  group('DartImportInfo', () {
    test('toJson', () {
      final i = DartImportInfo('dart:async', prefix: 'async', isDeferred: true);

      expect(i.toJson(), {
        'uri': 'dart:async',
        'prefix': 'async',
        'deferred': true,
      });
    });

    test('toMarkdown', () {
      final i = DartImportInfo('dart:async', prefix: 'async', isDeferred: true);

      final md = i.toMarkdown();

      expect(md, contains('`dart:async`'));
      expect(md, contains('as async'));
      expect(md, contains('deferred'));
    });

    test('toMermaid without label', () {
      final i = DartImportInfo('dart:async', filePath: 'main.dart');

      final m = i.toMermaid();

      expect(m, contains('main_dart --> dart_async'));
    });

    test('toMermaid with label', () {
      final i = DartImportInfo(
        'package:http/http.dart',
        prefix: 'http',
        isDeferred: true,
        filePath: 'main.dart',
      );

      final m = i.toMermaid();

      expect(m, contains('main_dart -->|as http, deferred|'));
    });

    test('toString', () {
      final i = DartImportInfo('dart:async', prefix: 'async', isDeferred: true);

      expect(i.toString(), 'dart:async as async (deferred)');
    });
  });

  group('DartFileImports', () {
    final imports = [
      DartImportInfo('dart:async', filePath: 'main.dart'),
      DartImportInfo(
        'package:http/http.dart',
        prefix: 'http',
        filePath: 'main.dart',
      ),
    ];

    test('toJson', () {
      final f = DartFileImports(imports, filePath: 'main.dart');

      expect(f.toJson(), {
        'filePath': 'main.dart',
        'imports': [
          {'uri': 'dart:async', 'prefix': null, 'deferred': false},
          {
            'uri': 'package:http/http.dart',
            'prefix': 'http',
            'deferred': false,
          },
        ],
      });
    });

    test('toMarkdown', () {
      final f = DartFileImports(imports, filePath: 'main.dart');

      final md = f.toMarkdown();

      expect(md, contains('### Imports'));
      expect(md, contains('File: main.dart'));
      expect(md, contains('`dart:async`'));
      expect(md, contains('`package:http/http.dart` as http'));
    });

    test('toMermaid', () {
      final f = DartFileImports(imports, filePath: 'main.dart');

      final m = f.toMermaid();

      expect(m, contains('class main_dart'));
      expect(m, contains('main_dart --> dart_async'));
      expect(m, contains('main_dart -->'));
    });

    test('toString', () {
      final f = DartFileImports(imports, filePath: 'main.dart');

      final s = f.toString();

      expect(s, contains('Imports (main.dart)'));
      expect(s, contains('dart:async'));
      expect(s, contains('package:http/http.dart as http'));
    });
  });
}

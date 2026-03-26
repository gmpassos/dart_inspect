import 'dart:async';

import 'package:dart_inspect/dart_inspect.dart';
import 'package:test/test.dart';

Stream<ReportInfo> _mockStream() async* {
  yield DartFileImports([DartImportInfo('dart:io')], filePath: 'a.dart');

  yield DartClassInfo(
    'Base',
    [DartFieldInfo('createdAt', 'DateTime')],
    isAbstract: true,
    filePath: 'a.dart',
  );

  yield DartClassInfo(
    'User',
    [DartFieldInfo('name', 'String'), DartFieldInfo('account', 'Account')],
    superClass: 'Base',
    interfaces: ['Serializable'],
    mixins: ['WithLogger'],
    filePath: 'a.dart',
  );

  yield DartClassInfo(
    'Account',
    [DartFieldInfo('id', 'int')],
    isInterface: true,
    filePath: 'a.dart',
  );

  yield DartClassInfo('WithLogger', [], isMixin: true, filePath: 'a.dart');
}

void main() {
  group('DartInspectReporterSimple', () {
    test('produces expected simple output', () async {
      final reporter = DartInspectReporterSimple(
        'test_dir',
        const DartInspectOptions(),
      );

      final output = await reporter.build(_mockStream());

      expect(output, contains('dart_inspect'));
      expect(output, contains('Directory : test_dir'));
      expect(output, contains('Format    : simple'));

      expect(output, contains('Imports:'));
      expect(output, contains('User'));
      expect(output, contains('Account'));
    });
  });

  group('DartInspectReporterMarkdown', () {
    test('produces markdown structure with hierarchy', () async {
      final reporter = DartInspectReporterMarkdown(
        'test_dir',
        const DartInspectOptions(markdown: true),
      );

      final output = await reporter.build(_mockStream());

      expect(output, contains('# Dart Inspect Report'));
      expect(output, contains('## Configuration'));
      expect(output, contains('## a.dart'));

      // modifiers
      expect(output, contains('abstract Base'));
      expect(output, contains('interface Account'));
      expect(output, contains('mixin WithLogger'));

      // hierarchy
      expect(output, contains('Extends: Base'));
      expect(output, contains('Implements: Serializable'));
      expect(output, contains('With: WithLogger'));
    });
  });

  group('DartInspectReporterMermaid', () {
    test('produces mermaid diagram with full relationships', () async {
      final reporter = DartInspectReporterMermaid(
        'test_dir',
        const DartInspectOptions(mermaid: true),
      );

      final output = await reporter.build(_mockStream());

      expect(output, contains('classDiagram'));

      expect(output, contains('class User'));
      expect(output, contains('class Account'));
      expect(output, contains('class Base'));

      // inheritance
      expect(output, contains('Base <|-- User'));

      // interface
      expect(output, contains('Serializable <|.. User'));

      // mixin (dependency style)
      expect(output, contains('WithLogger ..> User'));
    });

    test('deduplicates fields', () async {
      final stream = Stream<ReportInfo>.fromIterable([
        DartClassInfo('User', [
          DartFieldInfo('name', 'String'),
          DartFieldInfo('name', 'String'),
        ], filePath: 'a.dart'),
      ]);

      final reporter = DartInspectReporterMermaid(
        'test_dir',
        const DartInspectOptions(mermaid: true),
      );

      final output = await reporter.build(stream);

      final occurrences = RegExp(r'String name').allMatches(output).length;
      expect(occurrences, 1);
    });
  });
}

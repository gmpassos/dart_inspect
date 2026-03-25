import 'dart:async';

import 'package:dart_inspect/dart_inspect.dart';
import 'package:test/test.dart';

Stream<ReportInfo> _mockStream() async* {
  yield DartFileImports([DartImportInfo('dart:io')], filePath: 'a.dart');

  yield DartClassFields('User', [
    DartFieldInfo('name', 'String'),
    DartFieldInfo('account', 'Account'),
  ], filePath: 'a.dart');

  yield DartClassFields('Account', [
    DartFieldInfo('id', 'int'),
  ], filePath: 'a.dart');
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
    test('produces markdown structure', () async {
      final reporter = DartInspectReporterMarkdown(
        'test_dir',
        const DartInspectOptions(markdown: true),
      );

      final output = await reporter.build(_mockStream());

      expect(output, contains('# Dart Inspect Report'));
      expect(output, contains('## Configuration'));
      expect(output, contains('## a.dart'));

      expect(output, contains('User'));
      expect(output, contains('Account'));
    });
  });

  group('DartInspectReporterMermaid', () {
    test('produces mermaid diagram', () async {
      final reporter = DartInspectReporterMermaid(
        'test_dir',
        const DartInspectOptions(mermaid: true),
      );

      final output = await reporter.build(_mockStream());

      expect(output, contains('classDiagram'));

      expect(output, contains('class User'));
      expect(output, contains('class Account'));

      // relationship inferred
      expect(output, contains('User --> Account'));
    });

    test('deduplicates fields', () async {
      final stream = Stream<ReportInfo>.fromIterable([
        DartClassFields('User', [
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

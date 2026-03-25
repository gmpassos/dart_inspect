import 'package:dart_inspect/dart_inspect.dart';
import 'package:test/test.dart';

void main() {
  group('DartInspectOptions', () {
    test('default values', () {
      const options = DartInspectOptions();

      expect(options.privateOnly, false);
      expect(options.noPrimitives, false);
      expect(options.finalOnly, false);
      expect(options.noFinal, false);
      expect(options.noClasses, false);
      expect(options.noImports, false);
      expect(options.markdown, false);
      expect(options.mermaid, false);

      expect(options.flags, isEmpty);
      expect(options.options, isEmpty);

      expect(options.simple, true);
      expect(options.toString(), 'DartInspectOptions(default)');
    });

    test('includes all enabled flags and options', () {
      const options = DartInspectOptions(
        privateOnly: true,
        noPrimitives: true,
        finalOnly: true,
        noClasses: true,
        noImports: true,
        mermaid: true,
      );

      expect(
        options.flags,
        containsAll([
          'privateOnly',
          'noPrimitives',
          'finalOnly',
          'noClasses',
          'noImports',
          'mermaid',
        ]),
      );

      expect(
        options.options,
        containsAll([
          '--private-only',
          '--no-primitives',
          '--final-only',
          '--no-classes',
          '--no-imports',
          '--mermaid',
        ]),
      );
    });

    test('includes markdown option', () {
      const options = DartInspectOptions(markdown: true);

      expect(options.flags, contains('markdown'));
      expect(options.options, contains('--markdown'));
    });

    test('includes mermaid flag', () {
      const options = DartInspectOptions(mermaid: true);

      expect(options.flags, contains('mermaid'));
      expect(options.options, contains('--mermaid'));
    });

    test('rejects markdown + mermaid', () {
      expect(
        () => DartInspectOptions(markdown: true, mermaid: true),
        throwsA(isA<AssertionError>()),
      );
    });

    test('simple is false when markdown is true', () {
      const options = DartInspectOptions(markdown: true);

      expect(options.simple, false);
    });

    test('simple SHOULD be false when mermaid is true (expected behavior)', () {
      const options = DartInspectOptions(mermaid: true);

      // ⚠️ This currently FAILS with your implementation
      // because simple = !markdown
      expect(options.simple, false);
    });

    test('rejects finalOnly + noFinal', () {
      expect(
        () => DartInspectOptions(finalOnly: true, noFinal: true),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects markdown + mermaid', () {
      expect(
        () => DartInspectOptions(markdown: true, mermaid: true),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toString with flags', () {
      const options = DartInspectOptions(privateOnly: true, mermaid: true);

      final str = options.toString();

      expect(str, contains('privateOnly'));
      expect(str, contains('mermaid'));
    });
  });
}

import 'package:dart_inspect/dart_inspect.dart';
import 'package:test/test.dart';

void main() {
  group('DartClassInfo - Model', () {
    test('basic class info creation', () {
      const classInfo = DartClassInfo('User', [
        DartFieldInfo('id', 'int'),
        DartFieldInfo('name', 'String'),
      ], filePath: 'models/user.dart');

      expect(classInfo.className, 'User');
      expect(classInfo.fields.length, 2);
      expect(classInfo.filePath, 'models/user.dart');
    });

    test('class with no superclass', () {
      const classInfo = DartClassInfo('SimpleClass', [], superClass: null);

      expect(classInfo.superClass, isNull);
      expect(classInfo.isAbstract, isFalse);
    });

    test('abstract class modifier', () {
      const classInfo = DartClassInfo('AbstractBase', [], isAbstract: true);

      expect(classInfo.isAbstract, isTrue);
      expect(classInfo.toString(), contains('abstract'));
    });

    test('interface modifier', () {
      const classInfo = DartClassInfo('Drawable', [], isInterface: true);

      expect(classInfo.isInterface, isTrue);
    });

    test('mixin modifier', () {
      const classInfo = DartClassInfo('LoggerMixin', [], isMixin: true);

      expect(classInfo.isMixin, isTrue);
    });

    test('class with single superclass', () {
      const classInfo = DartClassInfo('User', [], superClass: 'Person');

      expect(classInfo.superClass, 'Person');
    });

    test('class with interfaces', () {
      const classInfo = DartClassInfo(
        'Dog',
        [],
        interfaces: ['Animal', 'Trainable'],
      );

      expect(classInfo.interfaces, ['Animal', 'Trainable']);
      expect(classInfo.interfaces.length, 2);
    });

    test('class with mixins', () {
      const classInfo = DartClassInfo(
        'Logger',
        [],
        mixins: ['TimestampMixin', 'ColorMixin'],
      );

      expect(classInfo.mixins, ['TimestampMixin', 'ColorMixin']);
    });

    test('class with all hierarchy info', () {
      const classInfo = DartClassInfo(
        'AdvancedUser',
        [DartFieldInfo('id', 'int')],
        superClass: 'Person',
        interfaces: ['Serializable', 'Comparable'],
        mixins: ['TimestampMixin'],
        isAbstract: false,
        isInterface: false,
        isMixin: false,
      );

      expect(classInfo.superClass, 'Person');
      expect(classInfo.interfaces.length, 2);
      expect(classInfo.mixins.length, 1);
    });
  });

  group('DartClassInfo - JSON Serialization', () {
    test('toJson includes hierarchy info', () {
      const classInfo = DartClassInfo(
        'Dog',
        [DartFieldInfo('name', 'String')],
        superClass: 'Animal',
        interfaces: ['Comparable'],
        isAbstract: false,
      );

      final json = classInfo.toJson();

      expect(json['className'], 'Dog');
      expect(json['superClass'], 'Animal');
      expect(json['interfaces'], ['Comparable']);
      expect(json['isAbstract'], isNull);
    });

    test('toJson handles null superclass', () {
      const classInfo = DartClassInfo('Root', [], superClass: null);

      final json = classInfo.toJson();

      expect(json.containsKey('superClass'), isTrue);
      expect(json['superClass'], isNull);
    });

    test('toJson handles empty collections', () {
      const classInfo = DartClassInfo('Simple', [], interfaces: [], mixins: []);

      final json = classInfo.toJson();

      expect(json['interfaces'], isEmpty);
      expect(json['mixins'], isEmpty);
    });
  });

  group('DartClassInfo - Markdown Output', () {
    test('markdown includes superclass', () {
      const classInfo = DartClassInfo('User', [], superClass: 'Person');

      final md = classInfo.toMarkdown();

      expect(md, contains('User'));
      expect(md, contains('Extends: Person'));
    });

    test('markdown includes interfaces', () {
      const classInfo = DartClassInfo(
        'Dog',
        [],
        interfaces: ['Animal', 'Comparable'],
      );

      final md = classInfo.toMarkdown();

      expect(md, contains('Implements: Animal, Comparable'));
    });

    test('markdown includes modifiers', () {
      const classInfo = DartClassInfo('Logger', [], isAbstract: true);

      final md = classInfo.toMarkdown();

      expect(md, contains('abstract'));
    });

    test('markdown with complex hierarchy', () {
      const classInfo = DartClassInfo(
        'AdvancedLogger',
        [DartFieldInfo('level', 'int')],
        superClass: 'Logger',
        interfaces: ['Loggable'],
        mixins: ['TimestampMixin'],
        isAbstract: true,
      );

      final md = classInfo.toMarkdown();

      expect(md, contains('AdvancedLogger'));
      expect(md, contains('abstract'));
      expect(md, contains('Extends: Logger'));
      expect(md, contains('Implements: Loggable'));
      expect(md, contains('With: TimestampMixin'));
    });
  });

  group('DartClassInfo - Comparable/Sorting', () {
    test('classes sortable by name', () {
      final classes = [
        const DartClassInfo('Zebra', []),
        const DartClassInfo('Apple', []),
        const DartClassInfo('Monkey', []),
      ];

      final sorted = classes..sort();

      expect(sorted.map((c) => c.className), ['Apple', 'Monkey', 'Zebra']);
    });

    test('equal objects have consistent comparison', () {
      const class1 = DartClassInfo('User', []);
      const class2 = DartClassInfo('User', []);

      expect(class1.compareTo(class2), 0);
      expect(class1 == class2, isTrue);
    });

    test('Comparable matches equality semantics', () {
      const user = DartClassInfo('User', []);
      const admin = DartClassInfo('Admin', []);

      expect(admin.compareTo(user) < 0, isTrue);
      expect(admin == user, isFalse);
    });
  });

  group('DartClassInfo - Equality & Hash', () {
    test('identical classes are equal', () {
      const class1 = DartClassInfo('User', [
        DartFieldInfo('id', 'int'),
      ], superClass: 'Person');

      const class2 = DartClassInfo('User', [
        DartFieldInfo('id', 'int'),
      ], superClass: 'Person');

      expect(class1, equals(class2));
      expect(class1.hashCode, equals(class2.hashCode));
    });

    test('different superclasses make classes unequal', () {
      const class1 = DartClassInfo('User', [], superClass: 'Person');

      const class2 = DartClassInfo('User', [], superClass: 'Entity');

      expect(class1, isNot(equals(class2)));
    });

    test('different interfaces make classes unequal', () {
      const class1 = DartClassInfo('Dog', [], interfaces: ['Animal']);

      const class2 = DartClassInfo('Dog', [], interfaces: ['Pet']);

      expect(class1, isNot(equals(class2)));
    });
  });
}

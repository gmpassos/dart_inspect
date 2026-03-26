import 'package:dart_inspect/dart_inspect.dart';
import 'package:test/test.dart';

void main() {
  group('Class hierarchy extraction', () {
    const simpleInheritance = '''
class Animal {}
class Dog extends Animal {}
''';

    const multipleInterfaces = '''
class Drawable {}
class Comparable {}
class Shape implements Drawable, Comparable {}
''';

    const withMixins = '''
mixin Logger {}
mixin Timestamp {}
class Service with Logger, Timestamp {}
''';

    const complexHierarchy = '''
abstract class Entity {}
class User extends Entity implements Comparable, Serializable with Timestamp {}
''';

    DartInspect makeInspect() => DartInspect(const DartInspectOptions());

    Future<List<DartClassInfo>> extractClasses(String code) async {
      final inspect = makeInspect();
      return (await inspect.scanCode(code, filePath: 'test.dart').toList())
          .whereType<DartClassInfo>()
          .toList();
    }

    test('detects simple inheritance', () async {
      final results = await extractClasses(simpleInheritance);
      final dog = results.firstWhere((c) => c.className == 'Dog');
      expect(dog.superClass, 'Animal');
      expect(dog.interfaces, isEmpty);
      expect(dog.mixins, isEmpty);
    });

    test('detects root class has no superclass', () async {
      final results = await extractClasses(simpleInheritance);
      final animal = results.firstWhere((c) => c.className == 'Animal');
      expect(animal.superClass, isNull);
    });

    test('detects multiple interfaces', () async {
      final results = await extractClasses(multipleInterfaces);
      final shape = results.firstWhere((c) => c.className == 'Shape');
      expect(shape.interfaces, containsAll(['Drawable', 'Comparable']));
    });

    test('detects mixins', () async {
      final results = await extractClasses(withMixins);
      final service = results.firstWhere((c) => c.className == 'Service');
      expect(service.mixins, containsAll(['Logger', 'Timestamp']));
    });

    test('detects complex hierarchy', () async {
      final results = await extractClasses(complexHierarchy);
      final user = results.firstWhere((c) => c.className == 'User');
      expect(user.superClass, 'Entity');
      expect(user.interfaces, containsAll(['Comparable', 'Serializable']));
      expect(user.mixins, contains('Timestamp'));
    });

    test('detects abstract modifier', () async {
      final results = await extractClasses(complexHierarchy);
      final entity = results.firstWhere((c) => c.className == 'Entity');
      expect(entity.isAbstract, isTrue);
    });
  });
}

// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:cli_completion/src/installer/script_configuration_entry.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$ScriptConfigurationEntry', () {
    test('can be instatiated', () {
      expect(() => ScriptConfigurationEntry('name'), returnsNormally);
    });

    test('has a name', () {
      expect(ScriptConfigurationEntry('name').name, 'name');
    });

    group('appendsTo', () {
      test('returns normally when file exist', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name');

        expect(
          () => entry.appendTo(file),
          returnsNormally,
        );
      });

      test('returns normally when file does not exist', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath);

        final entry = ScriptConfigurationEntry('name');

        expect(
          () => entry.appendTo(file),
          returnsNormally,
        );
      });

      test('correctly appends content', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();
        const initialContent = 'hello world\n';
        file.writeAsStringSync(initialContent);

        final entry = ScriptConfigurationEntry('name');
        const entryContent = 'hello world';

        entry.appendTo(file, content: entryContent);

        final fileContent = file.readAsStringSync();
        const expectedContent = '''
$initialContent
## [name]
$entryContent
## [/name]

''';
        expect(fileContent, equals(expectedContent));
      });
    });

    group('existsIn', () {
      group('returns false', () {
        test('when when file does not exist', () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final filePath = path.join(tempDirectory.path, 'file');
          final file = File(filePath);

          final entry = ScriptConfigurationEntry('name');

          expect(entry.existsIn(file), isFalse);
        });

        test('when file exists without entry', () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final filePath = path.join(tempDirectory.path, 'file');
          final file = File(filePath)..createSync();

          final entry = ScriptConfigurationEntry('name');

          expect(entry.existsIn(file), isFalse);
        });

        test('when file exists with another entry', () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final filePath = path.join(tempDirectory.path, 'file');
          final file = File(filePath)..createSync();
          ScriptConfigurationEntry('other').appendTo(file);

          final entry = ScriptConfigurationEntry('name');
          expect(entry.existsIn(file), isFalse);
        });
      });

      test('returns true when file exists with an entry', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name')..appendTo(file);

        expect(entry.existsIn(file), isTrue);
      });
    });

    group('removeFrom', () {
      test('returns normally when file does not exist', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath);

        final entry = ScriptConfigurationEntry('name');

        expect(() => entry.removeFrom(file), returnsNormally);
      });

      test('does not change the file when file is empty', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        ScriptConfigurationEntry('name').removeFrom(file);

        final content = file.readAsStringSync();
        expect(content, isEmpty);
      });

      test('does not change the file when another entry exists in file', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        ScriptConfigurationEntry('name').appendTo(file);
        final content = file.readAsStringSync();

        ScriptConfigurationEntry('anotherName').removeFrom(file);

        final newContent = file.readAsStringSync();
        expect(content, equals(newContent));
      });

      test('removes entry from file when there is a single matching entry', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name')..appendTo(file);
        expect(entry.existsIn(file), isTrue);

        ScriptConfigurationEntry('name').removeFrom(file);
        final content = file.readAsStringSync();
        expect(content, isEmpty);
      });

      test(
          '''removes all entries from file when there is a multiple matching entries''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name')
          ..appendTo(file)
          ..appendTo(file)
          ..appendTo(file);
        expect(entry.existsIn(file), isTrue);

        ScriptConfigurationEntry('name').removeFrom(file);
        final content = file.readAsStringSync();
        expect(content, isEmpty);
      });

      test('only removes matching entries from file', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name')..appendTo(file);
        expect(entry.existsIn(file), isTrue);

        final anotherEntry = ScriptConfigurationEntry('anotherName')
          ..appendTo(file);
        expect(anotherEntry.existsIn(file), isTrue);

        ScriptConfigurationEntry('name').removeFrom(file);
        final content = file.readAsStringSync();
        expect(content, isEmpty);
      });
    });
  });
}

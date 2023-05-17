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

    group('appendTo', () {
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

        const entryContent = 'hello world';
        ScriptConfigurationEntry('name').appendTo(file, content: entryContent);

        final fileContent = file.readAsStringSync();
        const expectedContent = '''
$initialContent
## [name]
$entryContent
## [/name]

''';
        expect(fileContent, equals(expectedContent));
      });

      test('correctly appends content when null', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();
        const initialContent = 'hello world\n';
        file.writeAsStringSync(initialContent);

        ScriptConfigurationEntry('name').appendTo(file);

        final fileContent = file.readAsStringSync();
        const expectedContent = '''
$initialContent
## [name]
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

      test('deletes file when file is empty and should delete', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        ScriptConfigurationEntry('name').removeFrom(file, shouldDelete: true);

        expect(file.existsSync(), isFalse);
      });

      test('does not change the file when another entry exists in file', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        ScriptConfigurationEntry('name').appendTo(file);
        final content = file.readAsStringSync();

        ScriptConfigurationEntry('anotherName').removeFrom(file);

        final currentContent = file.readAsStringSync();
        expect(content, equals(currentContent));
      });

      test(
          '''removes file when there is only a single matching entry and should delete''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name')..appendTo(file);
        expect(entry.existsIn(file), isTrue);

        ScriptConfigurationEntry('name').removeFrom(file, shouldDelete: true);
        expect(file.existsSync(), isFalse);
      });

      test(
          '''preseves file when there is a single matching entry and should not delete''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name')..appendTo(file);
        expect(entry.existsIn(file), isTrue);

        ScriptConfigurationEntry('name').removeFrom(file);
        expect(file.existsSync(), isTrue);
        final currentContent = file.readAsStringSync();
        expect(currentContent, isEmpty);
      });

      test(
          '''removes file when there are only multiple matching entries and should delete''',
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

        ScriptConfigurationEntry('name').removeFrom(file, shouldDelete: true);
        expect(file.existsSync(), isFalse);
      });

      test('only removes matching entries from file', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final filePath = path.join(tempDirectory.path, 'file');
        final file = File(filePath)..createSync();

        final entry = ScriptConfigurationEntry('name')..appendTo(file);
        expect(entry.existsIn(file), isTrue);
        final newContent = file.readAsStringSync();

        final anotherEntry = ScriptConfigurationEntry('anotherName')
          ..appendTo(file);
        expect(anotherEntry.existsIn(file), isTrue);

        ScriptConfigurationEntry('anotherName').removeFrom(file);
        final actualContent = file.readAsStringSync();
        expect(actualContent, equals(newContent));
      });
    });
  });
}

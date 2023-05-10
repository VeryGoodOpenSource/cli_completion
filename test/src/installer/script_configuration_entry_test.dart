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
## [/name]\n
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
  });
}

// ignore_for_file: prefer_const_constructors

import 'dart:collection';
import 'dart:io';

import 'package:cli_completion/installer.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$CompletionConfiguration', () {
    final testUninstalls = UnmodifiableMapView({
      SystemShell.bash: UnmodifiableSetView({'very_bad'}),
    });

    group('fromFile', () {
      test(
        'returns empty cache when file does not exist',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final file = File(path.join(tempDirectory.path, 'config.json'));
          expect(
            file.existsSync(),
            isFalse,
            reason: 'File should not exist',
          );

          final cache = CompletionConfiguration.fromFile(file);
          expect(
            cache.uninstalls,
            isEmpty,
            reason: 'Uninstalls should be initially empty',
          );
        },
      );

      test('returns empty cache when file is empty', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final file = File(path.join(tempDirectory.path, 'config.json'))
          ..writeAsStringSync('');

        final cache = CompletionConfiguration.fromFile(file);
        expect(
          cache.uninstalls,
          isEmpty,
          reason: 'Uninstalls should be initially empty',
        );
      });

      test("returns a $CompletionConfiguration with the file's defined members",
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final file = File(path.join(tempDirectory.path, 'config.json'));
        final cache = CompletionConfiguration.empty().copyWith(
          uninstalls: testUninstalls,
        )..writeTo(file);

        final newCache = CompletionConfiguration.fromFile(file);
        expect(
          newCache.uninstalls,
          cache.uninstalls,
          reason: 'Uninstalls should match those defined in the file',
        );
      });

      test(
        '''returns a $CompletionConfiguration with empty uninstalls if the file's JSON "uninstalls" key has a string value''',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          const json = '{"uninstalls": "very_bad"}';
          final file = File(path.join(tempDirectory.path, 'config.json'))
            ..writeAsStringSync(json);

          final cache = CompletionConfiguration.fromFile(file);
          expect(
            cache.uninstalls,
            isEmpty,
            reason:
                '''Uninstalls should be empty when the value is of an invalid type''',
          );
        },
      );

      test(
        '''returns a $CompletionConfiguration with empty uninstalls if file's JSON "uninstalls" key has a numeric value''',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          const json = '{"uninstalls": 1}';
          final file = File(path.join(tempDirectory.path, 'config.json'))
            ..writeAsStringSync(json);

          final cache = CompletionConfiguration.fromFile(file);
          expect(
            cache.uninstalls,
            isEmpty,
            reason:
                '''Uninstalls should be empty when the value is of an invalid type''',
          );
        },
      );
    });

    group('writeTo', () {
      test('creates a file when it does not exist', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final file = File(path.join(tempDirectory.path, 'config.json'));
        expect(
          file.existsSync(),
          isFalse,
          reason: 'File should not exist',
        );

        CompletionConfiguration.empty().writeTo(file);

        expect(
          file.existsSync(),
          isTrue,
          reason: 'File should exist after cache creation',
        );
      });

      test('returns normally when file already exists', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final file = File(path.join(tempDirectory.path, 'config.json'))
          ..createSync();
        expect(
          file.existsSync(),
          isTrue,
          reason: 'File should exist',
        );

        expect(
          () => CompletionConfiguration.empty().writeTo(file),
          returnsNormally,
          reason: 'Should not throw when file exists',
        );
      });

      test('content can be read succesfully after written', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final file = File(path.join(tempDirectory.path, 'config.json'));
        final cache = CompletionConfiguration.empty().copyWith(
          uninstalls: testUninstalls,
        )..writeTo(file);

        final newCache = CompletionConfiguration.fromFile(file);
        expect(
          newCache.uninstalls,
          cache.uninstalls,
          reason: 'Uninstalls should match those defined in the file',
        );
      });
    });

    group('copyWith', () {
      test('members remain unchanged when nothing is specified', () {
        final cache = CompletionConfiguration.empty();
        final newCache = cache.copyWith();

        expect(
          newCache.uninstalls,
          cache.uninstalls,
          reason: 'Uninstalls should remain unchanged',
        );
      });

      test('modifies uninstalls when specified', () {
        final cache = CompletionConfiguration.empty();
        final uninstalls = testUninstalls;
        final newCache = cache.copyWith(uninstalls: uninstalls);

        expect(
          newCache.uninstalls,
          equals(uninstalls),
          reason: 'Uninstalls should be modified',
        );
      });
    });
  });

  group('UninstallsExtension', () {
    group('include', () {
      test('adds command to $Uninstalls when not already in', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({});

        final newUninstalls =
            uninstalls.include(command: testCommand, systemShell: testShell);

        expect(
          newUninstalls.contains(command: testCommand, systemShell: testShell),
          isTrue,
        );
      });

      test('does nothing when $Uninstalls already has command', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({
          testShell: UnmodifiableSetView({testCommand}),
        });

        final newUninstalls =
            uninstalls.include(command: testCommand, systemShell: testShell);

        expect(
          newUninstalls.contains(command: testCommand, systemShell: testShell),
          isTrue,
        );
      });

      test('adds command $Uninstalls when on a different shell', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        final newUninstalls = uninstalls.include(
          command: testCommand,
          systemShell: anotherShell,
        );
        expect(testShell, isNot(equals(anotherShell)));

        expect(
          newUninstalls.contains(command: testCommand, systemShell: testShell),
          isTrue,
        );
        expect(
          newUninstalls.contains(
            command: testCommand,
            systemShell: anotherShell,
          ),
          isTrue,
        );
      });
    });

    group('exclude', () {
      test('removes command when in $Uninstalls', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({
          testShell: UnmodifiableSetView({testCommand}),
        });

        final newUninstalls =
            uninstalls.exclude(command: testCommand, systemShell: testShell);

        expect(
          newUninstalls.contains(command: testCommand, systemShell: testShell),
          isFalse,
        );
      });

      test('does nothing when command not in $Uninstalls', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({});

        final newUninstalls =
            uninstalls.exclude(command: testCommand, systemShell: testShell);

        expect(
          newUninstalls.contains(command: testCommand, systemShell: testShell),
          isFalse,
        );
      });

      test('does nothing when command in $Uninstalls is on a different shell',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        final newUninstalls =
            uninstalls.exclude(command: testCommand, systemShell: anotherShell);

        expect(
          newUninstalls.contains(command: testCommand, systemShell: testShell),
          isTrue,
        );
      });
    });

    group('contains', () {
      test('returns true when command is in $Uninstalls for the given shell',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({
          testShell: UnmodifiableSetView({testCommand}),
        });

        expect(
          uninstalls.contains(command: testCommand, systemShell: testShell),
          isTrue,
        );
      });

      test('returns false when command is in $Uninstalls for another shell',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final uninstalls = Uninstalls({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        expect(testShell, isNot(equals(anotherShell)));

        expect(
          uninstalls.contains(command: testCommand, systemShell: anotherShell),
          isFalse,
        );
      });
    });
  });
}

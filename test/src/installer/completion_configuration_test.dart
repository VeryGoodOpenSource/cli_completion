// ignore_for_file: prefer_const_constructors

import 'dart:collection';
import 'dart:io';

import 'package:cli_completion/installer.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('$CompletionConfiguration', () {
    final testInstalls = ShellCommandsMap({
      SystemShell.bash: UnmodifiableSetView({'very_good'}),
    });
    final testUninstalls = ShellCommandsMap({
      SystemShell.bash: UnmodifiableSetView({'very_bad'}),
    });

    group('fromFile', () {
      test(
        'returns empty $CompletionConfiguration when file does not exist',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final file = File(path.join(tempDirectory.path, 'config.json'));
          expect(
            file.existsSync(),
            isFalse,
            reason: 'File should not exist',
          );

          final completionConfiguration =
              CompletionConfiguration.fromFile(file);
          expect(
            completionConfiguration.uninstalls,
            isEmpty,
            reason: 'Uninstalls should be initially empty',
          );
        },
      );

      test('returns empty $CompletionConfiguration when file is empty', () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final file = File(path.join(tempDirectory.path, 'config.json'))
          ..writeAsStringSync('');

        final completionConfiguration = CompletionConfiguration.fromFile(file);
        expect(
          completionConfiguration.uninstalls,
          isEmpty,
          reason: 'Uninstalls should be initially empty',
        );
      });

      test("returns a $CompletionConfiguration with the file's defined members",
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final file = File(path.join(tempDirectory.path, 'config.json'));
        final completionConfiguration =
            CompletionConfiguration.empty().copyWith(
          installs: testInstalls,
          uninstalls: testUninstalls,
        )..writeTo(file);

        final newConfiguration = CompletionConfiguration.fromFile(file);
        expect(
          newConfiguration.installs,
          equals(completionConfiguration.installs),
          reason: 'Installs should match those defined in the file',
        );
        expect(
          newConfiguration.uninstalls,
          equals(completionConfiguration.uninstalls),
          reason: 'Uninstalls should match those defined in the file',
        );
      });

      test(
        '''returns a $CompletionConfiguration with empty uninstalls if the file's JSON uninstalls key has a string value''',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          const json =
              '{"${CompletionConfiguration.uninstallsJsonKey}": "very_bad"}';
          final file = File(path.join(tempDirectory.path, 'config.json'))
            ..writeAsStringSync(json);

          final completionConfiguration =
              CompletionConfiguration.fromFile(file);
          expect(
            completionConfiguration.uninstalls,
            isEmpty,
            reason:
                '''Uninstalls should be empty when the value is of an invalid type''',
          );
        },
      );

      test(
        '''returns a $CompletionConfiguration with empty installs if the file's JSON installs key has a string value''',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          const json =
              '{"${CompletionConfiguration.installsJsonKey}": "very_bad"}';
          final file = File(path.join(tempDirectory.path, 'config.json'))
            ..writeAsStringSync(json);

          final completionConfiguration =
              CompletionConfiguration.fromFile(file);
          expect(
            completionConfiguration.installs,
            isEmpty,
            reason:
                '''Installs should be empty when the value is of an invalid type''',
          );
        },
      );

      test(
        '''returns a $CompletionConfiguration with empty uninstalls if file's JSON uninstalls key has a numeric value''',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          const json = '{"${CompletionConfiguration.uninstallsJsonKey}": 1}';
          final file = File(path.join(tempDirectory.path, 'config.json'))
            ..writeAsStringSync(json);

          final completionConfiguration =
              CompletionConfiguration.fromFile(file);
          expect(
            completionConfiguration.uninstalls,
            isEmpty,
            reason:
                '''Uninstalls should be empty when the value is of an invalid type''',
          );
        },
      );

      test(
        '''returns a $CompletionConfiguration with empty installs if file's JSON installs key has a numeric value''',
        () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          const json = '{"${CompletionConfiguration.installsJsonKey}": 1}';
          final file = File(path.join(tempDirectory.path, 'config.json'))
            ..writeAsStringSync(json);

          final completionConfiguration =
              CompletionConfiguration.fromFile(file);
          expect(
            completionConfiguration.installs,
            isEmpty,
            reason:
                '''Installs should be empty when the value is of an invalid type''',
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
          reason: 'File should exist after completionConfiguration creation',
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
        final completionConfiguration =
            CompletionConfiguration.empty().copyWith(
          installs: testInstalls,
          uninstalls: testUninstalls,
        )..writeTo(file);

        final newcompletionConfiguration =
            CompletionConfiguration.fromFile(file);
        expect(
          newcompletionConfiguration.installs,
          completionConfiguration.installs,
          reason: 'Installs should match those defined in the file',
        );
        expect(
          newcompletionConfiguration.uninstalls,
          completionConfiguration.uninstalls,
          reason: 'Uninstalls should match those defined in the file',
        );
      });
    });

    group('copyWith', () {
      test('members remain unchanged when nothing is specified', () {
        final completionConfiguration = CompletionConfiguration.empty();
        final newcompletionConfiguration = completionConfiguration.copyWith();

        expect(
          newcompletionConfiguration.uninstalls,
          completionConfiguration.uninstalls,
          reason: 'Uninstalls should remain unchanged',
        );
      });

      test('modifies uninstalls when specified', () {
        final completionConfiguration = CompletionConfiguration.empty();
        final uninstalls = testUninstalls;
        final newcompletionConfiguration =
            completionConfiguration.copyWith(uninstalls: uninstalls);

        expect(
          newcompletionConfiguration.uninstalls,
          equals(uninstalls),
          reason: 'Uninstalls should be modified',
        );
      });

      test('modifies installs when specified', () {
        final completionConfiguration = CompletionConfiguration.empty();
        final installs = testUninstalls;
        final newcompletionConfiguration =
            completionConfiguration.copyWith(installs: installs);

        expect(
          newcompletionConfiguration.uninstalls,
          equals(installs),
          reason: 'Installs should be modified',
        );
      });
    });
  });

  group('ShellCommandsMapExtension', () {
    group('include', () {
      test('adds command to $ShellCommandsMap when not already in', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({});

        final newShellCommadsMap = shellCommandsMap.include(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });

      test('does nothing when $ShellCommandsMap already has command', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        final newShellCommadsMap = shellCommandsMap.include(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });

      test('adds command $ShellCommandsMap when on a different shell', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        final newShellCommadsMap = shellCommandsMap.include(
          command: testCommand,
          systemShell: anotherShell,
        );
        expect(testShell, isNot(equals(anotherShell)));

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: anotherShell,
          ),
          isTrue,
        );
      });
    });

    group('exclude', () {
      test('removes command when in $ShellCommandsMap', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        final newShellCommandsMap = shellCommandsMap.exclude(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommandsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isFalse,
        );
      });

      test('does nothing when command not in $ShellCommandsMap', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({});

        final newShellCommandsMap = shellCommandsMap.exclude(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommandsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isFalse,
        );
      });

      test(
          '''does nothing when command in $ShellCommandsMap is on a different shell''',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        final newShellCommadsMap = shellCommandsMap.exclude(
          command: testCommand,
          systemShell: anotherShell,
        );

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });
    });

    group('contains', () {
      test(
          '''returns true when command is in $ShellCommandsMap for the given shell''',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        expect(
          shellCommandsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });

      test(
          '''returns false when command is in $ShellCommandsMap for another shell''',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        expect(testShell, isNot(equals(anotherShell)));

        expect(
          shellCommandsMap.contains(
            command: testCommand,
            systemShell: anotherShell,
          ),
          isFalse,
        );
      });
    });
  });

  group('ShellCommandsMapExtension', () {
    group('include', () {
      test('adds command to $ShellCommandsMap when not already in', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({});

        final newShellCommadsMap = shellCommandsMap.include(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });

      test('does nothing when $ShellCommandsMap already has command', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        final newShellCommadsMap = shellCommandsMap.include(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });

      test('adds command $ShellCommandsMap when on a different shell', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        final newShellCommadsMap = shellCommandsMap.include(
          command: testCommand,
          systemShell: anotherShell,
        );
        expect(testShell, isNot(equals(anotherShell)));

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: anotherShell,
          ),
          isTrue,
        );
      });
    });

    group('exclude', () {
      test('removes command when in $ShellCommandsMap', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        final newShellCommandsMap = shellCommandsMap.exclude(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommandsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isFalse,
        );
      });

      test('does nothing when command not in $ShellCommandsMap', () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({});

        final newShellCommandsMap = shellCommandsMap.exclude(
          command: testCommand,
          systemShell: testShell,
        );

        expect(
          newShellCommandsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isFalse,
        );
      });

      test(
          '''does nothing when command in $ShellCommandsMap is on a different shell''',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        final newShellCommadsMap = shellCommandsMap.exclude(
          command: testCommand,
          systemShell: anotherShell,
        );

        expect(
          newShellCommadsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });
    });

    group('contains', () {
      test(
          '''returns true when command is in $ShellCommandsMap for the given shell''',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        expect(
          shellCommandsMap.contains(
            command: testCommand,
            systemShell: testShell,
          ),
          isTrue,
        );
      });

      test(
          '''returns false when command is in $ShellCommandsMap for another shell''',
          () {
        const testCommand = 'test_command';
        const testShell = SystemShell.bash;
        final shellCommandsMap = ShellCommandsMap({
          testShell: UnmodifiableSetView({testCommand}),
        });

        const anotherShell = SystemShell.zsh;
        expect(testShell, isNot(equals(anotherShell)));

        expect(
          shellCommandsMap.contains(
            command: testCommand,
            systemShell: anotherShell,
          ),
          isFalse,
        );
      });
    });
  });
}

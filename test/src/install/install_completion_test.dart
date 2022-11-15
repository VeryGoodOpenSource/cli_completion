import 'dart:io';

import 'package:cli_completion/install.dart';
import 'package:cli_completion/src/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  late Logger logger;
  late Directory tempDir;

  setUp(() {
    logger = MockLogger();
    tempDir = Directory.systemTemp.createTempSync();
  });

  group('installCompletion', () {
    test('installs for zsh', () {
      File(path.join(tempDir.path, '.zshrc')).createSync();

      installCompletion(
        logger: logger,
        rootCommand: 'very_good',
        isWindowsOverride: false,
        environmentOverride: {
          'SHELL': '/foo/bar/zsh',
          'HOME': tempDir.path,
        },
      );

      verify(
        () => logger.detail(
          'Completion installation for very_good started',
        ),
      );

      verify(
        () => logger.detail(
          'Shell identified as zsh',
        ),
      );

      expect(tempDir.listSync().map((e) => path.basename(e.path)), [
        '.zshrc',
        '.dart-cli-completion',
      ]);
    });

    test('installs for bash', () {
      File(path.join(tempDir.path, '.bash_profile')).createSync();

      installCompletion(
        logger: logger,
        rootCommand: 'very_good',
        isWindowsOverride: false,
        environmentOverride: {
          'SHELL': '/foo/bar/bash',
          'HOME': tempDir.path,
        },
      );

      verify(
        () => logger.detail(
          'Completion installation for very_good started',
        ),
      );

      verify(
        () => logger.detail(
          'Shell identified as bash',
        ),
      );

      expect(tempDir.listSync().map((e) => path.basename(e.path)), [
        '.dart-cli-completion',
        '.bash_profile',
      ]);
    });

    test('do nothing on unknown shells', () {
      expect(
        () {
          installCompletion(
            logger: logger,
            rootCommand: 'very_good',
            isWindowsOverride: false,
            environmentOverride: {
              'SHELL': '/foo/bar/someshell',
              'HOME': tempDir.path,
            },
          );
        },
        throwsA(
          predicate(
            (e) {
              return e is CompletionInstallationException &&
                  e.toString() ==
                      'Could not install completion scripts for very_good: '
                          'Unknown shell.';
            },
          ),
        ),
      );
    });
  });
}

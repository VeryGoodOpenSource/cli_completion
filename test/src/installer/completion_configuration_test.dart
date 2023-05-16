// TODO(alestiago): Use barrel file for imports.
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
        'creates file with empty cache when file does not exist',
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
          expect(
            file.existsSync(),
            isTrue,
            reason: 'File should exist after cache creation',
          );
        },
      );

      test('has empty members when file is empty', () {
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

      test("creates $CompletionConfiguration with the file's defined members",
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
}

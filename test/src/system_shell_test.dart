import 'package:cli_completion/handling.dart';
import 'package:test/test.dart';

void main() {
  group('SystemShell', () {
    group('fromCurrentShell', () {
      test('instantiated without env', () {
        expect(
          SystemShell.current,
          returnsNormally,
        );
      });

      test('identifies zsh', () {
        final result = SystemShell.current(
          environmentOverride: {
            'SHELL': '/foo/bar/zsh',
          },
        );

        expect(result, SystemShell.zsh);
      });

      test('identifies bash shell', () {
        final result = SystemShell.current(
          environmentOverride: {
            'SHELL': '/foo/bar/bash',
          },
        );

        expect(result, SystemShell.bash);

        final resultWindows = SystemShell.current(
          environmentOverride: {
            'SHELL': r'c:\foo\bar\bash.exe',
          },
        );

        expect(resultWindows, SystemShell.bash);
      });

      group('identifies no shell', () {
        test('for no shell env', () {
          final result = SystemShell.current(
            environmentOverride: {},
          );

          expect(result, null);
        });

        test('for empty shell env', () {
          final result = SystemShell.current(
            environmentOverride: {
              'SHELL': '',
            },
          );

          expect(result, null);
        });

        test('for extraneous shell', () {
          final result = SystemShell.current(
            environmentOverride: {
              'SHELL': '/usr/bin/someshell',
            },
          );

          expect(result, null);
        });
      });
    });
  });
}

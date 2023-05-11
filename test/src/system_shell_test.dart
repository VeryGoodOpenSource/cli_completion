import 'package:cli_completion/parser.dart';
import 'package:test/test.dart';

void main() {
  group('SystemShell', () {
    group('name', () {
      test('bash is correct', () {
        expect(SystemShell.bash.name, equals('bash'));
      });

      test('zsh is correct', () {
        expect(SystemShell.zsh.name, equals('zsh'));
      });
    });

    group('current', () {
      test('instantiated without env', () {
        expect(
          SystemShell.current,
          returnsNormally,
        );
      });

      group('Heuristics', () {
        test('identifies zsh', () {
          final result = SystemShell.current(
            environmentOverride: {
              'ZSH_NAME': 'zsh',
            },
          );

          expect(result, SystemShell.zsh);
        });

        test('identifies bash', () {
          final result = SystemShell.current(
            environmentOverride: {
              'BASH': '/bin/bash',
            },
          );

          expect(result, SystemShell.bash);
        });
      });

      group(r'When checking $SHELL', () {
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
  });
}

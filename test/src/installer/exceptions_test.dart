import 'package:cli_completion/installer.dart';
import 'package:test/test.dart';

void main() {
  group('$CompletionUninstallationException', () {
    test('can be instantiated', () {
      expect(
        () => CompletionUninstallationException(
          message: 'message',
          rootCommand: 'executableName',
        ),
        returnsNormally,
      );
    });

    test('has a message', () {
      expect(
        CompletionUninstallationException(
          message: 'message',
          rootCommand: 'executableName',
        ).message,
        equals('message'),
      );
    });

    test('has an executableName', () {
      expect(
        CompletionUninstallationException(
          message: 'message',
          rootCommand: 'executableName',
        ).rootCommand,
        equals('executableName'),
      );
    });

    group('toString', () {
      test('returns a string', () {
        expect(
          CompletionUninstallationException(
            message: 'message',
            rootCommand: 'executableName',
          ).toString(),
          isA<String>(),
        );
      });

      test('returns a correctly formatted string', () {
        expect(
          CompletionUninstallationException(
            message: 'message',
            rootCommand: 'executableName',
          ).toString(),
          equals(
            '''Could not uninstall completion scripts for executableName: message''',
          ),
        );
      });
    });
  });
}

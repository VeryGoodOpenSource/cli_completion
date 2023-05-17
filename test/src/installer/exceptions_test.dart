import 'package:cli_completion/installer.dart';
import 'package:test/test.dart';

void main() {
  group('$CompletionUnistallationException', () {
    test('can be instantiated', () {
      expect(
        () => CompletionUnistallationException(
          message: 'message',
          executableName: 'executableName',
        ),
        returnsNormally,
      );
    });

    test('has a message', () {
      expect(
        CompletionUnistallationException(
          message: 'message',
          executableName: 'executableName',
        ).message,
        equals('message'),
      );
    });

    test('has an executableName', () {
      expect(
        CompletionUnistallationException(
          message: 'message',
          executableName: 'executableName',
        ).executableName,
        equals('executableName'),
      );
    });

    group('toString', () {
      test('returns a string', () {
        expect(
          CompletionUnistallationException(
            message: 'message',
            executableName: 'executableName',
          ).toString(),
          isA<String>(),
        );
      });

      test('returns a correctly formatted string', () {
        expect(
          CompletionUnistallationException(
            message: 'message',
            executableName: 'executableName',
          ).toString(),
          equals(
            '''Could not uninstall completion scripts for executableName: message''',
          ),
        );
      });
    });
  });
}

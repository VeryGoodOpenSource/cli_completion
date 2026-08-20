import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/installer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockCompletionInstallation extends Mock
    implements CompletionInstallation {}

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner() : super('test', 'Test command runner');

  @override
  bool get enableAutoInstall => false;

  @override
  // Override acceptable for test files
  // ignore: overridden_fields
  final Logger completionLogger = _MockLogger();

  @override
  // Override acceptable for test files
  // ignore: overridden_fields
  final Logger completionInstallationLogger = _MockLogger();

  @override
  final CompletionInstallation completionInstallation =
      _MockCompletionInstallation();
}

void main() {
  group('PrintCompletionScriptCommand', () {
    late _TestCompletionCommandRunner commandRunner;

    setUp(() {
      commandRunner = _TestCompletionCommandRunner();
    });

    test('can be instantiated', () {
      expect(PrintCompletionScriptCommand<int>(), isNotNull);
    });

    test('is not hidden', () {
      expect(PrintCompletionScriptCommand<int>().hidden, isFalse);
    });

    test('description', () {
      expect(
        PrintCompletionScriptCommand<int>().description,
        'Prints the completion script for the current shell to stdout.',
      );
    });

    group('completion-script', () {
      test('prints the completion script to stdout', () async {
        when(
          () => commandRunner.completionInstallation.completionScriptFor(
            commandRunner.executableName,
          ),
        ).thenReturn('some completion script');

        await commandRunner.run(['completion-script']);

        verify(
          () => commandRunner.completionLogger.info('some completion script'),
        ).called(1);
      });

      test(
        'logs a warning when it throws a CompletionInstallationException',
        () async {
          when(
            () => commandRunner.completionInstallation.completionScriptFor(
              commandRunner.executableName,
            ),
          ).thenThrow(
            CompletionInstallationException(
              message: 'oops',
              rootCommand: 'test',
            ),
          );

          await commandRunner.run(['completion-script']);

          verify(
            () => commandRunner.completionInstallationLogger.warn(any()),
          ).called(1);
        },
      );

      test(
        'logs an error when an unknown exception happens',
        () async {
          when(
            () => commandRunner.completionInstallation.completionScriptFor(
              commandRunner.executableName,
            ),
          ).thenThrow(Exception('oops'));

          await commandRunner.run(['completion-script']);

          verify(
            () => commandRunner.completionInstallationLogger.err(any()),
          ).called(1);
        },
      );
    });
  });
}

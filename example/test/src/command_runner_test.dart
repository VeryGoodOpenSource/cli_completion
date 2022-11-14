import 'package:args/command_runner.dart';
import 'package:example/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('ExampleCommandRunner', () {
    late Logger logger;
    late ExampleCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();

      commandRunner = ExampleCommandRunner(
        logger: logger,
      );
    });

    test(
      'can be instantiated without an explicit logger instance',
      () {
        final commandRunner = ExampleCommandRunner();
        expect(commandRunner, isNotNull);
      },
    );

    test('handles FormatException', () async {
      const exception = FormatException('oops!');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--rootFlag']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info(commandRunner.usage)).called(1);
    });

    test('handles UsageException', () async {
      final exception = UsageException('oops!', 'exception usage');
      var isFirstInvocation = true;
      when(() => logger.info(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw exception;
        }
      });
      final result = await commandRunner.run(['--rootFlag']);
      expect(result, equals(ExitCode.usage.code));
      verify(() => logger.err(exception.message)).called(1);
      verify(() => logger.info('exception usage')).called(1);
    });

    group('--rootFlag', () {
      test('does nothing', () async {
        final result = await commandRunner.run(['--rootFlag']);
        expect(result, equals(ExitCode.success.code));
        verify(
          () => logger.info('You used the root flag, it does nothing :)'),
        ).called(1);
      });
    });

    group('printUsage', () {
      test('usesLogger', () async {
        commandRunner.printUsage();

        final a = verify(
          () => logger.info(captureAny()),
        ).captured;
        expect(a.first, '''
Example for cli_completion

Usage: example_cli <command> [arguments]

Global options:
-h, --help             Print this usage information.
    --[no-]rootFlag    A flag in the root command

Available commands:
  some_command         This is help for some_command
  some_other_command   This is help for some_other_command

Run "example_cli help <command>" for more information about a command.''');
      });
    });
  });
}

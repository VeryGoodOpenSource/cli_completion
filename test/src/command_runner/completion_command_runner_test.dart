import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/install.dart';
import 'package:cli_completion/src/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockCompletionInstallation extends Mock
    implements CompletionInstallation {}

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner(this.completionInstallationLogger)
      : super('test', 'Test command runner');

  @override
  // ignore: overridden_fields
  final Logger completionInstallationLogger;

  @override
  final CompletionInstallation completionInstallation =
      MockCompletionInstallation();
}

class _TestUserCommand extends Command<int> {
  @override
  String get description => 'some command';

  @override
  String get name => 'ahoy';

  @override
  int run() {
    return 0;
  }
}

void main() {
  group('CompletionCommandRunner', () {
    late Logger logger;
    late _TestCompletionCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();

      commandRunner = _TestCompletionCommandRunner(logger);
    });

    test('can be instantiated', () {
      expect(commandRunner, isNotNull);
    });

    test('Adds default commands', () {
      expect(
        commandRunner.commands.keys,
        containsAll([
          'completion',
          'install-completion-files',
        ]),
      );
    });

    test('Tries to install completion file test subcommand', () async {
      commandRunner.addCommand(_TestUserCommand());

      await commandRunner.run(['ahoy']);

      verify(() => commandRunner.completionInstallation.install('test'))
          .called(1);

      verify(() => logger.level = Level.error).called(1);
    });

    test('When something goes wrong on install, it logs as error', () async {
      commandRunner.addCommand(_TestUserCommand());

      when(
        () => commandRunner.completionInstallation.install('test'),
      ).thenThrow(
        CompletionInstallationException(message: 'oops', rootCommand: 'test'),
      );

      await commandRunner.run(['ahoy']);

      verify(
        () => logger.err('Could not install completion scripts for test: oops'),
      ).called(1);
    });
  });
}

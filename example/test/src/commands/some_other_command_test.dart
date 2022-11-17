import 'package:example/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('SomeOtherCommand', () {
    late Logger logger;
    late ExampleCommandRunner commandRunner;

    setUp(() {
      logger = MockLogger();

      commandRunner = ExampleCommandRunner(
        logger: logger,
      );
    });

    test('list passed options', () async {
      final exitCode = await commandRunner.run(
        'some_other_command subcommand anything after command '.split(' '),
      );

      expect(exitCode, ExitCode.success.code);

      verify(() => logger.info('A sub command of some_other_command'))
          .called(1);
      verify(() => logger.info('  - anything')).called(1);
      verify(() => logger.info('  - after')).called(1);
      verify(() => logger.info('  - command')).called(1);
    });
  });
}

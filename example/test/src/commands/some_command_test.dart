import 'package:example/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('SomeCommand', () {
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
        'some_command '
                '--discrete foo '
                '--continuous something '
                '--multi-d fii --multi-d bar '
                '--multi-c oof --multi-c rab '
                '--flag '
                '--no-inverseflag '
                '--trueflag'
            .split(' '),
      );

      expect(exitCode, ExitCode.success.code);

      verify(() => logger.info('  - discrete: foo')).called(1);
      verify(() => logger.info('  - continuous: something')).called(1);
      verify(() => logger.info('  - multi-d: [fii, bar]')).called(1);
      verify(() => logger.info('  - multi-c: [oof, rab]')).called(1);
      verify(() => logger.info('  - flag: true')).called(1);
      verify(() => logger.info('  - inverseflag: false')).called(1);
      verify(() => logger.info('  - trueflag: true')).called(1);
      verify(() => logger.info('  - help: false')).called(1);
    });
  });
}

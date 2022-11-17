import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner() : super('test', 'Test command runner');

  @override
  // ignore: overridden_fields
  final Logger completionLogger = MockLogger();
}

void main() {
  group('HandleCompletionRequestCommand', () {
    late _TestCompletionCommandRunner commandRunner;

    setUp(() {
      commandRunner = _TestCompletionCommandRunner();
    });

    test('can be instantiated', () {
      expect(HandleCompletionRequestCommand<int>(MockLogger()), isNotNull);
    });

    test('is hidden', () {
      expect(HandleCompletionRequestCommand<int>(MockLogger()).hidden, isTrue);
    });

    test('description', () {
      expect(
        HandleCompletionRequestCommand<int>(MockLogger()).description,
        'Handles shell completion (should never be called manually)',
      );
    });

    group('when run', () {
      test('with no args', () async {
        await commandRunner.run(['completion']);

        verify(() {
          commandRunner.completionLogger.info('USA');
        }).called(1);
        verify(() {
          commandRunner.completionLogger.info('Brazil');
        }).called(1);
        verify(() {
          commandRunner.completionLogger.info('Netherlands');
        }).called(1);
      });
    });
  });
}

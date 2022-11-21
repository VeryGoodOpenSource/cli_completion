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

    group('run', () {
      test('should display completion', () async {
        final output = StringBuffer();
        when(() {
          commandRunner.completionLogger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        commandRunner.environmentOverride = {
          'SHELL': '/foo/bar/zsh',
          'COMP_LINE': 'example_cli some_command --discrete foo',
          'COMP_POINT': '12',
          'COMP_CWORD': '2'
        };
        await commandRunner.run(['completion']);

        expect(output.toString(), r'''
Brazil:A country
USA:Another country
Netherlands:Guess what\: a country
Portugal:Yep, a country
''');
      });

      test('should supress error messages', () async {
        final output = StringBuffer();
        when(() {
          commandRunner.completionLogger.info(any());
        }).thenThrow(Exception('oh no'));

        commandRunner.environmentOverride = {
          'SHELL': '/foo/bar/zsh',
          'COMP_LINE': 'example_cli some_command --discrete foo',
          'COMP_POINT': '12',
          'COMP_CWORD': '2'
        };
        await commandRunner.run(['completion']);

        expect(output.toString(), '');
      });
    });
  });
}

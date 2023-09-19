import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner() : super('test', 'Test command runner') {
    final subCommand = _TestCommand(
      name: 'subcommand',
      description: 'level 1',
    );
    addCommand(subCommand);
    final subSubCommand = _TestCommand(
      name: 'subsubcommand2',
      description: 'level 2',
    );
    subCommand.addSubcommand(subSubCommand);
  }

  @override
  String get executableName => 'test_cli';

  @override
  // ignore: overridden_fields
  final Logger completionLogger = MockLogger();
}

class _TestCommand extends Command<int> {
  _TestCommand({
    required this.name,
    required this.description,
  });

  @override
  final String description;

  @override
  final String name;
}

void main() {
  group('HandleCompletionRequestCommand', () {
    late _TestCompletionCommandRunner commandRunner;

    setUp(() {
      commandRunner = _TestCompletionCommandRunner();
    });

    test('can be instantiated', () {
      expect(HandleCompletionRequestCommand<int>(), isNotNull);
    });

    test('is hidden', () {
      expect(HandleCompletionRequestCommand<int>().hidden, isTrue);
    });

    test('description', () {
      expect(
        HandleCompletionRequestCommand<int>().description,
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

        const line = 'test_cli ';
        commandRunner.environmentOverride = {
          'SHELL': '/foo/bar/zsh',
          'COMP_LINE': line,
          'COMP_POINT': '${line.length}',
          'COMP_CWORD': '2',
        };
        await commandRunner.run(['completion']);

        expect(output.toString(), '''
subcommand:level 1
--help:Print this usage information.
''');
      });

      test('should suppress error messages', () async {
        final output = StringBuffer();
        when(() {
          commandRunner.completionLogger.info(any());
        }).thenThrow(Exception('oh no'));

        const line = 'test_cli ';
        commandRunner.environmentOverride = {
          'SHELL': '/foo/bar/zsh',
          'COMP_LINE': line,
          'COMP_POINT': '${line.length}',
          'COMP_CWORD': '2',
        };
        await commandRunner.run(['completion']);

        expect(output.toString(), '');
      });
    });
  });
}

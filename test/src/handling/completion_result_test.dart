import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/completion_level.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class _TestCompletionResult extends CompletionResult {
  const _TestCompletionResult(this._completions);

  final Map<String, String?> _completions;

  @override
  Iterable<MapEntry<String, String?>> get completions => _completions.entries;
}

class _TestCommand extends Command<void> {
  _TestCommand({
    required this.name,
    required this.description,
    required this.aliases,
  });

  @override
  final String description;

  @override
  final String name;

  @override
  final List<String> aliases;
}

void main() {
  group('CompletionResult', () {
    group('render', () {
      test('renders predefined suggestions on zsh', () {
        const completionResult = _TestCompletionResult({
          'suggestion1': 'description1',
          'suggestion2': 'description2',
          'suggestion3': null,
          'suggestion4': 'description4',
        });

        final logger = MockLogger();

        final output = StringBuffer();

        when(() {
          logger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        completionResult.render(logger, SystemShell.zsh);
      });

      test('renders predefined suggestions on bash', () {
        const completionResult = _TestCompletionResult({
          'suggestion1': 'description1',
          'suggestion2': 'description2',
          'suggestion3': null,
          'suggestion4': 'description4',
        });

        final logger = MockLogger();

        final output = StringBuffer();
        when(() {
          logger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        completionResult.render(logger, SystemShell.bash);

        expect(output.toString(), '''
suggestion1
suggestion2
suggestion3
suggestion4
''');
      });
    });
  });

  group('EmptyCompletionResult', () {
    test('renders nothing', () {
      const completionResult = EmptyCompletionResult();

      final logger = MockLogger();

      final output = StringBuffer();
      when(() {
        logger.info(any());
      }).thenAnswer((invocation) {
        output.writeln(invocation.positionalArguments.first);
      });

      completionResult.render(logger, SystemShell.zsh);

      expect(output.toString(), '');

      completionResult.render(logger, SystemShell.bash);

      expect(output.toString(), '');
    });
  });

  group('AllOptionsAndCommandsCompletionResult', () {
    test(
      'renders suggestions for all sub commands and options in'
      ' a completion level',
      () {
        final testArgParser = ArgParser()
          ..addOption('option1')
          ..addFlag('option2', help: 'yay option 2');

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: [],
          visibleSubcommands: [
            _TestCommand(
              name: 'command1',
              description: 'yay command 1',
              aliases: [],
            ),
            _TestCommand(
              name: 'command2',
              description: 'yay command 2',
              aliases: ['alias'],
            ),
          ],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = AllOptionsAndCommandsCompletionResult(
          completionLevel: completionLevel,
        );

        final logger = MockLogger();

        final output = StringBuffer();

        when(() {
          logger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        completionResult.render(logger, SystemShell.zsh);
        expect(output.toString(), '''
command1:yay command 1
command2:yay command 2
--option1
--option2:yay option 2
''');

        output.clear();

        completionResult.render(logger, SystemShell.bash);
        expect(output.toString(), '''
command1
command2
--option1
--option2
''');
      },
    );
  });

  group('MatchingCommandsCompletionResult', () {
    test(
      'renders suggestions only for sub commands that starts with pattern',
      () {
        final testArgParser = ArgParser()..addOption('option');

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: [],
          visibleSubcommands: [
            _TestCommand(
              name: 'command1',
              description: 'yay command 1',
              aliases: [],
            ),
            _TestCommand(
              name: 'command2',
              description: 'yay command 2',
              aliases: ['alias'],
            ),
            _TestCommand(
              name: 'weird_command',
              description: 'yay weird command',
              aliases: ['command_not_weird'],
            ),
          ],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = MatchingCommandsCompletionResult(
          completionLevel: completionLevel,
          pattern: 'co',
        );

        final logger = MockLogger();

        final output = StringBuffer();

        when(() {
          logger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        completionResult.render(logger, SystemShell.zsh);
        expect(output.toString(), '''
command1:yay command 1
command2:yay command 2
command_not_weird:yay weird command
''');

        output.clear();

        completionResult.render(logger, SystemShell.bash);
        expect(output.toString(), '''
command1
command2
command_not_weird
''');
      },
    );
  });
}

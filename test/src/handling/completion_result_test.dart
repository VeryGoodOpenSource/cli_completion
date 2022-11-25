import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/completion_level.dart';
import 'package:test/test.dart';

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
          rawArgs: const <String>[],
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

        expect(
          completionResult.completions,
          {
            'command1': 'yay command 1',
            'command2': 'yay command 2',
            '--option1': null,
            '--option2': 'yay option 2',
          },
        );
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
          rawArgs: const <String>[],
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

        expect(
          completionResult.completions,
          {
            'command1': 'yay command 1',
            'command2': 'yay command 2',
            'command_not_weird': 'yay weird command'
          },
        );
      },
    );
  });
}

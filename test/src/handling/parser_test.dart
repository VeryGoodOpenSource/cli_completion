import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/completion_level.dart';
import 'package:cli_completion/src/handling/parser.dart';
import 'package:test/test.dart';

class _TestCommand extends Command<void> {
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
  group('CompletionParser', () {
    final visibleSubcommands = [
      _TestCommand(
        name: 'command1',
        description: 'yay command 1',
      ),
      _TestCommand(
        name: 'command2',
        description: 'yay command 2',
      ),
    ];

    final testArgParser = ArgParser()..addOption('option1');

    test('can be instantiated', () {
      expect(
        () => CompletionParser(
          completionLevel: CompletionLevel(
            grammar: ArgParser(),
            rawArgs: const [],
            visibleOptions: const [],
            visibleSubcommands: const [],
          ),
        ),
        returnsNormally,
      );
    });

    group('parse', () {
      group('when there is zero non empty args', () {
        test('returns all options', () {
          final parser = CompletionParser(
            completionLevel: CompletionLevel(
              grammar: testArgParser,
              rawArgs: '  '.split(' '),
              visibleSubcommands: visibleSubcommands,
              visibleOptions: testArgParser.options.values.toList(),
            ),
          );

          final result = parser.parse();

          expect(result.length, 1);
          expect(
            result.first,
            isA<AllOptionsAndCommandsCompletionResult>(),
          );
        });
      });

      group('when user writes something, presses space before completion', () {
        test('returns all  all options', () {
          final parser = CompletionParser(
            completionLevel: CompletionLevel(
              grammar: testArgParser,
              rawArgs: const ['', 'command1', 'rest', ''],
              visibleSubcommands: visibleSubcommands,
              visibleOptions: testArgParser.options.values.toList(),
            ),
          );

          final result = parser.parse();
          expect(result.length, 1);
          expect(
            result.first,
            isA<AllOptionsAndCommandsCompletionResult>(),
          );
        });
      });

      group('when the user started to type a sub command', () {
        test('returns all matching command and options', () {
          final parser = CompletionParser(
            completionLevel: CompletionLevel(
              grammar: testArgParser,
              rawArgs: const ['', 'command'],
              visibleSubcommands: visibleSubcommands,
              visibleOptions: testArgParser.options.values.toList(),
            ),
          );

          final result = parser.parse();

          expect(result.length, 1);
          expect(
            result.first,
            isA<MatchingCommandsCompletionResult>().having(
              (res) => res.pattern,
              'commands start with',
              'command',
            ),
          );
        });
      });
    });
  });
}

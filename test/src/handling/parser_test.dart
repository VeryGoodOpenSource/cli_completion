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

CompletionState stateForLine(
  String line, {
  int? cursorIndex,
}) {
  final cpoint = cursorIndex ?? line.length;
  var cword = 0;
  line.split(' ').fold(0, (value, element) {
    final total = value + 1 + element.length;
    if (total < cpoint) {
      cword++;
      return total;
    }
    return value;
  });
  final environment = <String, String>{
    'COMP_LINE': line,
    'COMP_POINT': '$cpoint',
    'COMP_CWORD': '$cword',
  };
  return CompletionState.fromEnvironment(environment)!;
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
      final state = stateForLine('foo command1 --p');

      expect(
        () => CompletionParser(
          state: state,
          runnerGrammar: ArgParser(),
          runnerCommands: {},
        )..findCompletionLevel = (_, __, ___) => null,
        returnsNormally,
      );
    });

    group('parse', () {
      group('when there is an argument terminator', () {
        test('returns nothing', () {
          final state = stateForLine('foo command1 -- command2');
          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => null;
          final result = parser.parse();

          expect(result, <CompletionResult>[]);
        });
      });

      group('when completion level cannot be found', () {
        test('returns nothing', () {
          final state = stateForLine('foo unknown subcommand');

          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => null;
          final result = parser.parse();

          expect(result, <CompletionResult>[]);
        });
      });

      group('when completion level cannot be found', () {
        test('returns nothing', () {
          final state = stateForLine('foo unknown subcommand');

          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => null;
          final result = parser.parse();

          expect(result, <CompletionResult>[]);
        });
      });

      group('when calling parse', () {
        test('calls find with he correct params', () {
          final state = stateForLine('foo subcommand');

          final argParser = ArgParser();

          final commands = <String, Command<dynamic>>{};

          Iterable<String>? rootArgs;
          ArgParser? runnerGrammar;
          Map<String, Command<dynamic>>? runnerCommands;

          CompletionParser(
            state: state,
            runnerGrammar: argParser,
            runnerCommands: commands,
          )
            ..findCompletionLevel = (args, grammar, commands) {
              rootArgs = args;
              runnerGrammar = grammar;
              runnerCommands = commands;
              return null;
            }
            ..parse();

          expect(rootArgs, state.args);
          expect(runnerGrammar, same(argParser));
          expect(runnerCommands, same(commands));
        });
      });

      group('when completion level cannot be found', () {
        test('returns nothing', () {
          final state = stateForLine('foo subcommand');

          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => null;
          final result = parser.parse();

          expect(result, <CompletionResult>[]);
        });
      });

      group('when the cursor is not at the end of the line', () {
        test('returns nothing', () {
          const rawArgs = ['', ''];
          final state = stateForLine('foo  ', cursorIndex: 4);

          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: rawArgs,
            visibleSubcommands: visibleSubcommands,
            visibleOptions: testArgParser.options.values.toList(),
          );
          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => completionLevel;

          final result = parser.parse();

          expect(result, <CompletionResult>[]);
        });
      });

      group('when there is zero non empty args', () {
        test('returns all options', () {
          const rawArgs = ['', ''];
          final state = stateForLine('foo   ');

          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: rawArgs,
            visibleSubcommands: visibleSubcommands,
            visibleOptions: testArgParser.options.values.toList(),
          );
          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => completionLevel;

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
          const rawArgs = ['', 'command1', 'rest', ''];
          final state = stateForLine('foo command1 rest ');

          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: rawArgs,
            visibleSubcommands: visibleSubcommands,
            visibleOptions: testArgParser.options.values.toList(),
          );
          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => completionLevel;

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
          const rawArgs = ['', 'command'];
          final state = stateForLine('foo command');

          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: rawArgs,
            visibleSubcommands: visibleSubcommands,
            visibleOptions: testArgParser.options.values.toList(),
          );
          final parser = CompletionParser(
            state: state,
            runnerGrammar: ArgParser(),
            runnerCommands: {},
          )..findCompletionLevel = (_, __, ___) => completionLevel;

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

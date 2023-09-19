import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/parser.dart';
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
          ..addFlag('option2', help: 'yay option 2')
          ..addFlag(
            'trueflag',
            negatable: false,
          );

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
            '--no-option2': 'yay option 2',
            '--trueflag': null,
          },
        );
      },
    );
  });

  group('AllAbbrOptionsCompletionResult', () {
    test(
      'render suggestions for all abbreviated options ins a completion level',
      () {
        final testArgParser = ArgParser()
          ..addOption('option1')
          ..addOption('option2', abbr: 'a')
          ..addFlag('flag1')
          ..addFlag('flag2', abbr: 'b', help: 'yay flag1 2');

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const [],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = AllAbbrOptionsCompletionResult(
          completionLevel: completionLevel,
        );

        expect(
          completionResult.completions,
          {'-a': null, '-b': 'yay flag1 2'},
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
              aliases: ['command2alias'],
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
            'command_not_weird': 'yay weird command',
          },
        );
      },
    );
  });

  group('MatchingOptionsCompletionResult', () {
    test(
      'renders suggestions only for options that starts with pattern',
      () {
        final testArgParser = ArgParser()
          ..addOption('option1')
          ..addOption(
            'noption2',
            aliases: ['option2alias'],
            help: 'yay noption2',
          )
          ..addFlag('oflag1');

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = MatchingOptionsCompletionResult(
          completionLevel: completionLevel,
          pattern: 'o',
        );

        expect(
          completionResult.completions,
          {
            '--option1': null,
            '--option2alias': 'yay noption2',
            '--oflag1': null,
          },
        );
      },
    );

    test(
      'renders suggestions only for negated flags',
      () {
        final testArgParser = ArgParser()
          ..addOption('option1')
          ..addOption(
            'noption2',
            aliases: ['option2alias'],
            help: 'yay noption2',
          )
          ..addFlag('flag', aliases: ['aliasforflag'])
          ..addFlag('trueflag', negatable: false);

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = MatchingOptionsCompletionResult(
          completionLevel: completionLevel,
          pattern: 'no',
        );

        expect(
          completionResult.completions,
          {
            '--noption2': 'yay noption2',
            '--no-flag': null,
          },
        );

        final completionResultAlias = MatchingOptionsCompletionResult(
          completionLevel: completionLevel,
          pattern: 'no-a',
        );

        expect(
          completionResultAlias.completions,
          {
            '--no-aliasforflag': null,
          },
        );
      },
    );
  });

  group('OptionValuesCompletionResult', () {
    final testArgParser = ArgParser()
      ..addOption('continuous', abbr: 'c')
      ..addOption(
        'allowed',
        abbr: 'a',
        allowed: [
          'value',
          'valuesomething',
          'anothervalue',
        ],
        allowedHelp: {
          'valueyay': 'yay valueyay',
          'valuesomething': 'yay valuesomething',
        },
      );

    group('OptionValuesCompletionResult.new', () {
      test('render suggestions for all option values', () {
        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult(
          completionLevel: completionLevel,
          optionName: 'allowed',
        );

        expect(completionResult.completions, {
          'value': null,
          'valuesomething': 'yay valuesomething',
          'anothervalue': null,
        });
      });
      test(
        'renders suggestions for option values that starts with pattern',
        () {
          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: const <String>[],
            visibleSubcommands: const [],
            visibleOptions: testArgParser.options.values.toList(),
          );

          final completionResult = OptionValuesCompletionResult(
            completionLevel: completionLevel,
            optionName: 'allowed',
            pattern: 'va',
          );

          expect(completionResult.completions, {
            'value': null,
            'valuesomething': 'yay valuesomething',
          });
        },
      );
      test('renders no suggestions when there is no allowed values', () {
        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult(
          completionLevel: completionLevel,
          optionName: 'continuous',
        );

        expect(completionResult.completions, isEmpty);
      });
    });
    group('OptionValuesCompletionResult.abbr', () {
      test('render suggestions for all option values', () {
        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult.abbr(
          completionLevel: completionLevel,
          abbrName: 'a',
        );

        expect(completionResult.completions, {
          'value': null,
          'valuesomething': 'yay valuesomething',
          'anothervalue': null,
        });
      });
      test(
        'renders suggestions for option values that starts with pattern',
        () {
          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: const <String>[],
            visibleSubcommands: const [],
            visibleOptions: testArgParser.options.values.toList(),
          );

          final completionResult = OptionValuesCompletionResult.abbr(
            completionLevel: completionLevel,
            abbrName: 'a',
            pattern: 'va',
          );

          expect(completionResult.completions, {
            'value': null,
            'valuesomething': 'yay valuesomething',
          });
        },
      );

      test('renders no suggestions when there is no allowed values', () {
        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult.abbr(
          completionLevel: completionLevel,
          abbrName: 'o',
        );

        expect(completionResult.completions, isEmpty);
      });

      test('render suggestions for all option values with name', () {
        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult.abbr(
          completionLevel: completionLevel,
          abbrName: 'a',
          includeAbbrName: true,
        );

        expect(completionResult.completions, {
          '-avalue': null,
          '-avaluesomething': 'yay valuesomething',
          '-aanothervalue': null,
        });
      });
    });
  });
}

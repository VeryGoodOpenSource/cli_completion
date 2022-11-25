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

  group('AllAbbrOptionsCompletionResult', () {
    test(
      'render suggestions for all abbreviated options ins a completion level',
      () {
        final testArgParser = ArgParser()
          ..addOption('option1')
          ..addOption('option2', abbr: 'a')
          ..addFlag('flag1')
          ..addFlag('flag2', abbr: 'b', help: 'yay flag1 2')
          ..addFlag('flag3', abbr: 'c');

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
          {
            '-a': null,
            '-b': 'yay flag1 2',
            '-c': null,
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

  group('MatchingOptionsCompletionResult', () {
    test(
      'renders suggestions only for options that starts with pattern',
      () {
        final testArgParser = ArgParser()
          ..addOption('option1')
          ..addOption(
            'noption2',
            aliases: [
              'option2alias',
            ],
            help: 'yay noption2',
          )
          ..addFlag('oflag1')
          ..addFlag('flag2', help: 'yay flag2');

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
  });

  group('OptionValuesCompletionResult', () {
    group('OptionValuesCompletionResult.new', () {
      test('render suggestions for all option values', () {
        final testArgParser = ArgParser()
          ..addOption(
            'option',
            allowed: [
              'value1',
              'value2',
              'value3',
            ],
            allowedHelp: {
              'value1': 'yay value1',
              'value3': 'yay value3',
            },
          );

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult(
          completionLevel: completionLevel,
          optionName: 'option',
        );

        expect(
          completionResult.completions,
          {
            'value1': 'yay value1',
            'value2': null,
            'value3': 'yay value3',
          },
        );
      });
      test(
        'renders suggestions for option values that starts with pattern',
        () {
          final testArgParser = ArgParser()
            ..addOption(
              'option',
              allowed: [
                'value',
                'valueyay',
                'valuesomething',
                'somevalue',
                'anothervalue',
              ],
              allowedHelp: {
                'valueyay': 'yay valueyay',
                'valuesomething': 'yay valuesomething',
              },
            );

          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: const <String>[],
            visibleSubcommands: const [],
            visibleOptions: testArgParser.options.values.toList(),
          );

          final completionResult = OptionValuesCompletionResult(
            completionLevel: completionLevel,
            optionName: 'option',
            pattern: 'va',
          );

          expect(
            completionResult.completions,
            {
              'value': null,
              'valueyay': 'yay valueyay',
              'valuesomething': 'yay valuesomething',
            },
          );
        },
      );
      test('renders no suggestions when there is no allowed values', () {
        final testArgParser = ArgParser()..addOption('option');

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult(
          completionLevel: completionLevel,
          optionName: 'option',
        );

        expect(completionResult.completions, isEmpty);
      });
    });
    group('OptionValuesCompletionResult.abbr', () {
      test('render suggestions for all option values', () {
        final testArgParser = ArgParser()
          ..addOption(
            'option',
            abbr: 'o',
            allowed: [
              'value1',
              'value2',
              'value3',
            ],
            allowedHelp: {
              'value1': 'yay value1',
              'value3': 'yay value3',
            },
          );

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

        expect(
          completionResult.completions,
          {
            'value1': 'yay value1',
            'value2': null,
            'value3': 'yay value3',
          },
        );
      });
      test(
        'renders suggestions for option values that starts with pattern',
        () {
          final testArgParser = ArgParser()
            ..addOption(
              'option',
              abbr: 'o',
              allowed: [
                'value',
                'valueyay',
                'valuesomething',
                'somevalue',
                'anothervalue',
              ],
              allowedHelp: {
                'valueyay': 'yay valueyay',
                'valuesomething': 'yay valuesomething',
              },
            );

          final completionLevel = CompletionLevel(
            grammar: testArgParser,
            rawArgs: const <String>[],
            visibleSubcommands: const [],
            visibleOptions: testArgParser.options.values.toList(),
          );

          final completionResult = OptionValuesCompletionResult.abbr(
            completionLevel: completionLevel,
            abbrName: 'o',
            pattern: 'va',
          );

          expect(
            completionResult.completions,
            {
              'value': null,
              'valueyay': 'yay valueyay',
              'valuesomething': 'yay valuesomething',
            },
          );
        },
      );
      test('renders no suggestions when there is no allowed values', () {
        final testArgParser = ArgParser()..addOption('option', abbr: 'o');

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
        final testArgParser = ArgParser()
          ..addOption(
            'option',
            abbr: 'o',
            allowed: [
              'value1',
              'value2',
              'value3',
            ],
            allowedHelp: {
              'value1': 'yay value1',
              'value3': 'yay value3',
            },
          );

        final completionLevel = CompletionLevel(
          grammar: testArgParser,
          rawArgs: const <String>[],
          visibleSubcommands: const [],
          visibleOptions: testArgParser.options.values.toList(),
        );

        final completionResult = OptionValuesCompletionResult.abbr(
          completionLevel: completionLevel,
          abbrName: 'o',
          includeAbbrName: true,
        );

        expect(
          completionResult.completions,
          {
            '-ovalue1': 'yay value1',
            '-ovalue2': null,
            '-ovalue3': 'yay value3',
          },
        );
      });
    });
  });
}

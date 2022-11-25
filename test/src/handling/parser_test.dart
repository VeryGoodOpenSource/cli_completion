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

      final testArgParser = ArgParser()
        ..addOption('option')
        ..addOption(
          'optionWithAllowed',
          abbr: 'a',
          allowed: [
            'allowed1',
            'anotherAllowed',
          ],
        )
        ..addFlag('flag');

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

      group('when there is a space before the cursor', () {
        group('and last given arg is an option', () {
          group('an option without allowed values', () {
            test('returns OptionValuesCompletionResult', () {
              final parser = CompletionParser(
                completionLevel: CompletionLevel(
                  grammar: testArgParser,
                  rawArgs: const ['', 'command1', '--option', ''],
                  visibleSubcommands: visibleSubcommands,
                  visibleOptions: testArgParser.options.values.toList(),
                ),
              );

              final result = parser.parse();
              expect(result.length, 1);
              expect(
                result.first,
                isA<OptionValuesCompletionResult>()
                    .having(
                      (result) => result.optionName,
                      'option name',
                      'option',
                    )
                    .having(
                      (result) => result.pattern,
                      'pattern',
                      null,
                    )
                    .having(
                      (result) => result.isAbbr,
                      'is abbr',
                      false,
                    ),
              );
            });
          });

          group('an option with allowed values', () {
            test('returns option values', () {
              final parser = CompletionParser(
                completionLevel: CompletionLevel(
                  grammar: testArgParser,
                  rawArgs: const ['', 'command1', '--optionWithAllowed', ''],
                  visibleSubcommands: visibleSubcommands,
                  visibleOptions: testArgParser.options.values.toList(),
                ),
              );

              final result = parser.parse();
              expect(result.length, 1);
              expect(
                result.first,
                isA<OptionValuesCompletionResult>()
                    .having(
                      (result) => result.optionName,
                      'option name',
                      'optionWithAllowed',
                    )
                    .having(
                      (result) => result.pattern,
                      'pattern',
                      null,
                    )
                    .having(
                      (result) => result.isAbbr,
                      'is abbr',
                      false,
                    ),
              );
            });
          });

          group('an option with allowed values (abbr)', () {
            test('returns option values', () {
              final parser = CompletionParser(
                completionLevel: CompletionLevel(
                  grammar: testArgParser,
                  rawArgs: const ['', 'command1', '-a', ''],
                  visibleSubcommands: visibleSubcommands,
                  visibleOptions: testArgParser.options.values.toList(),
                ),
              );

              final result = parser.parse();
              expect(result.length, 1);
              expect(
                result.first,
                isA<OptionValuesCompletionResult>()
                    .having(
                      (result) => result.optionName,
                      'option name',
                      'a',
                    )
                    .having(
                      (result) => result.pattern,
                      'pattern',
                      null,
                    )
                    .having(
                      (result) => result.isAbbr,
                      'is abbr',
                      true,
                    )
                    .having(
                      (result) => result.includeAbbrName,
                      'include abbr name',
                      false,
                    ),
              );
            });
          });

          group('a flag', () {
            test('returns all options', () {
              final parser = CompletionParser(
                completionLevel: CompletionLevel(
                  grammar: testArgParser,
                  rawArgs: const ['', 'command1', '--flag', ''],
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
        });

        test('returns all options', () {
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

      group(
          'when the user started to type something after writing '
          'an option', () {
        group('an option without allowed values', () {
          test('returns OptionValuesCompletionResults', () {
            final parser = CompletionParser(
              completionLevel: CompletionLevel(
                grammar: testArgParser,
                rawArgs: const ['', 'command1', '--option', 'something'],
                visibleSubcommands: visibleSubcommands,
                visibleOptions: testArgParser.options.values.toList(),
              ),
            );

            final result = parser.parse();
            expect(result.length, 1);
            expect(
              result.first,
              isA<OptionValuesCompletionResult>()
                  .having(
                    (result) => result.optionName,
                    'option name',
                    'option',
                  )
                  .having(
                    (result) => result.pattern,
                    'pattern',
                    'something',
                  )
                  .having(
                    (result) => result.isAbbr,
                    'is abbr',
                    false,
                  ),
            );
          });
        });

        group('an option with allowed values', () {
          test('returns OptionValuesCompletionResults', () {
            final parser = CompletionParser(
              completionLevel: CompletionLevel(
                grammar: testArgParser,
                rawArgs: const [
                  '',
                  'command1',
                  '--optionWithAllowed',
                  'something',
                ],
                visibleSubcommands: visibleSubcommands,
                visibleOptions: testArgParser.options.values.toList(),
              ),
            );

            final result = parser.parse();
            expect(result.length, 1);
            expect(
              result.first,
              isA<OptionValuesCompletionResult>()
                  .having(
                    (result) => result.optionName,
                    'option name',
                    'optionWithAllowed',
                  )
                  .having(
                    (result) => result.pattern,
                    'pattern',
                    'something',
                  )
                  .having(
                    (result) => result.isAbbr,
                    'is abbr',
                    false,
                  ),
            );
          });
        });

        group('an option with allowed values (abbr)', () {
          test('returns OptionValuesCompletionResults', () {
            final parser = CompletionParser(
              completionLevel: CompletionLevel(
                grammar: testArgParser,
                rawArgs: const [
                  '',
                  'command1',
                  '-a',
                  'something',
                ],
                visibleSubcommands: visibleSubcommands,
                visibleOptions: testArgParser.options.values.toList(),
              ),
            );

            final result = parser.parse();
            expect(result.length, 1);
            expect(
              result.first,
              isA<OptionValuesCompletionResult>()
                  .having(
                    (result) => result.optionName,
                    'option name',
                    'a',
                  )
                  .having(
                    (result) => result.pattern,
                    'pattern',
                    'something',
                  )
                  .having(
                    (result) => result.isAbbr,
                    'is abbr',
                    true,
                  )
                  .having(
                    (result) => result.includeAbbrName,
                    'include abbr name',
                    false,
                  ),
            );
          });
        });

        group('a flag', () {
          test('returns all options', () {
            final parser = CompletionParser(
              completionLevel: CompletionLevel(
                grammar: testArgParser,
                rawArgs: const ['', 'command1', '--flag', ''],
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
      });

      group('when the user started to type a sub command', () {
        test('returns all matching command', () {
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
              'commands pattern',
              'command',
            ),
          );
        });
      });

      group('when the user started to type an option', () {
        test('returns all matching options', () {
          final parser = CompletionParser(
            completionLevel: CompletionLevel(
              grammar: testArgParser,
              rawArgs: const ['', '--option'],
              visibleSubcommands: visibleSubcommands,
              visibleOptions: testArgParser.options.values.toList(),
            ),
          );

          final result = parser.parse();

          expect(result.length, 2);
          expect(
            result.first,
            isA<MatchingCommandsCompletionResult>().having(
              (res) => res.pattern,
              'commands pattern',
              '--option',
            ),
          );
          expect(
            result.last,
            isA<MatchingOptionsCompletionResult>().having(
              (res) => res.pattern,
              'option pattern',
              'option',
            ),
          );
        });
      });

      group('when the user just typed a dash', () {
        test('returns all matching abbreviated options', () {
          final parser = CompletionParser(
            completionLevel: CompletionLevel(
              grammar: testArgParser,
              rawArgs: const ['', '-'],
              visibleSubcommands: visibleSubcommands,
              visibleOptions: testArgParser.options.values.toList(),
            ),
          );

          final result = parser.parse();

          expect(result.length, 2);
          expect(
            result.first,
            isA<MatchingCommandsCompletionResult>().having(
              (res) => res.pattern,
              'commands pattern',
              '-',
            ),
          );
          expect(
            result.last,
            isA<AllAbbrOptionsCompletionResult>(),
          );
        });
      });

      group('when the user typed an abbreviated option with value', () {
        test('returns OptionValuesCompletionResults', () {
          final parser = CompletionParser(
            completionLevel: CompletionLevel(
              grammar: testArgParser,
              rawArgs: const ['', '-asomething'],
              visibleSubcommands: visibleSubcommands,
              visibleOptions: testArgParser.options.values.toList(),
            ),
          );

          final result = parser.parse();

          expect(result.length, 2);
          expect(
            result.first,
            isA<MatchingCommandsCompletionResult>().having(
              (res) => res.pattern,
              'commands pattern',
              '-asomething',
            ),
          );
          expect(
            result.last,
            isA<OptionValuesCompletionResult>()
                .having(
                  (result) => result.optionName,
                  'option name',
                  'a',
                )
                .having(
                  (result) => result.pattern,
                  'pattern',
                  'something',
                )
                .having(
                  (result) => result.isAbbr,
                  'is abbr',
                  true,
                )
                .having(
                  (result) => result.includeAbbrName,
                  'include abbr name',
                  true,
                ),
          );
        });
      });
    });
  });
}

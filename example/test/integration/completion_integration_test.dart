@Tags(['integration'])
import 'package:test/test.dart';

import 'utils.dart';

/// The goal for the tests in this file is to guarantee the general working of
/// the completion suggestions given a shell request
void main() {
  final noSuggestions = <String, String?>{};

  group('root level', () {
    group('empty', () {
      final allRootOptionsAndSubcommands = <String, String?>{
        'some_command': 'This is help for some_command',
        'some_other_command': 'This is help for some_other_command',
        '--help': 'Print this usage information.',
        '--rootFlag': r'A flag\: in the root command',
        '--rootOption': null,
      };

      test('basic usage', () async {
        await expectLater(
          'example_cli',
          suggests(allRootOptionsAndSubcommands),
        );
      });

      test('basic usage', () async {
        await expectLater(
          'example_cli',
          suggests(allRootOptionsAndSubcommands),
        );
      });

      test('leading whitespaces', () async {
        await expectLater(
          '   example_cli',
          suggests(allRootOptionsAndSubcommands),
        );
      });

      test('trailing whitespaces', () async {
        await expectLater(
          'example_cli   ',
          suggests(allRootOptionsAndSubcommands),
        );
      });
    });

    group('options', () {
      group('partially written option', () {
        test('just double dash', () async {
          await expectLater(
            'example_cli --',
            suggests({
              '--help': 'Print this usage information.',
              '--rootFlag': r'A flag\: in the root command',
              '--rootOption': null,
            }),
          );
        });

        test('partially written name', () async {
          await expectLater(
            'example_cli --r',
            suggests({
              '--rootFlag': r'A flag\: in the root command',
              '--rootOption': null,
            }),
          );
        });

        test('partially written name with preceding option', () async {
          await expectLater(
            'example_cli -h --r',
            suggests({
              '--rootFlag': r'A flag\: in the root command',
              '--rootOption': null,
            }),
          );
        });

        test('partially written name with preceding dash', () async {
          await expectLater(
            'example_cli - --r',
            suggests({
              '--rootFlag': r'A flag\: in the root command',
              '--rootOption': null,
            }),
          );
        });
      });

      group('partially written option (abbr)', () {
        test('just dash', () async {
          await expectLater(
            'example_cli -',
            suggests({
              '-h': 'Print this usage information.',
              '-f': r'A flag\: in the root command',
            }),
          );
        });
      });

      test('totally written option', () async {
        await expectLater(
          'example_cli --rootflag',
          suggests(noSuggestions),
        );
      });

      test('totally written option (abbr)', () async {
        await expectLater(
          'example_cli -f',
          suggests(noSuggestions),
        );
      });
    });

    group('sub commands', () {
      group('partially written commands', () {
        test('completes subcommands that starts with typed intro', () async {
          await expectLater(
            'example_cli some',
            suggests({
              'some_command': 'This is help for some_command',
              'some_other_command': 'This is help for some_other_command',
            }),
          );
        });

        test('completes subcommands even with given options', () async {
          await expectLater(
            'example_cli -f some',
            suggests({
              'some_command': 'This is help for some_command',
              'some_other_command': 'This is help for some_other_command',
            }),
          );
        });

        test('completes only one sub command', () async {
          await expectLater(
            'example_cli   some_comm',
            suggests({
              'some_command': 'This is help for some_command',
            }),
          );
        });
      });

      group('partially written commands (aliases)', () {
        test('completes sub commands aliases when typed', () async {
          await expectLater(
            'example_cli mel',
            suggests({
              'melon': 'This is help for some_command',
            }),
          );
        });

        test('completes sub commands aliases when typed 2', () async {
          await expectLater(
            'example_cli disguised',
            suggests({
              r'disguised\:some_commmand': 'This is help for some_command',
            }),
          );
        });
      });
    });
  });

  group('some_command', () {
    final allOptionsInThisLevel = <String, String?>{
      '--help': 'Print this usage information.',
      '--discrete': 'A discrete option with "allowed" values (mandatory)',
      '--continuous': r'A continuous option\: any value is allowed',
      '--multi-d': 'An discrete option that can be passed multiple times ',
      '--multi-c': 'An continuous option that can be passed multiple times',
      '--flag': null,
      '--inverseflag': 'A flag that the default value is true',
      '--trueflag': 'A flag that cannot be negated'
    };

    final allAbbreviationssInThisLevel = <String, String?>{
      '-h': 'Print this usage information.',
      '-d': 'A discrete option with "allowed" values (mandatory)',
      '-m': 'An discrete option that can be passed multiple times ',
      '-n': 'An continuous option that can be passed multiple times',
      '-f': null,
      '-i': 'A flag that the default value is true',
      '-t': 'A flag that cannot be negated'
    };

    group('empty ', () {
      test('basic usage', () async {
        await expectLater(
          'example_cli some_command',
          suggests(allOptionsInThisLevel),
        );
      });

      test('leading spaces', () async {
        await expectLater(
          '   example_cli some_command',
          suggests(allOptionsInThisLevel),
        );
      });

      test('trailing spaces', () async {
        await expectLater(
          'example_cli some_command     ',
          suggests(allOptionsInThisLevel),
        );
      });

      test('flags in between', () async {
        await expectLater(
          'example_cli -f some_command',
          suggests(allOptionsInThisLevel),
        );
      });

      test(
        'options in between',
        () async {
          await expectLater(
            'example_cli -f --rootOption yay some_command',
            suggests(allOptionsInThisLevel),
          );
        },
        tags: 'known-issues',
      );

      test('lots of spaces in between', () async {
        await expectLater(
          'example_cli      some_command',
          suggests(allOptionsInThisLevel),
        );
      });
    });

    group('empty (aliases)', () {
      test('shows same options for alias sub command', () async {
        await expectLater(
          'example_cli melon',
          suggests(allOptionsInThisLevel),
        );
      });

      test('shows same options for alias sub command 2', () async {
        await expectLater(
          'example_cli disguised:some_commmand',
          suggests(allOptionsInThisLevel),
        );
      });
    });

    group('partially written options', () {
      test('just double dash', () async {
        await expectLater(
          'example_cli some_command --',
          suggests(allOptionsInThisLevel),
        );
      });

      test('just double dash with lots of spaces in between', () async {
        await expectLater(
          'example_cli    some_command      --',
          suggests(allOptionsInThisLevel),
        );
      });

      test('suggests multiple matching options', () async {
        await expectLater(
          'example_cli some_command --m',
          suggests({
            '--multi-d':
                'An discrete option that can be passed multiple times ',
            '--multi-c':
                'An continuous option that can be passed multiple times',
          }),
        );
      });

      test('suggests only one matching option', () async {
        await expectLater(
          'example_cli some_command --d',
          suggests({
            '--discrete': 'A discrete option with "allowed" values (mandatory)',
          }),
        );
      });
    });

    group('partially written options (aliases)', () {
      test('completes option aliases when typed', () async {
        await expectLater(
          'example_cli some_command --all',
          suggests({
            '--allowed': 'A discrete option with "allowed" values (mandatory)',
          }),
        );
      });

      test('completes option aliases when typed 2', () async {
        await expectLater(
          'example_cli some_command --defi',
          suggests({
            '--defined-values':
                'A discrete option with "allowed" values (mandatory)',
          }),
        );
      });
    });

    group('partially written options (abbr)', () {
      test('just dash', () async {
        await expectLater(
          'example_cli some_command -',
          suggests(allAbbreviationssInThisLevel),
        );
      });
    });

    group('partially written options (invalid)', () {
      test('do not complete hidden options', () async {
        await expectLater(
          'example_cli some_command --hidd',
          suggests(noSuggestions),
        );
      });

      test('do not complete ubnknown options', () async {
        await expectLater(
          'example_cli some_command --invalid',
          suggests(noSuggestions),
        );
      });
    });

    group('options values', () {
      group('discrete', () {
        test('suggest possible options', () async {
          await expectLater(
            'example_cli some_command --discrete  ',
            suggests({
              'foo': 'foo help',
              'bar': 'bar help',
              'faa': 'faa help',
            }),
          );
        });

        test('suggest matching options', () async {
          await expectLater(
            'example_cli some_command  --discrete  f',
            suggests({
              'foo': 'foo help',
              'faa': 'faa help',
            }),
          );
        });

        test(
            '**do not** suggest possible options when using equals/quote syntax',
            () async {
          await expectLater(
            'example_cli some_command --discrete="',
            suggests(noSuggestions),
          );
        });
      });

      group('discrete (aliases)', () {
        test('suggest matching options for alias option when typed', () async {
          await expectLater(
            'example_cli some_command --allowed ',
            suggests({
              'foo': 'foo help',
              'bar': 'bar help',
              'faa': 'faa help',
            }),
          );
        });

        test('suggest matching options for alias option when typed 2',
            () async {
          await expectLater(
            'example_cli some_command --defined-values ',
            suggests({
              'foo': 'foo help',
              'bar': 'bar help',
              'faa': 'faa help',
            }),
          );
        });
      });

      group('continuous', () {
        test('suggest nothing when previous option is continuous', () async {
          await expectLater(
            'example_cli some_command --continuous  ',
            suggests(noSuggestions),
          );
        });

        test(
          'suggest all options when previous option is continuous with a value',
          () async {
            await expectLater(
              'example_cli some_command --continuous="yeahoo" ',
              suggests(allOptionsInThisLevel),
            );
          },
        );

        test(
          'suggest all options when previous option is continuous with a value',
          () async {
            await expectLater(
              'example_cli some_command --continuous yeahoo ',
              suggests(allOptionsInThisLevel),
            );
          },
        );
      });

      group('flags', () {
        test('suggest all options when a flag was declared', () async {
          await expectLater(
            'example_cli some_command --flag  ',
            suggests(allOptionsInThisLevel),
          );
        });

        test('suggest all options when a negated flag was declared', () async {
          await expectLater(
            'example_cli some_command --no-flag  ',
            suggests(allOptionsInThisLevel),
          );
        });
      });
    });

    group('options values (abbr)', () {
      group('discrete', () {
        test('suggest possible options', () async {
          await expectLater(
            'example_cli some_command -d ',
            suggests({
              'foo': 'foo help',
              'bar': 'bar help',
              'faa': 'faa help',
            }),
          );
        });

        test('suggest possible options in a joined form', () async {
          await expectLater(
            'example_cli some_command -d',
            suggests({
              '-dfoo': 'foo help',
              '-dbar': 'bar help',
              '-dfaa': 'faa help',
            }),
          );
        });

        test('suggest matching options', () async {
          await expectLater(
            'example_cli some_command  -d f',
            suggests({
              'foo': 'foo help',
              'faa': 'faa help',
            }),
          );
        });

        test('suggest matching options in a joined form', () async {
          await expectLater(
            'example_cli some_command  -df',
            suggests({
              '-dfoo': 'foo help',
              '-dfaa': 'faa help',
            }),
          );
        });
      });

      group('continuous', () {
        test('suggest nothing when previous option is continuous', () async {
          await expectLater(
            'example_cli some_command -n ',
            suggests(noSuggestions),
          );
        });

        test('suggest nothing when continuous option is joined', () async {
          await expectLater(
            'example_cli some_command -n',
            suggests(noSuggestions),
          );
        });

        test('suggest nothing when typing its value', () async {
          await expectLater(
            'example_cli some_command -n something',
            suggests(noSuggestions),
          );
        });

        test('suggest nothing when joining abbreviations', () async {
          await expectLater(
            'example_cli some_command -dn',
            suggests(noSuggestions),
          );
        });
      });

      group('flag', () {
        test('suggest all options when a flag was declared', () async {
          await expectLater(
            'example_cli some_command -f  ',
            suggests(allOptionsInThisLevel),
          );
        });
      });
    });

    group('invalid options', () {
      test('just dash with a space after', () async {
        await expectLater(
          'example_cli some_command - ',
          suggests(allOptionsInThisLevel),
        );
      });
    });

    group(
      'repeating options',
      tags: 'known-issues',
      () {
        group('non multi options', () {});

        group('multi options', () {});
      },
    );
  });

  group('some_other_command', () {
    group('empty', () {
      test('basic usage', () async {
        await expectLater(
          'example_cli some_other_command ',
          suggests({
            'subcommand': 'A sub command of some_other_command',
            '--help': 'Print this usage information.',
          }),
        );
      });
    });

    group('partially written sub command', () {
      test('partially written sub command', () async {
        await expectLater(
          'example_cli some_other_command sub',
          suggests({
            'subcommand': 'A sub command of some_other_command',
          }),
        );
      });
    });

    group('subcommand', () {
      final allOptionsInThisLevel = <String, String?>{
        '--help': 'Print this usage information.',
        '--flag': 'a flag just to show we are in the subcommand',
      };
      group('empty', () {
        test('basic usage', () async {
          await expectLater(
            'example_cli some_other_command subcommand',
            suggests(allOptionsInThisLevel),
          );
        });

        test('basic usage with lots of spaces in between', () async {
          await expectLater(
            'example_cli    some_other_command    subcommand',
            suggests(allOptionsInThisLevel),
          );
        });

        test('basic usage with args in between', () async {
          await expectLater(
            'example_cli -f some_other_command subcommand',
            suggests(allOptionsInThisLevel),
          );
        });
      });

      group('empty (aliases)', () {
        test('basic usage with args in between', () async {
          await expectLater(
            'example_cli some_other_command subcommand_alias',
            suggests(allOptionsInThisLevel),
          );
        });
      });
    });
  });

  group('argument terminator bails', () {
    test('between commands', () async {
      await expectLater(
        'example_cli -- some_command',
        suggests(noSuggestions),
      );
    });

    test('after commands', () async {
      await expectLater(
        'example_cli some_command -- ',
        suggests(noSuggestions),
      );
    });

    test('before args', () async {
      await expectLater(
        'example_cli some_command -f --continuous="foo/bar" -- a --something',
        suggests(noSuggestions),
      );
    });
  });
}

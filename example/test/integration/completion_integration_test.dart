@Tags(['integration'])
import 'package:test/test.dart';

import 'utils.dart';

const notImplemmentedYet = 'not implemented yet';

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
      };

      testCompletion(
        'basic usage',
        forLine: 'example_cli',
        suggests: allRootOptionsAndSubcommands,
      );

      testCompletion(
        'leading whitespaces',
        forLine: '   example_cli',
        suggests: allRootOptionsAndSubcommands,
      );

      testCompletion(
        'trailing whitespaces',
        forLine: 'example_cli   ',
        suggests: allRootOptionsAndSubcommands,
      );
    });

    group('options', () {
      group('partially written option', () {
        testCompletion(
          'just double dash',
          forLine: 'example_cli --',
          suggests: {
            '--help': 'Print this usage information.',
            '--rootFlag': r'A flag\: in the root command',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'partially written name',
          forLine: 'example_cli --r',
          suggests: {
            '--rootFlag': r'A flag\: in the root command',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'partially written name with preceding option',
          forLine: 'example_cli -h --r',
          suggests: {
            '--rootFlag': r'A flag\: in the root command',
          },
          skip: notImplemmentedYet,
        );
      });

      group('partially written option (abbr)', () {
        testCompletion(
          'just dash',
          forLine: 'example_cli -',
          suggests: {
            '-h': 'Print this usage information.',
            '-f': r'A flag\: in the root command',
          },
          skip: notImplemmentedYet,
        );
      });

      testCompletion(
        'totally written option',
        forLine: 'example_cli --rootflag',
        suggests: noSuggestions,
        skip: notImplemmentedYet,
      );

      testCompletion(
        'totally written option (abbr)',
        forLine: 'example_cli -f',
        suggests: noSuggestions,
        skip: notImplemmentedYet,
      );
    });

    group('sub commands', () {
      group('partially written commands', () {
        testCompletion(
          'completes subcommands that starts with typed intro',
          forLine: 'example_cli some',
          suggests: {
            'some_command': 'This is help for some_command',
            'some_other_command': 'This is help for some_other_command',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'completes subcommands even with given options',
          forLine: 'example_cli -f some',
          suggests: {
            'some_command': 'This is help for some_command',
            'some_other_command': 'This is help for some_other_command',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'completes only one sub command',
          forLine: 'example_cli   some_comm',
          suggests: {
            'some_command': 'This is help for some_command',
          },
          skip: notImplemmentedYet,
        );
      });

      group('partially written commands (aliases)', () {
        testCompletion(
          'completes sub commands aliases when typed',
          forLine: 'example_cli mel',
          suggests: {
            'melon': 'This is help for some_command',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'completes sub commands aliases when typed 2',
          forLine: 'example_cli disguised',
          suggests: {
            r'disguised\:some_commmand': 'This is help for some_command',
          },
          skip: notImplemmentedYet,
        );
      });

      group(
        'invalid command structure',
        () {
          testCompletion(
            'suggests nothing when there is an unkown command',
            forLine: 'example_cli unknown some',
            suggests: noSuggestions,
            skip: notImplemmentedYet,
          );
        },
      );
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

    group('empty', () {
      testCompletion(
        'basic usage',
        forLine: 'example_cli some_command',
        suggests: allOptionsInThisLevel,
      );

      testCompletion(
        'leading spaces',
        forLine: '   example_cli some_command',
        suggests: allOptionsInThisLevel,
      );

      testCompletion(
        'trailing spaces',
        forLine: 'example_cli some_command     ',
        suggests: allOptionsInThisLevel,
      );

      testCompletion(
        'options in between',
        forLine: 'example_cli -f some_command',
        suggests: allOptionsInThisLevel,
      );

      testCompletion(
        'lots of spaces in between',
        forLine: 'example_cli      some_command',
        suggests: allOptionsInThisLevel,
      );
    });

    group('empty (aliases)', () {
      testCompletion(
        'shows same options for alias sub command',
        forLine: 'example_cli melon',
        suggests: allOptionsInThisLevel,
      );

      testCompletion(
        'shows same options for alias sub command 2',
        forLine: 'example_cli disguised:some_commmand',
        suggests: allOptionsInThisLevel,
      );
    });

    group('partially written options', () {
      testCompletion(
        'just double dash',
        forLine: 'example_cli some_command --',
        suggests: allOptionsInThisLevel,
        skip: notImplemmentedYet,
      );

      testCompletion(
        'just double dash with lots of spaces in between',
        forLine: 'example_cli    some_command      --',
        suggests: allOptionsInThisLevel,
        skip: notImplemmentedYet,
      );

      testCompletion(
        'suggests multiple matching options',
        forLine: 'example_cli some_command --m',
        suggests: {
          '--multi-d': 'An discrete option that can be passed multiple times ',
          '--multi-c': 'An continuous option that can be passed multiple times',
        },
        skip: notImplemmentedYet,
      );

      testCompletion(
        'suggests only one matching option',
        forLine: 'example_cli some_command --d',
        suggests: {
          '--discrete': 'A discrete option with "allowed" values (mandatory)',
        },
        skip: notImplemmentedYet,
      );
    });

    group('partially written options (aliases)', () {
      testCompletion(
        'completes option aliases when typed',
        forLine: 'example_cli some_command --all',
        suggests: {
          '--allowed': 'A discrete option with "allowed" values (mandatory)',
        },
        skip: notImplemmentedYet,
      );

      testCompletion(
        'completes option aliases when typed 2',
        forLine: 'example_cli some_command --defi',
        suggests: {
          '--defined-values':
              'A discrete option with "allowed" values (mandatory)',
        },
        skip: notImplemmentedYet,
      );
    });

    group('partially written options (abbr)', () {
      testCompletion(
        'just dash',
        forLine: 'example_cli some_command -',
        suggests: allAbbreviationssInThisLevel,
        skip: notImplemmentedYet,
      );
    });

    group('partially written options (invalid)', () {
      testCompletion(
        'do not complete hidden options',
        forLine: 'example_cli some_command --hidd',
        suggests: noSuggestions,
        skip: notImplemmentedYet,
      );

      testCompletion(
        'do not complete ubnknown options',
        forLine: 'example_cli some_command --invalid',
        suggests: noSuggestions,
        skip: notImplemmentedYet,
      );
    });

    group('options values', () {
      group('discrete', () {
        testCompletion(
          'suggest possible options',
          forLine: 'example_cli some_command --discrete  ',
          suggests: {
            'foo': 'foo help',
            'bar': 'bar help',
            'faa': 'faa help',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'suggest matching options',
          forLine: 'example_cli some_command  --discrete  f',
          suggests: {
            'foo': 'foo help',
            'faa': 'faa help',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          '**do not** suggest possible options when using equals/quote syntax',
          forLine: 'example_cli some_command --discrete="',
          suggests: noSuggestions,
          skip: notImplemmentedYet,
        );
      });

      group('discrete (aliases)', () {
        testCompletion(
          'suggest matching options for alias option when typed',
          forLine: 'example_cli some_command --allowed ',
          suggests: {
            'foo': 'foo help',
            'bar': 'bar help',
            'faa': 'faa help',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'suggest matching options for alias option when typed 2',
          forLine: 'example_cli some_command --defined-values ',
          suggests: {
            'foo': 'foo help',
            'bar': 'bar help',
            'faa': 'faa help',
          },
          skip: notImplemmentedYet,
        );
      });

      group('continuous', () {
        testCompletion(
          'suggest nothing when previous option is continuous',
          forLine: 'example_cli some_command --continuous  ',
          suggests: noSuggestions,
          skip: notImplemmentedYet,
        );

        testCompletion(
          'suggest all options when previous option is continuous with a value',
          forLine: 'example_cli some_command --continuous="yeahoo" ',
          suggests: allOptionsInThisLevel,
          skip: notImplemmentedYet,
        );

        testCompletion(
          'suggest all options when previous option is continuous with a value',
          forLine: 'example_cli some_command --continuous yeahoo ',
          suggests: allOptionsInThisLevel,
          skip: notImplemmentedYet,
        );
      });

      group('flags', () {
        testCompletion(
          'suggest all options when a flag was declared',
          forLine: 'example_cli some_command --flag  ',
          suggests: allOptionsInThisLevel,
          skip: notImplemmentedYet,
        );

        testCompletion(
          'suggest all options when a negated flag was declared',
          forLine: 'example_cli some_command --no-flag  ',
          suggests: allOptionsInThisLevel,
          skip: notImplemmentedYet,
        );
      });
    });

    group('options values (abbr)', () {
      group('discrete', () {
        testCompletion(
          'suggest possible options',
          forLine: 'example_cli some_command -d',
          suggests: {
            '-dfoo': 'foo help',
            '-dbar': 'bar help',
            '-dfaa': 'faa help',
          },
          skip: notImplemmentedYet,
        );

        testCompletion(
          'suggest matching options',
          forLine: 'example_cli some_command  -df',
          suggests: {
            '-dfoo': 'foo help',
            '-dfaa': 'faa help',
          },
          skip: notImplemmentedYet,
        );
      });
    });

    group('invalid options', () {
      testCompletion(
        'just dash with a space after',
        forLine: 'example_cli some_command - ',
        suggests: allOptionsInThisLevel,
        skip: notImplemmentedYet,
      );
    });

    group(
      skip: notImplemmentedYet,
      'repeating options',
      () {
        group('non multi options', () {});

        group('multi options', () {});
      },
    );
  });

  group('some_other_command', () {
    group('empty', () {
      testCompletion(
        'basic usage',
        forLine: 'example_cli some_other_command ',
        suggests: {
          'subcommand': 'A sub command of some_other_command',
          '--help': 'Print this usage information.',
        },
      );
    });

    group('partially written sub command', () {
      testCompletion(
        'partially written sub command',
        forLine: 'example_cli some_other_command sub',
        suggests: {
          'subcommand': 'A sub command of some_other_command',
        },
      );
    });

    group('subcommand', () {
      final allOptionsInThisLevel = <String, String?>{
        '--help': 'Print this usage information.',
        '--flag': 'a flag just to show we are in the subcommand',
      };
      group('empty', () {
        testCompletion(
          'basic usage',
          forLine: 'example_cli some_other_command subcommand',
          suggests: allOptionsInThisLevel,
          skip: notImplemmentedYet,
        );

        testCompletion(
          'basic usage with lots of spaces in between',
          forLine: 'example_cli    some_other_command    subcommand',
          suggests: allOptionsInThisLevel,
          skip: notImplemmentedYet,
        );

        testCompletion(
          'basic usage with args in between',
          forLine: 'example_cli -f some_other_command subcommand',
          suggests: allOptionsInThisLevel,
          skip: notImplemmentedYet,
        );
      });

      group('empty (aliases)', () {
        testCompletion(
          'basic usage with args in between',
          forLine: 'example_cli some_other_command subcommand_alias',
          suggests: allOptionsInThisLevel,

        );
      });
    });
  });

  group('argument terminator bails', () {
    testCompletion(
      'between commands',
      forLine: 'example_cli -- some_command',
      suggests: noSuggestions,
    );

    testCompletion(
      'between after commands',
      forLine: 'example_cli some_command -- ',
      suggests: noSuggestions,
    );

    testCompletion(
      'between after/before args',
      forLine:
          'example_cli some_command -f --continuous="foo/bar" -- a --something',
      suggests: noSuggestions,
    );
  });
}

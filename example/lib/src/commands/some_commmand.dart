import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that has no sub commands (a.k.a leaf command) that
/// receives all the common cases of option mapping: options, muilt-options,
/// flags and whatnot
class SomeCommand extends Command<int> {
  SomeCommand(this._logger) {
    argParser
      ..addOption(
        'discrete',
        abbr: 'd',
        help: 'A discrete option with "allowed" values (mandatory)',
        allowed: ['foo', 'bar', 'faa'],
        aliases: [
          'allowed',
          'defined-values',
        ],
        allowedHelp: {
          'foo': 'foo help',
          'bar': 'bar help',
          'faa': 'faa help',
        },
        mandatory: true,
      )
      ..addSeparator('yay')
      ..addOption(
        'hidden',
        hide: true,
        help: 'A hidden option',
      )
      ..addOption(
        'continuous', // intentionally, this one does not have an abbr
        help: 'A continuous option: any value is allowed',
      )
      ..addMultiOption(
        'multi-d',
        abbr: 'm',
        allowed: [
          'fii',
          'bar',
          'fee',
          'i have space', // arg parser wont accept space on "allowed" values,
          // therefore this should never appear on completions
        ],
        allowedHelp: {
          'fii': 'fii help',
          'bar': 'bar help',
          'fee': 'fee help',
          'i have space': 'an allowed option with space on it',
        },
        help: 'An discrete option that can be passed multiple times ',
      )
      ..addMultiOption(
        'multi-c',
        abbr: 'n',
        help: 'An continuous option that can be passed multiple times',
      )
      ..addFlag(
        'flag',
        abbr: 'f',
      )
      ..addFlag(
        'inverseflag',
        abbr: 'i',
        defaultsTo: true,
        help: 'A flag that the default value is true',
      )
      ..addFlag(
        'trueflag',
        abbr: 't',
        help: 'A flag that cannot be negated',
        negatable: false,
      );
  }

  final Logger _logger;

  @override
  String get description => 'This is help for some_command';

  @override
  String get name => 'some_command';

  @override
  List<String> get aliases => [
        'disguised:some_commmand',
        'melon',
      ];

  @override
  Future<int> run() async {
    for (final option in argResults!.options) {
      _logger.info('  - $option: ${argResults![option]}');
    }

    return ExitCode.success.code;
  }
}

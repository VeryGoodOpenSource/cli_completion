import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

class SomeOtherCommand extends Command<int> {
  SomeOtherCommand(this._logger) {
    addSubcommand(SomeSubCommand(_logger));
  }

  final Logger _logger;

  @override
  String get description => 'This is help for some_other_command';

  @override
  String get name => 'some_other_command';
}

class SomeSubCommand extends Command<int> {
  SomeSubCommand(this._logger);

  final Logger _logger;

  @override
  String get description => 'A sub command of some_other_command';

  @override
  String get name => 'subcommand';

  @override
  Future<int> run() async {
    for (final option in argResults!.options) {
      _logger.info('  - $option: ${argResults![option]}');
    }

    return ExitCode.success.code;
  }
}

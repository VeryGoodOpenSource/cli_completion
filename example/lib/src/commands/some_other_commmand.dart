import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that only has a sub command
class SomeOtherCommand extends Command<int> {
  SomeOtherCommand(this._logger) {
    addSubcommand(_SomeSubCommand(_logger));
  }

  final Logger _logger;

  @override
  String get description => 'This is help for some_other_command';

  @override
  String get name => 'some_other_command';
}

/// A command under [SomeOtherCommand] that does not receive options and read
/// the "rest" field from arg results
class _SomeSubCommand extends Command<int> {
  _SomeSubCommand(this._logger);

  final Logger _logger;

  @override
  String get description => 'A sub command of some_other_command';

  @override
  String get name => 'subcommand';

  @override
  Future<int> run() async {
    _logger.info(description);
    for (final rest in argResults!.rest) {
      _logger.info('  - $rest');
    }

    return ExitCode.success.code;
  }
}

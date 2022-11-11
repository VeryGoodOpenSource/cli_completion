import 'package:args/command_runner.dart';
import 'package:example/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';

const executableName = 'example_cli';
const packageName = 'example';
const description = 'Example for cli_completion';

/// {@template example_command_runner}
/// A [CommandRunner] for the CLI.
///
/// ```
/// $ example_cli --version
/// ```
/// {@endtemplate}
class ExampleCommandRunner extends CommandRunner<int> {
  /// {@macro example_command_runner}
  ExampleCommandRunner({
    Logger? logger,
  })  : _logger = logger ?? Logger(),
        super(executableName, description) {
    // Add root options and flags
    argParser.addFlag(
      'rootFlag',
      help: 'A flag in the root command',
    );

    // Add sub commands
    addCommand(SomeCommand(_logger));
    addCommand(SomeOtherCommand(_logger));
  }

  @override
  void printUsage() => _logger.info(usage);

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final topLevelResults = parse(args);

      return await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on FormatException catch (e, stackTrace) {
      // On format errors, show the commands error message, root usage and
      // exit with an error code
      _logger
        ..err(e.message)
        ..err('$stackTrace')
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      // On usage errors, show the commands usage message and
      // exit with an error code
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }
}

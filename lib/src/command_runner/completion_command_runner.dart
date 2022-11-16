import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/src/command_runner/commands/commands.dart';
import 'package:cli_completion/src/exceptions.dart';
import 'package:cli_completion/src/install/completion_installation.dart';
import 'package:cli_completion/src/system_shell.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

/// {@template completion_command_runner}
/// A [CommandRunner] that takes care of installing shell completion scripts
/// and handle completion requests.
/// {@endtemplate}
///
/// It tries to install completion scripts upon any command run.
///
/// Adds [HandleCompletionRequestCommand] to route completion requests to
/// other sub commands.
///
/// Adds [InstallCompletionFilesCommand] to enable the user to
/// manually install completion files.
abstract class CompletionCommandRunner<T> extends CommandRunner<T> {
  /// {@macro completion_command_runner}
  CompletionCommandRunner(super.executableName, super.description) {
    addCommand(HandleCompletionRequestCommand<T>(completionLogger));
    addCommand(InstallCompletionFilesCommand<T>());
  }

  /// The [Logger] used to prompt the completion suggestions.
  final Logger completionLogger = Logger();

  /// The [Logger] used to display messages during completion installation.
  final Logger completionInstallationLogger = Logger();

  CompletionInstallation? _completionInstallation;

  /// The [CompletionInstallation] used to install completion files.
  @visibleForTesting
  CompletionInstallation get completionInstallation {
    if (_completionInstallation != null) {
      return _completionInstallation!;
    }

    _completionInstallation = CompletionInstallation.fromSystemShell(
      systemShell: SystemShell.current(),
      logger: completionInstallationLogger,
    );

    return _completionInstallation!;
  }

  @override
  @mustCallSuper
  Future<T?> runCommand(ArgResults topLevelResults) async {
    final reservedCommands = [
      HandleCompletionRequestCommand.commandName,
      InstallCompletionFilesCommand.commandName,
    ];

    if (!reservedCommands.contains(topLevelResults.command?.name)) {
      // When auto installing, use error level to display messages.
      tryInstallCompletionFiles(Level.error);
    }

    return super.runCommand(topLevelResults);
  }

  /// Tries to install completion files for the current shell.
  @internal
  void tryInstallCompletionFiles(Level level) {
    try {
      completionInstallationLogger.level = level;
      completionInstallation.install(executableName);
    } on CompletionInstallationException catch (e) {
      completionInstallationLogger.err(e.toString());
    }
  }
}

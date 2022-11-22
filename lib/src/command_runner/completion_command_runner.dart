import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/exceptions.dart';
import 'package:cli_completion/src/install/completion_installation.dart';
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

  /// Environment map which can be overridden for testing purposes.
  Map<String, String>? environmentOverride;

  /// The [SystemShell] used to determine the current shell.
  SystemShell? get systemShell =>
      SystemShell.current(environmentOverride: environmentOverride);

  CompletionInstallation? _completionInstallation;

  /// The [CompletionInstallation] used to install completion files.
  CompletionInstallation get completionInstallation {
    var completionInstallation = _completionInstallation;

    completionInstallation ??= CompletionInstallation.fromSystemShell(
      systemShell: systemShell,
      logger: completionInstallationLogger,
    );

    return _completionInstallation = completionInstallation;
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

  /// Renders a [CompletionResult] into the current system shell.
  ///
  /// This is called after a completion request (sent by a shell function) is
  /// parsed and the output is ready to be displayed.
  ///
  /// Override this to intercept and customize the general
  /// output of the completions.
  void renderCompletionResult(CompletionResult completionResult) {
    final systemShell = this.systemShell;
    if (systemShell == null) {
      return;
    }
    completionResult.render(completionLogger, systemShell);
  }
}

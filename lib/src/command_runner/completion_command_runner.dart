import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/installer.dart';
import 'package:cli_completion/parser.dart';
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
  CompletionCommandRunner(
    super.executableName,
    super.description, {
    super.usageLineLength,
    super.suggestionDistanceLimit,
  }) {
    addCommand(HandleCompletionRequestCommand<T>());
    addCommand(InstallCompletionFilesCommand<T>());
    addCommand(UnistallCompletionFilesCommand<T>());
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

  /// Define whether the installation of the completion files should done
  /// automatically upon the first command run.
  ///
  /// If set to false the user will have to manually install the completion
  /// files via the `install-completion-files` command.
  ///
  /// Override this field to disable auto installation.
  bool get enableAutoInstall => true;

  /// The [CompletionInstallation] used to install completion files.
  @visibleForTesting
  CompletionInstallation get completionInstallation {
    var completionInstallation = _completionInstallation;

    completionInstallation ??= CompletionInstallation.fromSystemShell(
      systemShell: systemShell,
      logger: completionInstallationLogger,
    );

    return _completionInstallation = completionInstallation;
  }

  /// The list of commands that should not trigger the auto installation.
  static const _reservedCommands = {
    HandleCompletionRequestCommand.commandName,
    InstallCompletionFilesCommand.commandName,
    UnistallCompletionFilesCommand.commandName,
  };

  @override
  @mustCallSuper
  Future<T?> runCommand(ArgResults topLevelResults) async {
    if (enableAutoInstall &&
        !_reservedCommands.contains(topLevelResults.command?.name)) {
      // When auto installing, use error level to display messages.
      tryInstallCompletionFiles(Level.error);
    }

    return super.runCommand(topLevelResults);
  }

  /// Tries to install completion files for the current shell.
  @internal
  void tryInstallCompletionFiles(Level level, {bool force = false}) {
    try {
      completionInstallationLogger.level = level;
      completionInstallation.install(executableName, force: force);
    } on CompletionInstallationException catch (e) {
      completionInstallationLogger.warn(e.toString());
    } on Exception catch (e) {
      completionInstallationLogger.err(e.toString());
    }
  }

  /// Tries to uninstall completion files for the current shell.
  @internal
  void tryUninstallCompletionFiles(Level level) {
    try {
      completionInstallationLogger.level = level;
      completionInstallation.uninstall(executableName);
    } on CompletionUninstallationException catch (e) {
      completionInstallationLogger.warn(e.toString());
    } on Exception catch (e) {
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

    for (final entry in completionResult.completions.entries) {
      switch (systemShell) {
        case SystemShell.zsh:
          // On zsh, colon acts as delimitation between a suggestion and its
          // description. Any literal colon should be escaped.
          final suggestion = entry.key.replaceAll(':', r'\:');
          final description = entry.value?.replaceAll(':', r'\:');

          completionLogger.info(
            '$suggestion${description != null ? ':$description' : ''}',
          );
        case SystemShell.bash:
          completionLogger.info(entry.key);
      }
    }
  }
}

import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/install.dart';
import 'package:cli_completion/src/exceptions.dart';
import 'package:cli_completion/src/handling/commands/handle_completion_command.dart';
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
abstract class CompletionCommandRunner<T> extends CommandRunner<T> {

  /// {@macro completion_command_runner}
  CompletionCommandRunner(super.executableName, super.description) {
    addCommand(HandleCompletionRequestCommand<T>(completionLogger));
  }

  /// The [Logger] used to display the completion suggestions
  final Logger completionLogger = Logger();

  @override
  Future<T?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name !=
        HandleCompletionRequestCommand.commandName) {
      tryAutoInstallInstallCompletion();
    }

    return super.runCommand(topLevelResults);
  }

  /// Tries to install shell completion scripts automatically.
  @protected
  void tryAutoInstallInstallCompletion() {
    try {
      installCompletionFiles(
        logger: completionLogger,
        rootCommand: executableName,
      );
    } on CompletionInstallationException catch (e) {
      completionLogger.detail(e.toString());
    }
  }
}

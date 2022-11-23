import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_completion/src/command_runner/completion_command_runner.dart';
import 'package:cli_completion/src/handling/completion_state.dart';
import 'package:cli_completion/src/handling/parser.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template handle_completion_request_command}
/// A hidden [Command] added by [CompletionCommandRunner] that handles the
/// "completion" sub command.
/// This is called by a shell function when the user presses "tab".
/// Any output to stdout during this call will be interpreted as suggestions
/// for completions.
/// {@endtemplate}
class HandleCompletionRequestCommand<T> extends Command<T> {
  /// {@macro handle_completion_request_command}
  HandleCompletionRequestCommand(this.logger);

  @override
  String get description {
    return 'Handles shell completion (should never be called manually)';
  }

  /// The string that the shell will use to call for completion suggestions
  static const commandName = 'completion';

  @override
  String get name => commandName;

  @override
  bool get hidden => true;

  /// The [Logger] used to display the completion suggestions
  final Logger logger;

  @override
  CompletionCommandRunner<T> get runner {
    return super.runner! as CompletionCommandRunner<T>;
  }

  @override
  FutureOr<T>? run() {
    try {
      final completionState = CompletionState.fromEnvironment(
        runner.environmentOverride,
      );
      if (completionState == null) {
        return null;
      }

      final result = CompletionParser(
        state: completionState,
        runnerGrammar: runner.argParser,
        runnerCommands: runner.commands,
      ).parse();
      runner.renderCompletionResult(result);
    } on Exception {
      // Do not output any Exception here, since even error messages are
      // interpreted as completion suggestions
    }
    return null;
  }
}

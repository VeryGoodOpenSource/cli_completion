import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/parser.dart';

/// {@template handle_completion_request_command}
/// A hidden [Command] added by [CompletionCommandRunner] that handles the
/// "completion" sub command.
/// {@endtemplate}
///
/// This is called by a shell function when the user presses "tab".
/// Any output to stdout during this call will be interpreted as suggestions
/// for completions.
class HandleCompletionRequestCommand<T> extends Command<T> {
  /// {@macro handle_completion_request_command}
  HandleCompletionRequestCommand();

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

  @override
  CompletionCommandRunner<T> get runner {
    return super.runner! as CompletionCommandRunner<T>;
  }

  @override
  FutureOr<T>? run() {
    try {
      // Get completion request params from the environment
      final completionState = CompletionState.fromEnvironment(
        runner.environmentOverride,
      );

      // If the parameters in the environment are not supported or invalid,
      // do not proceed with completion complete.
      if (completionState == null) {
        return null;
      }

      // Find the completion level
      final completionLevel = CompletionLevel.find(
        completionState.args,
        runner.argParser,
        runner.commands,
      );

      // Do not complete if the command structure is not recognized
      if (completionLevel == null) {
        return null;
      }

      // Parse the completion level into completion suggestions
      final completionResults = CompletionParser(
        completionLevel: completionLevel,
      ).parse();

      // Render the completion suggestions
      for (final completionResult in completionResults) {
        runner.renderCompletionResult(completionResult);
      }
    } on Exception {
      // Do not output any Exception here, since even error messages are
      // interpreted as completion suggestions
    }
    return null;
  }
}

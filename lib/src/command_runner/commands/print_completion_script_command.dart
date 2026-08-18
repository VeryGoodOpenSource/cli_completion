import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';

/// {@template print_completion_script_command}
/// A [Command] added by [CompletionCommandRunner] only when auto installation
/// is disabled that prints the completion script for the current shell to
/// stdout.
///
/// It allows users to install the completion script manually by piping the
/// output into their shell configuration file, for example:
/// ```sh
/// my_cli completion-script >> ~/.zshrc
/// ```
///
/// This mirrors the approach used by other CLIs such as npm and the GitHub CLI.
///
/// Unlike the other completion commands, this command is intentionally left
/// visible in `--help` (it does not override [hidden]) so that users can
/// discover it.
/// {@endtemplate}
class PrintCompletionScriptCommand<T> extends Command<T> {
  /// {@macro print_completion_script_command}
  PrintCompletionScriptCommand();

  @override
  String get description {
    return 'Prints the completion script for the current shell to stdout.';
  }

  /// The string that the user can call to print the completion script.
  static const commandName = 'completion-script';

  @override
  String get name => commandName;

  @override
  CompletionCommandRunner<T> get runner {
    return super.runner! as CompletionCommandRunner<T>;
  }

  @override
  FutureOr<T>? run() {
    runner.printCompletionScript();
    return null;
  }
}

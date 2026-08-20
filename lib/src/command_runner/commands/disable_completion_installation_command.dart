import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';

/// {@template disable_completion_installation_command}
/// A hidden [Command] added by [CompletionCommandRunner] that allows the user
/// to disable the automatic installation of completion files.
///
/// By default, [CompletionCommandRunner] tries to install completion files
/// upon any command run. Running this command persists the user's choice to
/// opt out of that behavior.
///
/// Users can still manually install completion files via the
/// `install-completion-files` command, which also re-enables the automatic
/// installation.
/// {@endtemplate}
class DisableCompletionInstallationCommand<T> extends Command<T> {
  /// {@macro disable_completion_installation_command}
  DisableCompletionInstallationCommand();

  @override
  String get description {
    return 'Disables the automatic installation of completion files.';
  }

  /// The string that the user can call to disable the automatic installation
  /// of completion files.
  static const commandName = 'disable-completion-auto-install';

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
    runner.disableAutoInstall();
    return null;
  }
}

import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_completion/src/command_runner/completion_command_runner.dart';

import 'package:mason_logger/mason_logger.dart';

/// {@template install_completion_command}
/// A hidden [Command] added by [CompletionCommandRunner] that handles the
/// "install-completion-files" sub command.
///
/// It can be used to manually install the completion files
/// (otherwise automatically installed by [CompletionCommandRunner]).
/// {@endtemplate}
///
/// Differently from the auto installation performed by
/// [CompletionCommandRunner] on any command run,
/// this command logs messages during the installation process.
class InstallCompletionFilesCommand<T> extends Command<T> {
  /// {@macro install_completion_command}
  InstallCompletionFilesCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      negatable: false,
    );
  }

  @override
  String get description {
    return 'Manually installs completion files for the current shell.';
  }

  /// The string that the user can call to manually install completion files
  static const commandName = 'install-completion-files';

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
    final verbose = argResults!['verbose'] as bool;
    final level = verbose ? Level.verbose : Level.info;
    runner.tryInstallCompletionFiles(level);
    return null;
  }
}

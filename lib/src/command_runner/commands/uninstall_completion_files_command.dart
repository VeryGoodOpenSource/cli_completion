import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template ninstall_completion_command}
/// A hidden [Command] added by [CompletionCommandRunner] that handles the
/// "uninstall-completion-files" sub command.
///
/// It can be used to manually uninstall the completion files
/// (those installed by [CompletionCommandRunner] or
/// [InstallCompletionFilesCommand]).
/// {@endtemplate}
class UnistallCompletionFilesCommand<T> extends Command<T> {
  /// {@macro uninstall_completion_command}
  UnistallCompletionFilesCommand() {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose output',
      negatable: false,
    );
  }

  @override
  String get description {
    return 'Manually uninstalls completion files for the current shell.';
  }

  /// The string that the user can call to manually uninstall completion files.
  static const commandName = 'uninstall-completion-files';

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
    runner.tryUninstallCompletionFiles(level);
    return null;
  }
}

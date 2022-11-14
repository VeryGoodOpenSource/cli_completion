import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/install.dart';
import 'package:cli_completion/src/exceptions.dart';
import 'package:cli_completion/src/handling/completion_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

abstract class CompletionCommandRunner<T> extends CommandRunner<T> {
  CompletionCommandRunner(super.executableName, super.description) {
    addCommand(CompletionCommand<T>(logger));
  }

  final Logger logger = Logger();

  final bool autoInstall = true;

  @override
  Future<T?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name != 'completion') {
      tryAutoInstallInstallCompletion();
    }

    return super.runCommand(topLevelResults);
  }

  @protected
  void tryAutoInstallInstallCompletion() {
    if(!autoInstall) return;

    try {
      installCompletionFiles(logger: logger, rootCommand: executableName);
    } on CompletionInstallationException catch (e) {
      logger.detail(e.toString());
    }
  }
}

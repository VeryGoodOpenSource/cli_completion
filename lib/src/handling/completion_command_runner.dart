import 'dart:async';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/install.dart';
import 'package:cli_completion/src/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

abstract class CompletionCommandRunner<T> extends CommandRunner<T> {
  CompletionCommandRunner(super.executableName, super.description);

  final Logger logger = Logger();

  @override
  Future<T?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name != 'completion') {
      tryInstallCompletion();
    }

    return super.runCommand(topLevelResults);
  }

  @protected
  void tryInstallCompletion() {
    try {
      installCompletion(logger: logger, rootCommand: executableName);
    } on CompletionInstallationException catch (e) {
      logger.detail(e.toString());
    }
  }
}

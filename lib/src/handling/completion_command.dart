import 'dart:async';

import 'package:args/command_runner.dart';

import 'package:cli_completion/src/handling/completion_command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

class CompletionCommand<T> extends Command<T> {
  CompletionCommand(this.logger);

  @override
  String get description =>
      'handles shell completion (should never be called manually)';

  @override
  String get name => 'completion';

  @override
  bool get hidden => true;

  /// The [Logger] used to display the completion suggestions
  final Logger logger;

  @override
  CompletionCommandRunner<T> get runner {
    return super.runner! as CompletionCommandRunner<T>;
  }

  FutureOr<T>? run() {
    logger
      ..info('This')
      ..info('is')..info('a suggestion');

    return null;
  }
}

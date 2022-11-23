import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/completion_level.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mason_logger/src/mason_logger.dart';

import 'arg_parser_extension.dart';

/// {@template completion_parser}
/// The workhorse of the completion system.
///
/// It is responsible for discovering the possible completions given a
/// [CompletionState].
/// {@endtemplate}
class CompletionParser {
  /// {@macro completion_parser}
  CompletionParser(this._state, this._runner);

  final CompletionState _state;

  final CompletionCommandRunner<dynamic> _runner;

  /// Do not complete if there is an argument terminator in the middle of
  /// the sentence
  bool _containsArgumentTerminator() {
    final args = _state.args;
    return args.isNotEmpty && args.take(args.length - 1).contains('--');
  }

  /// Parse the given [CompletionState] into a [CompletionResult] given the
  /// structure of commands and options declared by the CLIs [ArgParser].
  Iterable<CompletionResult> parse() sync* {
    if (_containsArgumentTerminator()) {
      yield const EmptyCompletionResult();
      return;
    }

    if (_state.cpoint < _state.cline.length) {
      // Do not complete when the cursor is not at the end of the line
      yield const EmptyCompletionResult();
      return;
    }

    final completionLevel = CompletionLevel.find(_state.args, _runner);

    if (completionLevel == null) {
      // Do not complete if the command structure is not recognized
      yield const EmptyCompletionResult();
      return;
    }

    final rawArgs = completionLevel.rawArgs;
    final visibleSubcommands = completionLevel.visibleSubcommands;

    final nonEmptyArgs = rawArgs.where((element) => element.isNotEmpty);

    if (nonEmptyArgs.isEmpty) {
      // There is nothing in the user prompt besides known commands
      yield AllOptionsAndCommandsCompletionResult(
        completionLevel: completionLevel,
      );
      return;
    }

    final argOnCursor = rawArgs.last;

    if (argOnCursor.isEmpty) {
      // User pressed space before tab (not currently writing any arg)
      yield AllOptionsAndCommandsCompletionResult(
        completionLevel: completionLevel,
      );
      return;
    }

    // Further code cover the case where the user is in the middle of wiring a
    // word.
    // From now on, avoid early returns with suggestions since completions may
    // include commands and options

    // Check if the user has started to type a sub command and pressed tab
    if (visibleSubcommands.isNotEmpty) {
      yield MatchingCommandsCompletionResult(
        completionLevel: completionLevel,
        pattern: argOnCursor,
      );
    }

    // todo(renancaraujo): add option completions
  }
}

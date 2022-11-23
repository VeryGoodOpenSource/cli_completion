import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/completion_level.dart';
import 'package:meta/meta.dart';

/// {@template completion_parser}
/// The workhorse of the completion system.
///
/// It is responsible for discovering the possible completions given a
/// [CompletionState] and the command runner [runnerGrammar] and
/// [runnerCommands].
/// {@endtemplate}
class CompletionParser {
  /// {@macro completion_parser}
  CompletionParser({
    required this.state,
    required this.runnerGrammar,
    required this.runnerCommands,
  });

  /// Represents the suer input that needs to be completed.
  final CompletionState state;

  /// The [ArgParser] present in the command runner.
  final ArgParser runnerGrammar;

  /// The commands declared in the command runner.
  final Map<String, Command<dynamic>> runnerCommands;

  /// Do not complete if there is an argument terminator in the middle of
  /// the sentence
  bool _containsArgumentTerminator() {
    final args = state.args;
    return args.isNotEmpty && args.take(args.length - 1).contains('--');
  }

  @visibleForTesting
  CompletionLevel? Function(
    Iterable<String> rootArgs,
    ArgParser runnerGrammar,
    Map<String, Command<dynamic>> runnerCommands,
  ) findCompletionLevel = CompletionLevel.find;

  /// Parse the given [CompletionState] into a [CompletionResult] given the
  /// structure of commands and options declared by the CLIs [ArgParser].
  List<CompletionResult> parse() {
    return _parse().toList();
  }

  Iterable<CompletionResult> _parse() sync* {
    if (_containsArgumentTerminator()) {
      return;
    }

    if (state.cpoint < state.cline.length) {
      // Do not complete when the cursor is not at the end of the line
      return;
    }

    final completionLevel = findCompletionLevel(
      state.args,
      runnerGrammar,
      runnerCommands,
    );

    if (completionLevel == null) {
      // Do not complete if the command structure is not recognized
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

    // Further code cover the case where the user is in the middle of writing a
    // word.
    // From now on, avoid early returns since completions may
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

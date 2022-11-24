import 'package:args/args.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/completion_level.dart';

/// {@template completion_parser}
/// The workhorse of the completion system.
///
/// Responsible for discovering the possible completions given a
/// [CompletionLevel]
/// {@endtemplate}
class CompletionParser {
  /// {@macro completion_parser}
  CompletionParser({
    required this.completionLevel,
  });

  /// The [CompletionLevel] to parse.
  final CompletionLevel completionLevel;

  /// Parse the given [CompletionState] into a [CompletionResult] given the
  /// structure of commands and options declared by the CLIs [ArgParser].
  List<CompletionResult> parse() {
    return _parse().toList();
  }

  Iterable<CompletionResult> _parse() sync* {
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

import 'package:args/args.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/arg_parser_extension.dart';
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
  List<CompletionResult> parse() => _parse().toList();

  Iterable<CompletionResult> _parse() sync* {
    final rawArgs = completionLevel.rawArgs;
    final visibleSubcommands = completionLevel.visibleSubcommands;

    final nonEmptyArgs = rawArgs.where((element) => element.isNotEmpty);

    if (nonEmptyArgs.isEmpty) {
      // There is nothing in the user prompt between the last known command and
      // the cursor
      // e.g. `my_cli commandName|`
      yield AllOptionsAndCommandsCompletionResult(
        completionLevel: completionLevel,
      );
      return;
    }

    final argOnCursor = rawArgs.last;

    if (argOnCursor.isEmpty) {
      // Check if the last given argument, if it is an option,
      // complete with the known allowed values.
      // e.g. `my_cli commandName --option |` or `my_cli commandName -o |`
      final lastNonEmpty = nonEmptyArgs.last;

      final suggestionForValues = _getOptionValues(lastNonEmpty);

      if (suggestionForValues != null) {
        yield suggestionForValues;
        return;
      }

      // User pressed space before tab (not currently writing any arg ot the
      // arg is a flag)
      // e.g. `my_cli commandName something |`
      yield AllOptionsAndCommandsCompletionResult(
        completionLevel: completionLevel,
      );
      return;
    }

    // Check if the user has started to type the value of an
    // option with "allowed" values
    // e.g. `my_cli --option valueNam|` or `my_cli -o valueNam|`
    if (nonEmptyArgs.length > 1) {
      final secondLastNonEmpty =
          nonEmptyArgs.elementAt(nonEmptyArgs.length - 2);

      final resultForValues = _getOptionValues(secondLastNonEmpty, argOnCursor);

      if (resultForValues != null) {
        yield resultForValues;
        return;
      }
    }

    // Further code cover the case where the user is in the middle of writing a
    // word.

    // From now on, avoid early returns since completions may include commands
    // and options alike

    // Check if the user has started to type a sub command and pressed tab
    // e.g. `my_cli commandNam|`
    if (visibleSubcommands.isNotEmpty) {
      yield MatchingCommandsCompletionResult(
        completionLevel: completionLevel,
        pattern: argOnCursor,
      );
    }

    // Check if the user has started to type an option
    // e.g. `my_cli commandName --optionNam|`
    if (isOption(argOnCursor)) {
      yield MatchingOptionsCompletionResult(
        completionLevel: completionLevel,
        pattern: argOnCursor.substring(2),
      );
    }

    // Abbreviation cases
    if (isAbbr(argOnCursor)) {
      // Check if the user typed only a dash
      if (argOnCursor.length == 1) {
        yield AllAbbrOptionsCompletionResult(completionLevel: completionLevel);
      } else {
        // The user has started to type the value of an
        // option with "allowed" in an abbreviated form or just the abbreviation
        // e.g. `my_cli commandName -a|` or `my_cli commandName -avalueNam|`

        final abbrName = argOnCursor.substring(1, 2);
        final abbrValue = argOnCursor.substring(2);

        yield OptionValuesCompletionResult.abbr(
          abbrName: abbrName,
          completionLevel: completionLevel,
          pattern: abbrValue,
          includeAbbrName: true,
        );
      }
    }
  }

  CompletionResult? _getOptionValues(String value, [String? valuePattern]) {
    if (isOption(value)) {
      final optionName = value.substring(2);
      final option = completionLevel.grammar.findByNameOrAlias(optionName);

      final receivesValue = option != null && !option.isFlag;

      if (receivesValue) {
        return OptionValuesCompletionResult(
          optionName: optionName,
          completionLevel: completionLevel,
          pattern: valuePattern,
        );
      }
    } else if (isAbbr(value) && value.length > 1) {
      final abbrName = value.substring(1, 2);
      final option = completionLevel.grammar.findByAbbreviation(abbrName);

      final receivesValue = option != null && !option.isFlag;

      if (receivesValue) {
        return OptionValuesCompletionResult.abbr(
          abbrName: abbrName,
          completionLevel: completionLevel,
          pattern: valuePattern,
        );
      }
    }
    return null;
  }
}

import 'package:args/args.dart';
import 'package:cli_completion/parser.dart';
import 'package:meta/meta.dart';

/// {@template completion_result}
/// Describes the result of a completion handling process.
/// {@endtemplate}
///
/// Generated after parsing a completion request from the shell, it is
/// responsible to contain the information to be sent back to the shell
/// (via stdout) including suggestions and its metadata (description).
///
/// See also:
/// - [AllOptionsAndCommandsCompletionResult]
/// - [AllAbbrOptionsCompletionResult]
/// - [MatchingCommandsCompletionResult]
/// - [MatchingOptionsCompletionResult]
/// - [OptionValuesCompletionResult]
@immutable
abstract class CompletionResult {
  /// {@macro completion_result}
  const CompletionResult();

  /// A collection of [MapEntry] with completion suggestions to their
  /// descriptions.
  Map<String, String?> get completions;
}

/// {@template all_options_and_commands_completion_result}
/// A [CompletionResult] that suggests all options and commands in a
/// [completionLevel].
/// {@endtemplate}
class AllOptionsAndCommandsCompletionResult extends CompletionResult {
  /// {@macro all_options_and_commands_completion_result}
  const AllOptionsAndCommandsCompletionResult({
    required this.completionLevel,
  });

  /// The [CompletionLevel] in which the suggested options and subcommands are
  /// supposed to be located at.
  final CompletionLevel completionLevel;

  @override
  Map<String, String?> get completions {
    final mapCompletions = <String, String?>{};
    for (final subcommand in completionLevel.visibleSubcommands) {
      mapCompletions[subcommand.name] = subcommand.description;
    }
    for (final option in completionLevel.visibleOptions) {
      mapCompletions['--${option.name}'] = option.help;
      if (option.negatable ?? false) {
        mapCompletions['--no-${option.name}'] = option.help;
      }
    }
    return mapCompletions;
  }
}

/// {@template all_options_and_commands_completion_result}
/// A [CompletionResult] that suggests all abbreviated options in a
/// [completionLevel].
/// {@endtemplate}
///
/// See also:
/// - [AllOptionsAndCommandsCompletionResult]
class AllAbbrOptionsCompletionResult extends CompletionResult {
  /// {@macro all_options_and_commands_completion_result}
  const AllAbbrOptionsCompletionResult({
    required this.completionLevel,
  });

  /// The [CompletionLevel] in which the suggested options and subcommands are
  /// supposed to be located at.
  final CompletionLevel completionLevel;

  @override
  Map<String, String?> get completions {
    final mapCompletions = <String, String?>{};
    for (final option in completionLevel.visibleOptions) {
      final abbr = option.abbr;
      if (abbr != null) {
        mapCompletions['-$abbr'] = option.help;
      }
    }
    return mapCompletions;
  }
}

/// {@template matching_commands_completion_result}
/// A [CompletionResult] that suggests the sub commands in a [completionLevel]
/// that matches [pattern] (A.K.A: startsWith).
/// {@endtemplate}
///
/// If a command doesnt match the pattern, its aliases are also checked.
class MatchingCommandsCompletionResult extends CompletionResult {
  /// {@macro matching_commands_completion_result}
  const MatchingCommandsCompletionResult({
    required this.completionLevel,
    required this.pattern,
  });

  /// The [CompletionLevel] in which the suggested commands are supposed to be
  /// located at.
  final CompletionLevel completionLevel;

  /// The pattern in which the matching commands will be suggested.
  final String pattern;

  @override
  Map<String, String?> get completions {
    final mapCompletions = <String, String>{};
    for (final command in completionLevel.visibleSubcommands) {
      final description = command.description;
      if (command.name.startsWith(pattern)) {
        mapCompletions[command.name] = description;
      } else {
        for (final alias in command.aliases) {
          if (alias.startsWith(pattern)) {
            mapCompletions[alias] = description;
          }
        }
      }
    }
    return mapCompletions;
  }
}

/// {@template matching_options_completion_result}
/// A [CompletionResult] that suggests the options in a [completionLevel] that
/// starts with [pattern].
/// {@endtemplate}
///
/// If an option does not match the pattern, its aliases will be checked.
class MatchingOptionsCompletionResult extends CompletionResult {
  /// {@macro matching_options_completion_result}
  const MatchingOptionsCompletionResult({
    required this.completionLevel,
    required this.pattern,
  });

  /// The [CompletionLevel] in which the suggested options are supposed to be
  /// located at.
  final CompletionLevel completionLevel;

  /// The pattern in which the matching options will be suggested.
  final String pattern;

  @override
  Map<String, String?> get completions {
    final mapCompletions = <String, String?>{};
    for (final option in completionLevel.visibleOptions) {
      final isNegatable = option.negatable ?? false;
      if (isNegatable) {
        if (option.negatedName.startsWith(pattern)) {
          mapCompletions['--${option.negatedName}'] = option.help;
        } else {
          for (final negatedAlias in option.negatedAliases) {
            if (negatedAlias.startsWith(pattern)) {
              mapCompletions['--$negatedAlias'] = option.help;
            }
          }
        }
      }

      if (option.name.startsWith(pattern)) {
        mapCompletions['--${option.name}'] = option.help;
      } else {
        for (final alias in option.aliases) {
          if (alias.startsWith(pattern)) {
            mapCompletions['--$alias'] = option.help;
          }
        }
      }
    }
    return mapCompletions;
  }
}

/// {@template option_values_completion_result}
/// A [CompletionResult] that suggests the values of an option given its
/// [optionName] and its [completionLevel].
/// {@endtemplate}
///
/// For options with [Option.allowed] values, the suggestions will be those
/// values with [Option.allowedHelp] as description.
///
/// If [pattern] is not null, only the values that start with the pattern will
/// be suggested.
///
/// Use [OptionValuesCompletionResult.isAbbr] to suggest the values of an option
/// in an abbreviated form.
class OptionValuesCompletionResult extends CompletionResult {
  /// {@macro option_values_completion_result}
  const OptionValuesCompletionResult({
    required this.completionLevel,
    required this.optionName,
    this.pattern,
  }) : isAbbr = false,
       includeAbbrName = false;

  /// {@macro option_values_completion_result}
  const OptionValuesCompletionResult.abbr({
    required this.completionLevel,
    required String abbrName,
    this.pattern,
    this.includeAbbrName = false,
  }) : isAbbr = true,
       optionName = abbrName;

  /// The [CompletionLevel] in which the suggested option is supposed to be
  /// located at.
  final CompletionLevel completionLevel;

  /// The pattern in which the matching options values be suggested.
  final String? pattern;

  /// The name of the option whose values will be suggested.
  final String optionName;

  /// Whether the option name is abbreviated.
  final bool isAbbr;

  /// Whether the option name should be included in the suggestions.
  /// This is only used when [isAbbr] is true.
  ///
  /// If true, suggestions will look like `-psomething` where `p` is the
  /// abbreviated option name and `something` is the suggested value.
  final bool includeAbbrName;

  @override
  Map<String, String?> get completions {
    final Option? option;
    if (isAbbr) {
      option = completionLevel.grammar.findByAbbreviation(optionName);
    } else {
      option = completionLevel.grammar.findByNameOrAlias(optionName);
    }

    final allowed = option?.allowed ?? [];
    Iterable<String> filteredAllowed;
    if (pattern == null) {
      filteredAllowed = allowed;
    } else {
      filteredAllowed = allowed.where((e) => e.startsWith(pattern!));
    }
    return {
      for (final allowed in filteredAllowed)
        if (includeAbbrName)
          '-$optionName$allowed': option?.allowedHelp?[allowed]
        else
          allowed: option?.allowedHelp?[allowed],
    };
  }
}

extension on Option {
  String get negatedName => 'no-$name';

  Iterable<String> get negatedAliases => aliases.map((e) => 'no-$e');
}

import 'package:cli_completion/src/handling/completion_level.dart';
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
/// - [MatchingCommandsCompletionResult]
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
    }
    return mapCompletions;
  }
}

/// {@template matching_commands_completion_result}
/// A [CompletionResult] that suggests the sub commands in a [completionLevel]
/// that matches [pattern] (A.K.A: startsWith).
/// {@endtemplate}
class MatchingCommandsCompletionResult extends CompletionResult {
  /// {@macro matching_commands_completion_result}
  const MatchingCommandsCompletionResult({
    required this.completionLevel,
    required this.pattern,
  });

  /// The pattern in which the matching commands will be suggested.
  final String pattern;

  /// The [CompletionLevel] in which the suggested commands are supposed to be
  /// located at.
  final CompletionLevel completionLevel;

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

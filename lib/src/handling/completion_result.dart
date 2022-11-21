import 'package:cli_completion/src/system_shell.dart';
import 'package:mason_logger/mason_logger.dart';
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
/// - [ValueCompletionResult]
/// - [EmptyCompletionResult]
@immutable
abstract class CompletionResult {
  /// Creates a [CompletionResult] that contains predefined suggestions.
  const factory CompletionResult.fromMap(Map<String, String?> completions) =
      ValueCompletionResult._fromMap;

  const CompletionResult._();

  /// Render the completion suggestions to the [shell].
  void render(Logger logger, SystemShell shell);
}

/// {@template value_completion_result}
/// A [CompletionResult] that contains completion suggestions.
/// {@endtemplate}
class ValueCompletionResult extends CompletionResult {
  /// {@macro value_completion_result}
  ValueCompletionResult()
      : _completions = <String, String?>{},
        super._();

  /// Create a [ValueCompletionResult] with predefined completion suggestions
  ///
  /// Since this can be const, calling "addSuggestion" on instances created
  /// with this constructor may result in runtime exceptions.
  /// Use [CompletionResult.fromMap] instead.
  const ValueCompletionResult._fromMap(this._completions) : super._();

  /// A map of completion suggestions to their descriptions.
  final Map<String, String?> _completions;

  /// Adds an entry to the current pool of suggestions. Overrides any previous
  /// entry with the same [completion].
  void addSuggestion(String completion, [String? description]) {
    _completions[completion] = description;
  }

  @override
  void render(Logger logger, SystemShell shell) {
    for (final entry in _completions.entries) {
      switch (shell) {
        case SystemShell.zsh:
          // On zsh, colon acts as delimitation between a suggestion and its
          // description. Any literal colon should be escaped.
          final suggestion = entry.key.replaceAll(':', r'\:');
          final description = entry.value?.replaceAll(':', r'\:');

          logger.info(
            '$suggestion${description != null ? ':$description' : ''}',
          );
          break;
        case SystemShell.bash:
          logger.info(entry.key);
          break;
      }
    }
  }
}

/// {@template no_completion_result}
/// A [CompletionResult] that indicates that no completion suggestions should be
/// displayed.
/// {@endtemplate}
class EmptyCompletionResult extends CompletionResult {
  /// {@macro no_completion_result}
  const EmptyCompletionResult() : super._();

  @override
  void render(Logger logger, SystemShell shell) {}
}

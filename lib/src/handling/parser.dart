import 'package:args/args.dart';
import 'package:cli_completion/cli_completion.dart';

/// {@template completion_parser}
/// The workhorse of the completion system.
///
/// It is responsible for discovering the possible completions given a
/// [CompletionState].
/// {@endtemplate}
class CompletionParser {
  /// {@macro completion_parser}
  CompletionParser(this._state);

  final CompletionState _state;

  /// Do not complete if there is an argument terminator in the middle of
  /// the sentence
  bool _containsArgumentTerminator() {
    final args = _state.args;
    return args.isNotEmpty && args.take(args.length - 1).contains('--');
  }

  /// Parse the given [CompletionState] into a [CompletionResult] given the
  /// structure of commands and options declared by the CLIs [ArgParser].
  CompletionResult parse() {
    if (_containsArgumentTerminator()) {
      return const CompletionResult.empty();
    }

    // todo(renancaraujo): actually suggest useful things
    return const CompletionResult.fromMap({
      'Brazil': 'A country',
      'USA': 'Another country',
      'Netherlands': 'Guess what: a country',
      'Portugal': 'Yep, a country'
    });
  }
}

import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:meta/meta.dart';

/// {@template completion_state}
/// A description of the state of a user input when requesting completion.
/// {@endtemplate}
///
/// Created when parsing a completion request (when the user hits tab), it
/// contains the information regarding the state of the user input in that
/// moment.
@immutable
class CompletionState extends Equatable {
  /// {@macro completion_state}
  @visibleForTesting
  const CompletionState({
    required this.cword,
    required this.point,
    required this.line,
    required this.args,
  });

  /// The index of the word being completed
  final int cword;

  /// The position of the cursor upon completion request
  final int point;

  /// The user prompt that is being completed
  final String line;

  /// The arguments that were passed by the user so far
  final Iterable<String> args;

  @override
  bool? get stringify => true;

  /// Creates a [CompletionState] from the environment variables set by the
  /// shell script.
  static CompletionState? fromEnvironment([
    Map<String, String>? environmentOverride,
  ]) {
    final environment = environmentOverride ?? Platform.environment;
    final compCword = environment['COMP_CWORD'];
    final compPoint = environment['COMP_POINT'];
    final line = environment['COMP_LINE'];

    if (compCword == null || compPoint == null || line == null) {
      return null;
    }

    final cwordInt = int.tryParse(compCword);
    final pointInt = int.tryParse(compPoint);

    if (cwordInt == null || pointInt == null) {
      return null;
    }

    final args = line.trimLeft().split(' ').skip(1);

    if (pointInt < line.length) {
      // Do not complete when the cursor is not at the end of the line
      return null;
    }

    if (args.isNotEmpty && args.take(args.length - 1).contains('--')) {
      // Do not complete if there is an argument terminator in the middle of
      // the sentence
      return null;
    }

    return CompletionState(
      cword: cwordInt,
      point: pointInt,
      line: line,
      args: args,
    );
  }

  @override
  List<Object?> get props => [cword, point, line, args];
}

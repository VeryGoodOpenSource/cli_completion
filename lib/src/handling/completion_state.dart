import 'dart:io';

import 'package:equatable/equatable.dart';

import 'package:meta/meta.dart';

/// {@template completion_state}
/// A description of the state of a user input when requesting completion.
/// {@endtemplate}
@immutable
class CompletionState extends Equatable {
  /// {@macro completion_state}
  @visibleForTesting
  const CompletionState({
    required this.cword,
    required this.cpoint,
    required this.cline,
    required this.args,
  });

  /// The index of the word being completed
  final int cword;

  /// The position of the cursor upon completion request
  final int cpoint;

  /// The user prompt that is being completed
  final String cline;

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
    final cword = environment['COMP_CWORD'];
    final cpoint = environment['COMP_POINT'];
    final compLine = environment['COMP_LINE'];

    if (cword == null || cpoint == null || compLine == null) {
      return null;
    }

    final cwordInt = int.tryParse(cword);
    final cpointInt = int.tryParse(cpoint);

    if (cwordInt == null || cpointInt == null) {
      return null;
    }

    final args = compLine.trimLeft().split(' ').skip(1);

    if (cpointInt < compLine.length) {
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
      cpoint: cpointInt,
      cline: compLine,
      args: args,
    );
  }

  @override
  List<Object?> get props => [cword, cpoint, cline, args];
}

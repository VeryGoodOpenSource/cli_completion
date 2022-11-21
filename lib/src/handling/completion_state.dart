import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

/// {@template completion_state}
/// A description of the state of a user input when requesting completion.
/// {@endtemplate}
@immutable
class CompletionState extends Equatable {
  const CompletionState._({
    required this.cword,
    required this.cpoint,
    required this.line,
    required this.args,
  });

  /// The index of the word being completed
  final int cword;

  /// The position of the cursor upon completion request
  final int cpoint;

  /// The user prompt that is being completed
  final String line;

  /// The arguments that were passed by the user so far
  final Iterable<String> args;

  @override
  bool? get stringify => true;

  /// Creates a [CompletionState] from the environment variables set by the
  /// shell script.
  static CompletionState? fromEnvironment(
    Logger logger, [
    Map<String, String>? environmentOverride,
  ]) {
    final environment = environmentOverride ?? Platform.environment;
    final cword = environment['COMP_CWORD'];
    final cpoint = environment['COMP_POINT'];
    final line = environment['COMP_LINE'];

    if (cword == null || cpoint == null || line == null) {
      return null;
    }

    final cwordInt = int.tryParse(cword);
    final cpointInt = int.tryParse(cpoint);

    if (cwordInt == null || cpointInt == null) {
      return null;
    }

    final args = line.trimLeft().split(' ').skip(1);

    return CompletionState._(
      cword: cwordInt,
      cpoint: cpointInt,
      line: line,
      args: args,
    );
  }

  @override
  List<Object?> get props => [cword, cpoint, line, args];
}

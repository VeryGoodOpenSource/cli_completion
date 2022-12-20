import 'dart:io';

import 'package:example/src/command_runner.dart';
import 'package:mocktail/mocktail.dart';

import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

Matcher suggests(Map<String, String?> suggestions, {int? whenCursorIsAt}) =>
    CliCompletionMatcher(
      suggestions,
      cursorIndex: whenCursorIsAt,
    );

class CliCompletionMatcher extends CustomMatcher {
  CliCompletionMatcher(
    Map<String, String?> suggestions, {
    this.cursorIndex,
  }) : super(
          'Completes with the expected suggestions',
          'suggestions',
          completion(suggestions),
        );

  final int? cursorIndex;

  @override
  Object? featureValueOf(dynamic line) {
    if (line is! String) {
      throw ArgumentError.value(line, 'line', 'must be a String');
    }

    return runCompletionCommand(line, cursorIndex: cursorIndex);
  }
}

/// Simulate the shell behavior of completing a command line.
Map<String, String> prepareEnvForLineInput(String line, {int? cursorIndex}) {
  final cpoint = cursorIndex ?? line.length;
  var cword = 0;
  line.split(' ').fold(0, (value, element) {
    final total = value + 1 + element.length;
    if (total < cpoint) {
      cword++;
      return total;
    }
    return value;
  });
  return {
    'COMP_LINE': line,
    'COMP_POINT': '$cpoint',
    'COMP_CWORD': '$cword',
  };
}

Future<Map<String, String?>> runCompletionCommand(
  String line, {
  int? cursorIndex,
}) async {
  final map = <String, String?>{};
  final stdout = MockStdout();
  when(() {
    stdout.writeln(any());
  }).thenAnswer((invocation) {
    // Simulate the shell behavior of interpreting the output of the completion.
    final line = invocation.positionalArguments.first as String;

    // A regex that finds all colons, except the ones preceded by backslash
    final res = line.split(RegExp(r'(?<!\\):'));

    final description = res.length > 1 ? res[1] : null;

    map[res.first] = description;
  });

  await IOOverrides.runZoned(
    stdout: () => stdout,
    () async {
      final commandRunner = ExampleCommandRunner()
        ..environmentOverride = {
          'SHELL': '/foo/bar/zsh',
          ...prepareEnvForLineInput(line, cursorIndex: cursorIndex),
        };
      await commandRunner.run(['completion']);
    },
  );

  return map;
}

extension CompletionUtils on Map<String, String?> {
  Map<String, String?> except(String key) {
    return Map.from(this)..remove(key);
  }
}

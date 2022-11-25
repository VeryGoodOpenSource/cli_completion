import 'dart:io';

import 'package:example/src/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';

import 'package:test/test.dart';

class MockStdout extends Mock implements Stdout {}

Map<String, String> prepareEnvForLineInput(
  String line, {
  int? cursorIndex,
}) {
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

@isTest
void testCompletion(
  String description, {
  required String forLine,
  required Map<String, String?> suggests,
  dynamic tags,
}) {
  test(
    description,
    () async {
      await expectLater(runCompletionCommand(forLine), completion(suggests));
    },
    tags: tags,
  );
}

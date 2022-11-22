import 'package:cli_completion/cli_completion.dart';
import 'package:example/src/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';

import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

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
  final completionLogger = MockLogger();
  final map = <String, String?>{};
  when(() {
    completionLogger.info(any());
  }).thenAnswer((invocation) {
    final line = invocation.positionalArguments.first as String;

    // a regex that finds all colons, except the ones preceded by backslash
    final res = line.split(RegExp(r'(?<!\\):'));

    final description = res.length > 1 ? res[1] : null;

    map[res.first] = description;
  });
  final commandRunner = ExampleCommandRunner()
    ..completionLogger = completionLogger
    ..environmentOverride = {
      'SHELL': '/foo/bar/zsh',
      ...prepareEnvForLineInput(line, cursorIndex: cursorIndex),
    };
  await commandRunner.run(['completion']);

  return map;
}

String mapToCompletion(Map<String, String?> map) {
  final logger = MockLogger();
  final output = StringBuffer();
  when(() {
    logger.info(any());
  }).thenAnswer((invocation) {
    output.writeln(invocation.positionalArguments.first);
  });
  CompletionResult.fromMap(map).render(logger, SystemShell.zsh);
  return output.toString();
}

@isTest
void testCompletion(
  String description, {
  required String forLine,
  required Map<String, String?> suggests,
  String? skip,
}) {
  test(
    description,
    () async {
      await expectLater(runCompletionCommand(forLine), completion(suggests));
    },
    skip: skip,
  );
}

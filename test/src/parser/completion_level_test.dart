import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/parser.dart';
import 'package:test/test.dart';

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner() : super('test', 'Test command runner') {
    argParser
      ..addOption('rootFlag')
      ..addCommand(
        'fakesubcommand',
        ArgParser()..addFlag('fakeSubcommandFlag'),
      );
    final subCommand = _TestCommand(
      name: 'subcommand',
      description: 'subcommand level 1',
    );
    addCommand(subCommand);
    subCommand.argParser
      ..addFlag('level1Flag')
      ..addMultiOption('level1Option');

    final subSubCommand = _TestCommand(
      name: 'subsubcommand',
      description: 'subcommand level 2',
    );
    subCommand.addSubcommand(subSubCommand);
    subSubCommand.argParser
      ..addFlag('level2Flag')
      ..addOption(
        'level2Option',
        mandatory: true,
      );

    final subSubSubCommand = _TestCommand(
      name: 'subsubsubcommand',
      description: 'subcommand level 2',
    );
    subSubCommand.addSubcommand(subSubSubCommand);
  }
}

class _TestCommand extends Command<int> {
  _TestCommand({
    required this.name,
    required this.description,
  });

  @override
  final String description;

  @override
  final String name;
}

void main() {
  group('CompletionLevel', () {
    group('find', () {
      test(
        'gets completion level from the innermost aspet',
        () {
          final commanrRunner = _TestCompletionCommandRunner();
          final args = '--rootFlag '
                  'subcommand  --level1Flag '
                  'subsubcommand  --level2Flag'
              .split(' ');

          final completionLevel = CompletionLevel.find(
            args,
            commanrRunner.argParser,
            commanrRunner.commands,
          );

          expect(completionLevel, isNotNull);
          completionLevel!;

          expect(completionLevel.rawArgs, [
            '',
            '--level2Flag',
          ]);

          expect(
            completionLevel.parsedOptions,
            isA<ArgResults>().having(
              (results) => results.wasParsed('level2Flag'),
              'parsed level2Flag',
              true,
            ),
          );

          expect(
            completionLevel.visibleOptions,
            isA<List<Option>>()
                .having(
                  (list) => list.length,
                  'available options in the last level',
                  2,
                )
                .having(
                  (list) => list[0].name,
                  'first option in the last level',
                  'help',
                )
                .having(
                  (list) => list[1].name,
                  'second option in the last level',
                  'level2Option',
                ),
          );

          expect(
            completionLevel.visibleSubcommands,
            isA<List<Command<dynamic>>>()
                .having(
                  (list) => list.length,
                  'available sub commands in the last level',
                  1,
                )
                .having(
                  (list) => list.single.name,
                  'sub command in the last level',
                  'subsubsubcommand',
                ),
          );
        },
      );

      test(
        'finds level when subcommand is added via "ArgParser.addCommand"',
        () {
          final commanrRunner = _TestCompletionCommandRunner();
          final args = '--rootFlag '
                  'fakesubcommand --fakeSubcommandFlag'
              .split(' ');

          final completionLevel = CompletionLevel.find(
            args,
            commanrRunner.argParser,
            commanrRunner.commands,
          );

          expect(completionLevel, isNotNull);
          completionLevel!;

          expect(completionLevel.rawArgs, [
            '--fakeSubcommandFlag',
          ]);
        },
      );
    });
  });
}

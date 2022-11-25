import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/completion_level.dart';
import 'package:test/test.dart';

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner() : super('test', 'Test command runner') {
    argParser
      ..addOption(
        'rootOption',
        mandatory: true, //  this should be disregarded
      )
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
    subSubCommand.argParser.addFlag('level2Flag');

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
          final args = '--rootOption  valueForOption  '
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
                  'level2Flag',
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
          final args = '--rootOption valueForOption '
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

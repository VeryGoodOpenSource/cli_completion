import 'package:args/args.dart';
import 'package:cli_completion/src/handling/arg_parser_extension.dart';
import 'package:test/test.dart';

void main() {
  group('ArgParserExtension', () {
    group('tryParseCommandsOnly', () {
      final rootArgParser = ArgParser()
        ..addFlag('rootFlag')
        ..addOption(
          'rootOption',
          mandatory: true, //  this should be disregarded
        );
      final argParserLevel1 = ArgParser()
        ..addFlag('level1Flag')
        ..addOption('level1Option');
      rootArgParser.addCommand('subcommand', argParserLevel1);
      final argParserLevel2 = ArgParser()
        ..addFlag('level2Flag')
        ..addMultiOption('level2Option');
      argParserLevel1.addCommand('subcommand2', argParserLevel2);

      test('parses commands only disregarding strict option rules', () {
        final args = '--rootFlag subcommand '
                '--level1Option option '
                'subcommand2 --level2Flag'
            .split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNotNull);
        results!;

        expect(results.name, null);
        expect(
          results.arguments,
          <String>[
            '--rootFlag',
            'subcommand',
            '--level1Option',
            'option',
            'subcommand2',
            '--level2Flag',
          ],
        );
        expect(
          results.command,
          isA<ArgResults>()
              .having(
                (results) => results.name,
                'level 1 name',
                'subcommand',
              )
              .having(
                (results) => results.command,
                'level2',
                isA<ArgResults>()
                    .having(
                      (results) => results.name,
                      'level 2 name',
                      'subcommand2',
                    )
                    .having(
                      (results) => results.command,
                      'level 3 doesnt exist',
                      isNull,
                    ),
              ),
        );

        expect(results.options, <String>{'rootFlag'});
      });

      test('returns null when args make no sense', () {
        final args = '--rootFlag subcommand oh my god subcommand2'.split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNull);
      });
    });
  });
}

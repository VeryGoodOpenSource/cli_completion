import 'package:args/args.dart';
import 'package:cli_completion/src/handling/arg_parser_extension.dart';
import 'package:test/test.dart';

void main() {
  group('ArgParserExtension', () {
    group('tryParseCommandsOnly', () {
      final rootArgParser = ArgParser()
        ..addOption(
          'rootOption',
          mandatory: true, //  this should be disregarded
        );
      final subArgPasrser = ArgParser();
      rootArgParser.addCommand('subcommand', subArgPasrser);

      test('parses commands only disregarding strict option rules', () {
        final args = '--rootOption value subcommand'.split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNotNull);
        results!;

        expect(results.name, null);
        expect(
          results.arguments,
          <String>[
            '--rootOption',
            'value',
            'subcommand',
          ],
        );
        expect(
          results.command,
          isA<ArgResults>().having(
            (results) => results.name,
            'level 1 name',
            'subcommand',
          ),
        );

        expect(results.options, <String>{'rootOption'});
      });

      test('returns null when args make no sense', () {
        final args = '--rootFlag oh my god subcommand'.split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNull);
      });

      test('returns null when args make no sense', () {
        final args = '         subcommand'.split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNotNull);
      });
    });
  });
}

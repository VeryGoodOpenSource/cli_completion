import 'package:args/args.dart';
import 'package:cli_completion/src/parser/arg_parser_extension.dart';
import 'package:test/test.dart';

void main() {
  group('isOption', () {
    test('detects options', () {
      expect(isOption('--'), isTrue);
      expect(isOption('--o'), isTrue);
      expect(isOption('--option'), isTrue);
      expect(isOption('--opt1on'), isTrue);
      expect(isOption('--opTion'), isTrue);
      expect(isOption('--option="value"'), isTrue);
      expect(isOption('--option=value'), isTrue);
    });
    test('discards not options', () {
      expect(isOption('-'), isFalse);
      expect(isOption('-o'), isFalse);
      expect(isOption('cake'), isFalse);
      expect(isOption('-- wow'), isFalse);
    });
  });
  group('isAbbr', () {
    test('detects abbreviations', () {
      expect(isAbbr('-'), isTrue);
      expect(isAbbr('-y'), isTrue);
      expect(isAbbr('-yay'), isTrue);
    });
    test('discards not abbreviations', () {
      expect(isAbbr('--'), isFalse);
      expect(isAbbr('--option'), isFalse);
      expect(isAbbr('cake'), isFalse);
      expect(isAbbr('- wow'), isFalse);
    });
  });
  group('ArgParserExtension', () {
    group('tryParseCommandsOnly', () {
      final rootArgParser = ArgParser()..addFlag('rootFlag');
      final subArgPasrser = ArgParser();
      rootArgParser.addCommand('subcommand', subArgPasrser);

      test('parses commands only disregarding all option rules', () {
        final args = '--rootFlag subcommand'.split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNotNull);
        results!;

        expect(results.name, null);
        expect(
          results.arguments,
          <String>[
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

        expect(results.options, <String>{});
      });

      test('returns null when args make no sense', () {
        final args = '--rootFlag oh my god subcommand'.split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNull);
      });

      test('parses args with leading spaces', () {
        final args = '         subcommand'.split(' ');
        final results = rootArgParser.tryParseCommandsOnly(args);

        expect(results, isNotNull);
      });
    });
    group('findValidOptions', () {
      final argParser = ArgParser()
        ..addFlag(
          'flag',
          abbr: 'f',
          aliases: ['flagalias'],
        )
        ..addOption('mandatoryOption', mandatory: true)
        ..addMultiOption('multiOption', allowed: ['a', 'b', 'c'])
        ..addCommand('subcommand', ArgParser());

      group('parses the minimal amount of valid options', () {
        test('options values and abbr', () {
          final args = '-f --mandatoryOption="yay" --multiOption'.split(' ');
          final results = argParser.findValidOptions(args);

          expect(
            results,
            isA<ArgResults>()
                .having((res) => res.wasParsed('flag'), 'parsed flag', true)
                .having(
                  (res) => res.wasParsed('mandatoryOption'),
                  'parsed mandatoryOption',
                  true,
                )
                .having(
                  (res) => res.wasParsed('multiOption'),
                  'parsed multiOption',
                  false,
                ),
          );
        });
        test('alias', () {
          final args = '--flagalias --mandatoryOption'.split(' ');
          final results = argParser.findValidOptions(args);

          expect(
            results,
            isA<ArgResults>()
                .having((res) => res.wasParsed('flag'), 'parsed flag', true)
                .having(
                  (res) => res.wasParsed('mandatoryOption'),
                  'parsed mandatoryOption',
                  false,
                )
                .having(
                  (res) => res.wasParsed('multiOption'),
                  'parsed multiOption',
                  false,
                ),
          );
        });
      });
      test('returns null when there is no valid options', () {
        final args = '--extraneousOption --flag'.split(' ');
        final results = argParser.findValidOptions(args);

        expect(results, isNull);
      });
      test('disregard sub command', () {
        final args = '--flag subcommand'.split(' ');
        final results = argParser.findValidOptions(args);

        expect(
          results,
          isA<ArgResults>()
              .having((res) => res.wasParsed('flag'), 'parsed flag', true)
              .having(
                (res) => res.wasParsed('mandatoryOption'),
                'parsed mandatoryOption',
                false,
              )
              .having(
                (res) => res.wasParsed('multiOption'),
                'parsed multiOption',
                false,
              )
              .having((res) => res.command, 'command', isNull),
        );
      });
    });
  });
}

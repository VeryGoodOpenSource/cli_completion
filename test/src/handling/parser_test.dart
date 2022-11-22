import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/src/handling/parser.dart';
import 'package:test/test.dart';

CompletionState stateForLine(
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
  final environment = <String, String>{
    'COMP_LINE': line,
    'COMP_POINT': '$cpoint',
    'COMP_CWORD': '$cword',
  };
  return CompletionState.fromEnvironment(environment)!;
}

void main() {
  group('CompletionParser', () {
    test('can be instantiated', () {
      final state = stateForLine('foo bar --p');

      expect(() => CompletionParser(state), returnsNormally);
    });

    group('parse', () {
      test('returns suggestions', () {
        final state = stateForLine('foo bar --p');
        final parser = CompletionParser(state);
        final result = parser.parse();

        expect(
          result,
          equals(
            const CompletionResult.fromMap(
              {
                'Brazil': 'A country',
                'USA': 'Another country',
                'Netherlands': 'Guess what: a country',
                'Portugal': 'Yep, a country',
              },
            ),
          ),
        );
      });

      group('argument terminator', () {
        test('returns nothing when finds argument terminator', () {
          final state = stateForLine('foo bar --p -- something');
          final parser = CompletionParser(state);
          final result = parser.parse();

          expect(result, equals(const EmptyCompletionResult()));
        });
      });
    });
  });
}

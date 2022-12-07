import 'package:cli_completion/parse_completion.dart';
import 'package:test/test.dart';

void main() {
  group('CompletionState', () {
    group('fromEnvironment', () {
      test('returns a valid completion state', () {
        final environment = <String, String>{
          'COMP_LINE': 'example_cli some_command --discrete foo',
          'COMP_POINT': '39',
          'COMP_CWORD': '3'
        };
        final state = CompletionState.fromEnvironment(environment);
        expect(state, isNotNull);
        expect(state!.cword, 3);
        expect(state.point, 39);
        expect(state.line, 'example_cli some_command --discrete foo');
        expect(state.args, [
          'some_command',
          '--discrete',
          'foo',
        ]);
      });

      test('equality', () {
        final environment = <String, String>{
          'COMP_LINE': 'example_cli some_command --discrete foo',
          'COMP_POINT': '39',
          'COMP_CWORD': '3'
        };
        final state = CompletionState.fromEnvironment(environment);
        final state2 = CompletionState.fromEnvironment(environment);
        expect(state, equals(state2));
        expect(
          state.toString(),
          'CompletionState('
          '3, '
          '39, '
          'example_cli some_command --discrete foo, '
          '(some_command, --discrete, foo))',
        );
      });

      test('returns null when no environment variables are set', () {
        expect(CompletionState.fromEnvironment(), isNull);
      });

      test('returns null when only COMP_LINE is set', () {
        final environment = <String, String>{
          'COMP_LINE': 'example_cli some_command --discrete foo'
        };
        expect(
          CompletionState.fromEnvironment(environment),
          isNull,
        );
      });

      test('returns null when only COMP_POINT is set', () {
        final environment = <String, String>{'COMP_POINT': '12'};
        expect(
          CompletionState.fromEnvironment(environment),
          isNull,
        );
      });

      test('returns null when only COMP_CWORD is set', () {
        final environment = <String, String>{'COMP_CWORD': '2'};
        expect(
          CompletionState.fromEnvironment(environment),
          isNull,
        );
      });

      test('returns null when COMP_CWORD or COMP_POINT are not ints', () {
        final environment = <String, String>{
          'COMP_CWORD': 'sdasdas',
          'COMP_POINT': 'asdasddd',
        };
        expect(
          CompletionState.fromEnvironment(environment),
          isNull,
        );
      });

      test('returns null when COMP_POINT is not at the end of the line', () {
        final environment = <String, String>{
          'COMP_LINE': 'example_cli some_command --discrete foo',
          'COMP_POINT': '0',
          'COMP_CWORD': '0'
        };
        expect(
          CompletionState.fromEnvironment(environment),
          isNull,
        );
      });

      test('returns null when there an argument terminator', () {
        final environment = <String, String>{
          'COMP_LINE': 'example_cli some_command -- --discrete foo',
          'COMP_POINT': '42',
          'COMP_CWORD': '4'
        };
        expect(
          CompletionState.fromEnvironment(environment),
          isNull,
        );
      });
    });
  });
}

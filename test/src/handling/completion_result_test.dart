import 'package:cli_completion/cli_completion.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  group('CompletionResult', () {
    group('fromMap', () {
      test('renders predefined suggestions on zsh', () {
        const completionResult = CompletionResult.fromMap({
          'suggestion1': 'description1',
          'suggestion2': 'description2',
          'suggestion3': null,
          'suggestion4': 'description4',
        });

        final logger = MockLogger();

        final output = StringBuffer();
        when(() {
          logger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        completionResult.render(logger, SystemShell.zsh);

        expect(output.toString(), '''
suggestion1:description1
suggestion2:description2
suggestion3
suggestion4:description4
''');
      });

      test('renders predefined suggestions on bash', () {
        const completionResult = CompletionResult.fromMap({
          'suggestion1': 'description1',
          'suggestion2': 'description2',
          'suggestion3': null,
          'suggestion4': 'description4',
        });

        final logger = MockLogger();

        final output = StringBuffer();
        when(() {
          logger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        completionResult.render(logger, SystemShell.bash);

        expect(output.toString(), '''
suggestion1
suggestion2
suggestion3
suggestion4
''');
      });
    });
  });

  group('ValueCompletionResult', () {
    test('can be instantiated without any parameters', () {
      expect(ValueCompletionResult.new, returnsNormally);
    });

    test('renders suggestions on zsh', () {
      final completionResult = ValueCompletionResult()
        ..addSuggestion('suggestion1', 'description1')
        ..addSuggestion('suggestion2', 'description2')
        ..addSuggestion('suggestion3')
        ..addSuggestion('suggestion4', 'description4');

      final logger = MockLogger();

      final output = StringBuffer();
      when(() {
        logger.info(any());
      }).thenAnswer((invocation) {
        output.writeln(invocation.positionalArguments.first);
      });

      completionResult.render(logger, SystemShell.zsh);

      expect(output.toString(), '''
suggestion1:description1
suggestion2:description2
suggestion3
suggestion4:description4
''');
    });

    test('renders suggestions on bash', () {
      final completionResult = ValueCompletionResult()
        ..addSuggestion('suggestion1', 'description1')
        ..addSuggestion('suggestion2', 'description2')
        ..addSuggestion('suggestion3')
        ..addSuggestion('suggestion4', 'description4');

      final logger = MockLogger();
      final output = StringBuffer();
      when(() {
        logger.info(any());
      }).thenAnswer((invocation) {
        output.writeln(invocation.positionalArguments.first);
      });

      completionResult.render(logger, SystemShell.bash);

      expect(output.toString(), '''
suggestion1
suggestion2
suggestion3
suggestion4
''');
    });
  });

  group('EmptyCompletionResult', () {
    test('can be instantiated without any parameters', () {
      expect(EmptyCompletionResult.new, returnsNormally);
    });

    test('renders nothing', () {
      const completionResult = EmptyCompletionResult();

      final logger = MockLogger();

      final output = StringBuffer();
      when(() {
        logger.info(any());
      }).thenAnswer((invocation) {
        output.writeln(invocation.positionalArguments.first);
      });

      completionResult.render(logger, SystemShell.zsh);

      expect(output.toString(), '');

      completionResult.render(logger, SystemShell.bash);

      expect(output.toString(), '');
    });
  });
}

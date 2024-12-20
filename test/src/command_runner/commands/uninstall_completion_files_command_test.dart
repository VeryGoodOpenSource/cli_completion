import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/installer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockCompletionInstallation extends Mock
    implements CompletionInstallation {}

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner() : super('test', 'Test command runner');

  @override
  // Override acceptable for test files
  // ignore: overridden_fields
  final Logger completionInstallationLogger = _MockLogger();

  @override
  final CompletionInstallation completionInstallation =
      _MockCompletionInstallation();
}

void main() {
  group('$UnistallCompletionFilesCommand', () {
    late _TestCompletionCommandRunner commandRunner;

    setUp(() {
      commandRunner = _TestCompletionCommandRunner();
    });

    test('can be instantiated', () {
      expect(UnistallCompletionFilesCommand<int>(), isNotNull);
    });

    test('is hidden', () {
      expect(UnistallCompletionFilesCommand<int>().hidden, isTrue);
    });

    test('description', () {
      expect(
        UnistallCompletionFilesCommand<int>().description,
        'Manually uninstalls completion files for the current shell.',
      );
    });

    group('uninstalls completion files', () {
      test('when normal', () async {
        await commandRunner.run(['uninstall-completion-files']);

        verify(
          () => commandRunner.completionInstallationLogger.level = Level.info,
        ).called(1);
        verify(
          () => commandRunner.completionInstallation
              .uninstall(commandRunner.executableName),
        ).called(1);
      });

      test('when verbose', () async {
        await commandRunner.run(['uninstall-completion-files', '--verbose']);

        verify(
          () {
            return commandRunner.completionInstallationLogger.level =
                Level.verbose;
          },
        ).called(1);
        verify(
          () => commandRunner.completionInstallation
              .uninstall(commandRunner.executableName),
        ).called(1);
      });
    });
  });
}

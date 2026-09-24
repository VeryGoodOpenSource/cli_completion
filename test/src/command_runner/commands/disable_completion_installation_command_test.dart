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
  group('DisableCompletionInstallationCommand', () {
    late _TestCompletionCommandRunner commandRunner;

    setUp(() {
      commandRunner = _TestCompletionCommandRunner();
    });

    test('can be instantiated', () {
      expect(DisableCompletionInstallationCommand<int>(), isNotNull);
    });

    test('is hidden', () {
      expect(DisableCompletionInstallationCommand<int>().hidden, isTrue);
    });

    test('description', () {
      expect(
        DisableCompletionInstallationCommand<int>().description,
        'Disables the automatic installation of completion files.',
      );
    });

    test('disables the automatic installation', () async {
      await commandRunner.run(['disable-completion-auto-install']);

      verify(
        () => commandRunner.completionInstallation.setAutoInstallEnabled(
          enabled: false,
        ),
      ).called(1);
    });

    test('logs an error when an unknown exception happens', () async {
      when(
        () => commandRunner.completionInstallation.setAutoInstallEnabled(
          enabled: any(named: 'enabled'),
        ),
      ).thenThrow(Exception('oops'));

      await commandRunner.run(['disable-completion-auto-install']);

      verify(
        () => commandRunner.completionInstallationLogger.err(any()),
      ).called(1);
    });
  });
}

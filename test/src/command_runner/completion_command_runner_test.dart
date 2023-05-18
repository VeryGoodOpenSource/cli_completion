import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:cli_completion/installer.dart';
import 'package:cli_completion/parser.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

class MockCompletionInstallation extends Mock
    implements CompletionInstallation {}

class _TestCompletionCommandRunner extends CompletionCommandRunner<int> {
  _TestCompletionCommandRunner() : super('test', 'Test command runner');

  @override
  bool enableAutoInstall = true;

  @override
  // ignore: overridden_fields
  final Logger completionLogger = MockLogger();

  @override
  // ignore: overridden_fields
  final Logger completionInstallationLogger = MockLogger();

  CompletionInstallation? mockCompletionInstallation;

  @override
  CompletionInstallation get completionInstallation =>
      mockCompletionInstallation ?? super.completionInstallation;
}

class _TestUserCommand extends Command<int> {
  @override
  String get description => 'some command';

  @override
  String get name => 'ahoy';

  @override
  int run() {
    return 0;
  }
}

class _TestCompletionResult extends CompletionResult {
  const _TestCompletionResult(this._completions);

  final Map<String, String?> _completions;

  @override
  Map<String, String?> get completions => _completions;
}

void main() {
  setUpAll(() {
    registerFallbackValue(Level.error);
  });

  group('CompletionCommandRunner', () {
    test('can be instantiated', () {
      final commandRunner = _TestCompletionCommandRunner();
      expect(commandRunner, isNotNull);
    });

    test('usage message omits reserved commands', () {
      final commandRunner = _TestCompletionCommandRunner()
        ..addCommand(_TestUserCommand());

      expect(
        commandRunner.usage,
        contains('ahoy'),
      );
      expect(
        commandRunner.usage,
        isNot(contains('install-completion-files')),
      );
      expect(
        commandRunner.usage,
        isNot(contains('completion')),
      );
    });

    group('completionInstallation', () {
      // test if it gets one with the current system shell
      test('creates one with the given system shell', () {
        final commandRunner = _TestCompletionCommandRunner()
          ..environmentOverride = {
            'SHELL': '/foo/bar/zsh',
          };
        expect(
          commandRunner.completionInstallation,
          isA<CompletionInstallation>().having(
            (e) => e.configuration?.shell,
            'chosen shell',
            equals(SystemShell.zsh),
          ),
        );
      });
    });

    test('Adds default commands', () {
      final commandRunner = _TestCompletionCommandRunner();
      expect(
        commandRunner.commands.keys,
        containsAll([
          'completion',
          'install-completion-files',
        ]),
      );
    });

    group('auto install', () {
      test('Tries to install completion files on test subcommand', () async {
        final commandRunner = _TestCompletionCommandRunner()
          ..addCommand(_TestUserCommand())
          ..mockCompletionInstallation = MockCompletionInstallation();

        await commandRunner.run(['ahoy']);

        verify(() => commandRunner.completionInstallation.install('test'))
            .called(1);

        verify(
          () => commandRunner.completionInstallationLogger.level = Level.error,
        ).called(1);
      });

      test('does not auto install when it is disabled', () async {
        final commandRunner = _TestCompletionCommandRunner()
          ..enableAutoInstall = false
          ..addCommand(_TestUserCommand())
          ..mockCompletionInstallation = MockCompletionInstallation();

        await commandRunner.run(['ahoy']);

        verifyNever(() => commandRunner.completionInstallation.install('test'));

        verifyNever(
          () => commandRunner.completionInstallationLogger.level = any(),
        );
      });
    });

    test(
      'When it throws CompletionInstallationException, it logs as a warning',
      () async {
        final commandRunner = _TestCompletionCommandRunner()
          ..addCommand(_TestUserCommand())
          ..mockCompletionInstallation = MockCompletionInstallation();

        when(
          () => commandRunner.completionInstallation.install('test'),
        ).thenThrow(
          CompletionInstallationException(message: 'oops', rootCommand: 'test'),
        );

        await commandRunner.run(['ahoy']);

        verify(() => commandRunner.completionInstallationLogger.warn(any()))
            .called(1);
      },
    );

    test('When an unknown exception happens during a install, it logs as error',
        () async {
      final commandRunner = _TestCompletionCommandRunner()
        ..addCommand(_TestUserCommand())
        ..mockCompletionInstallation = MockCompletionInstallation();

      when(
        () => commandRunner.completionInstallation.install('test'),
      ).thenThrow(Exception('oops'));

      await commandRunner.run(['ahoy']);

      verify(() => commandRunner.completionInstallationLogger.err(any()))
          .called(1);
    });

    group('tryUninstallCompletionFiles', () {
      test(
        'logs a warning wen it throws $CompletionUninstallationException',
        () async {
          final commandRunner = _TestCompletionCommandRunner()
            ..mockCompletionInstallation = MockCompletionInstallation();

          when(
            () => commandRunner.completionInstallation.uninstall('test'),
          ).thenThrow(
            CompletionUninstallationException(
              message: 'oops',
              rootCommand: 'test',
            ),
          );

          commandRunner.tryUninstallCompletionFiles(Level.verbose);

          verify(() => commandRunner.completionInstallationLogger.warn(any()))
              .called(1);
        },
      );

      test(
        'logs an error when an unknown exception happens during a install',
        () async {
          final commandRunner = _TestCompletionCommandRunner()
            ..mockCompletionInstallation = MockCompletionInstallation();

          when(
            () => commandRunner.completionInstallation.uninstall('test'),
          ).thenThrow(Exception('oops'));

          commandRunner.tryUninstallCompletionFiles(Level.verbose);

          verify(() => commandRunner.completionInstallationLogger.err(any()))
              .called(1);
        },
      );
    });

    group('renderCompletionResult', () {
      test('renders predefined suggestions on zsh', () {
        const completionResult = _TestCompletionResult({
          'suggestion1': 'description1',
          'suggestion2': 'description2',
          'suggestion3': null,
          'suggestion4': 'description4',
        });

        final commandRunner = _TestCompletionCommandRunner()
          ..environmentOverride = {
            'SHELL': '/foo/bar/zsh',
          };

        final output = StringBuffer();
        when(() {
          commandRunner.completionLogger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        commandRunner.renderCompletionResult(completionResult);

        expect(output.toString(), '''
suggestion1:description1
suggestion2:description2
suggestion3
suggestion4:description4
''');
      });

      test('renders predefined suggestions on bash', () {
        const completionResult = _TestCompletionResult({
          'suggestion1': 'description1',
          'suggestion2': 'description2',
          'suggestion3': null,
          'suggestion4': 'description4',
        });

        final commandRunner = _TestCompletionCommandRunner()
          ..environmentOverride = {
            'SHELL': '/foo/bar/bash',
          };

        final output = StringBuffer();
        when(() {
          commandRunner.completionLogger.info(any());
        }).thenAnswer((invocation) {
          output.writeln(invocation.positionalArguments.first);
        });

        commandRunner.renderCompletionResult(completionResult);

        expect(output.toString(), '''
suggestion1
suggestion2
suggestion3
suggestion4
''');
      });
    });
  });
}

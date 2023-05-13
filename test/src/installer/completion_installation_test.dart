import 'dart:io';

import 'package:cli_completion/installer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockLogger extends Mock implements Logger {}

void main() {
  late Logger logger;
  late Directory tempDir;

  setUp(() {
    logger = MockLogger();
    when(() => logger.level).thenReturn(Level.quiet);
    tempDir = Directory.systemTemp.createTempSync();
  });

  group('CompletionInstallation', () {
    group('fromSystemShell', () {
      test('bash', () {
        final installation = CompletionInstallation.fromSystemShell(
          systemShell: SystemShell.bash,
          logger: logger,
        );
        expect(installation.configuration?.shell, SystemShell.bash);
      });

      test('zsh', () {
        final installation = CompletionInstallation.fromSystemShell(
          systemShell: SystemShell.zsh,
          logger: logger,
        );
        expect(installation.configuration?.shell, SystemShell.zsh);
      });

      test('proxies overrides', () {
        final installation = CompletionInstallation.fromSystemShell(
          systemShell: SystemShell.zsh,
          logger: logger,
          isWindowsOverride: true,
          environmentOverride: {'HOME': '/foo/bar'},
        );
        expect(installation.isWindows, true);
        expect(installation.environment, {'HOME': '/foo/bar'});

        final installation2 = CompletionInstallation.fromSystemShell(
          systemShell: SystemShell.zsh,
          logger: logger,
          isWindowsOverride: false,
          environmentOverride: {'HOME': '/foo/bar'},
        );
        expect(installation2.isWindows, false);
      });
    });

    group('completionConfigDir', () {
      test('gets config dir location on windows', () {
        final installation = CompletionInstallation(
          configuration: zshConfiguration,
          logger: logger,
          isWindows: true,
          environment: {
            'LOCALAPPDATA': tempDir.path,
          },
        );

        expect(
          installation.completionConfigDir.path,
          path.join(tempDir.path, 'DartCLICompletion'),
        );
      });

      group('gets config dir location on posix', () {
        test('respects XDG home', () {
          final installation = CompletionInstallation(
            configuration: zshConfiguration,
            logger: logger,
            isWindows: false,
            environment: {
              'XDG_CONFIG_HOME': tempDir.path,
              'HOME': 'ooohnoooo',
            },
          );

          expect(
            installation.completionConfigDir.path,
            path.join(tempDir.path, '.dart-cli-completion'),
          );
        });

        test('defaults to home', () {
          final installation = CompletionInstallation(
            configuration: zshConfiguration,
            logger: logger,
            isWindows: false,
            environment: {
              'HOME': tempDir.path,
            },
          );

          expect(
            installation.completionConfigDir.path,
            path.join(tempDir.path, '.dart-cli-completion'),
          );
        });
      });
    });

    group('install', () {
      test('createCompletionConfigDir', () {
        final installation = CompletionInstallation(
          configuration: zshConfiguration,
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDir.path,
          },
        );

        expect(installation.completionConfigDir.existsSync(), false);

        installation.createCompletionConfigDir();

        expect(installation.completionConfigDir.existsSync(), true);

        verifyNever(
          () => logger.warn(
            any(
              that: endsWith(
                'directory was already found.',
              ),
            ),
          ),
        );

        installation.createCompletionConfigDir();

        verify(
          () => logger.warn(
            any(
              that: endsWith(
                'directory was already found.',
              ),
            ),
          ),
        ).called(1);
      });

      test('writeCompletionScriptForCommand', () {
        final installation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDir.path,
          },
          configuration: zshConfiguration,
        );

        final configDir = installation.completionConfigDir;

        final configFile = File(path.join(configDir.path, 'very_good.zsh'));

        expect(configFile.existsSync(), false);

        installation.createCompletionConfigDir();
        var result = installation.writeCompletionScriptForCommand('very_good');

        expect(configFile.existsSync(), true);
        expect(result, true);

        expect(
          configFile.readAsStringSync(),
          zshConfiguration.scriptTemplate('very_good'),
        );

        verifyNever(
          () => logger.warn(
            any(
              that: startsWith(
                'A script file for very_good was already found on ',
              ),
            ),
          ),
        );

        result = installation.writeCompletionScriptForCommand('very_good');

        expect(result, false);

        verify(
          () => logger.warn(
            any(
              that: startsWith(
                'A script file for very_good was already found on ',
              ),
            ),
          ),
        ).called(1);
      });

      test('writeCompletionConfigForShell', () {
        final installation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDir.path,
          },
          configuration: zshConfiguration,
        );

        final configDir = installation.completionConfigDir;

        final configFile = File(path.join(configDir.path, 'zsh-config.zsh'));

        expect(configFile.existsSync(), false);

        installation
          ..createCompletionConfigDir()
          ..writeCompletionConfigForShell('very_good');

        expect(configFile.existsSync(), true);

        // ignore: leading_newlines_in_multiline_strings
        expect(configFile.readAsStringSync(), '''
\n## [very_good]
## Completion config for "very_good"
[[ -f ${configDir.path}/very_good.zsh ]] && . ${configDir.path}/very_good.zsh || true
## [/very_good]

''');

        verify(
          () => logger.info(
            any(
              that: startsWith(
                'No file found at ${configFile.path}',
              ),
            ),
          ),
        ).called(1);

        installation.writeCompletionConfigForShell('very_good');

        verify(
          () => logger.warn(
            any(
              that: startsWith(
                'A config entry for very_good was already found on',
              ),
            ),
          ),
        ).called(1);
      });

      test('writeToShellConfigFile', () {
        final installation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDir.path,
          },
          configuration: zshConfiguration,
        );

        final configDir = installation.completionConfigDir;

        // When the rc file cannot be found, throw an exception
        expect(
          () => installation.writeToShellConfigFile('very_good'),
          throwsA(
            isA<CompletionInstallationException>().having(
              (e) => e.message,
              'message',
              'No configuration file found at '
                  '${path.join(tempDir.path, '.zshrc')}',
            ),
          ),
        );

        final rcFile = File(path.join(tempDir.path, '.zshrc'))..createSync();

        installation.writeToShellConfigFile('very_good');

        // ignore: leading_newlines_in_multiline_strings
        expect(rcFile.readAsStringSync(), '''
\n## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f ${configDir.path}/zsh-config.zsh ]] && . ${configDir.path}/zsh-config.zsh || true
## [/Completion]

''');
      });

      test(
        'installing completion for a command when it is already installed',
        () {
          final installation = CompletionInstallation(
            logger: logger,
            isWindows: false,
            environment: {
              'HOME': tempDir.path,
            },
            configuration: zshConfiguration,
          );

          File(path.join(tempDir.path, '.zshrc')).createSync();

          installation.install('very_good');

          verify(() => logger.level = Level.info).called(1);

          verify(
            () => logger.info(
              '\n'
              'Completion files installed. To enable completion, run the '
              'following command in your shell:\n'
              'source ${path.join(tempDir.path, '.zshrc')}\n',
            ),
          ).called(1);

          reset(logger);

          // install again
          installation.install('very_good');

          verify(
            () => logger.warn(
              'A ${installation.completionConfigDir.path} directory was already'
              ' found.',
            ),
          ).called(1);
          verify(
            () => logger.warn(
              'A script file for very_good was already found on ${path.join(
                installation.completionConfigDir.path,
                'very_good.zsh',
              )}.',
            ),
          ).called(1);
          verify(
            () => logger.warn(
              'A config entry for very_good was already found on '
              '${path.join(
                installation.completionConfigDir.path,
                'zsh-config.zsh',
              )}.',
            ),
          ).called(1);

          verify(
            () => logger.warn(
              'A completion config entry was already found on '
              '${path.join(tempDir.path, '.zshrc')}.',
            ),
          ).called(1);

          verifyNever(() => logger.level = Level.debug);

          verifyNever(
            () => logger.info(
              '\n'
              'Completion files installed. To enable completion, run the '
              'following command in your shell:\n'
              'source ${path.join(tempDir.path, '.zshrc')}\n',
            ),
          );
        },
      );

      test(
        'installing completion for two different commands',
        () {
          final zshInstallation = CompletionInstallation(
            logger: logger,
            isWindows: false,
            environment: {
              'HOME': tempDir.path,
            },
            configuration: zshConfiguration,
          );

          final rcFile = File(path.join(tempDir.path, '.zshrc'))..createSync();

          final configDir = zshInstallation.completionConfigDir;

          zshInstallation
            ..install('very_good')
            ..install('not_good');

          // rc fle includes one reference to the global config

          // ignore: leading_newlines_in_multiline_strings
          expect(rcFile.readAsStringSync(), '''
\n## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f ${configDir.path}/zsh-config.zsh ]] && . ${configDir.path}/zsh-config.zsh || true
## [/Completion]

''');

          // global config includes one reference for each command
          final globalConfig = File(
            path.join(configDir.path, 'zsh-config.zsh'),
          );

          // ignore: leading_newlines_in_multiline_strings
          expect(globalConfig.readAsStringSync(), '''
\n## [very_good]
## Completion config for "very_good"
[[ -f ${configDir.path}/very_good.zsh ]] && . ${configDir.path}/very_good.zsh || true
## [/very_good]

\n## [not_good]
## Completion config for "not_good"
[[ -f ${configDir.path}/not_good.zsh ]] && . ${configDir.path}/not_good.zsh || true
## [/not_good]

''');

          expect(
            configDir.listSync().map((e) => path.basename(e.path)),
            unorderedEquals([
              'not_good.zsh',
              'very_good.zsh',
              'zsh-config.zsh',
            ]),
          );

          final bashInstallation = CompletionInstallation(
            logger: logger,
            isWindows: false,
            environment: {
              'HOME': tempDir.path,
            },
            configuration: bashConfiguration,
          );

          final bashProfile = File(path.join(tempDir.path, '.bash_profile'))
            ..createSync();

          bashInstallation
            ..install('very_good')
            ..install('not_good');

          // ignore: leading_newlines_in_multiline_strings
          expect(bashProfile.readAsStringSync(), '''
\n## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[ -f ${configDir.path}/bash-config.bash ] && . ${configDir.path}/bash-config.bash || true
## [/Completion]

''');

          expect(
            configDir.listSync().map((e) => path.basename(e.path)),
            unorderedEquals([
              'not_good.bash',
              'not_good.zsh',
              'very_good.bash',
              'very_good.zsh',
              'zsh-config.zsh',
              'bash-config.bash'
            ]),
          );
        },
      );

      test(
        'installing completion when the current shell is not supported',
        () {
          final installation = CompletionInstallation.fromSystemShell(
            logger: logger,
            isWindowsOverride: false,
            environmentOverride: {
              'HOME': tempDir.path,
            },
            systemShell: null,
          );

          expect(
            () => installation.install('very_good'),
            throwsA(
              isA<CompletionInstallationException>().having(
                (e) => e.message,
                'message',
                'Unknown shell.',
              ),
            ),
          );
        },
      );
    });

    group('uninstall', () {
      test(
          '''deletes entire completion configuration when there is a single executable''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final configuration = zshConfiguration;
        final rcFile = File(path.join(tempDirectory.path, '.zshrc'))
          ..createSync();

        const executableName = 'very_good';
        final installation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDirectory.path,
          },
          configuration: configuration,
        )
          ..install(executableName)
          ..uninstall(executableName);

        expect(rcFile.existsSync(), isTrue);
        expect(rcFile.readAsStringSync(), isEmpty);
        expect(installation.completionConfigDir.existsSync(), false);
      });

      test(
          '''only deletes executable completion configuration when there are multiple installed executables''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final configuration = zshConfiguration;
        const executableName = 'very_good';
        const anotherExecutableName = 'not_good';

        final rcFile = File(path.join(tempDirectory.path, '.zshrc'))
          ..createSync();
        final installation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDirectory.path,
          },
          configuration: configuration,
        )
          ..install(executableName)
          ..install(anotherExecutableName);

        final shellCompletionConfigurationFile = File(
          path.join(
            installation.completionConfigDir.path,
            configuration.completionConfigForShellFileName,
          ),
        );

        installation.uninstall(executableName);

        expect(rcFile.existsSync(), isTrue);
        expect(
          const ScriptConfigurationEntry('Completion').existsIn(rcFile),
          isTrue,
        );

        expect(shellCompletionConfigurationFile.existsSync(), isTrue);
        expect(
          const ScriptConfigurationEntry(executableName)
              .existsIn(shellCompletionConfigurationFile),
          isFalse,
        );

        expect(
          const ScriptConfigurationEntry(anotherExecutableName)
              .existsIn(shellCompletionConfigurationFile),
          isTrue,
        );

        final executableCompletionConfigurationFile = File(
          path.join(
            installation.completionConfigDir.path,
            '$executableName.zsh',
          ),
        );
        expect(executableCompletionConfigurationFile.existsSync(), false);

        final anotherExecutableCompletionConfigurationFile = File(
          path.join(
            installation.completionConfigDir.path,
            '$anotherExecutableName.zsh',
          ),
        );
        expect(
          anotherExecutableCompletionConfigurationFile.existsSync(),
          isTrue,
        );
      });

      group('throws a CompletionUnistallationException', () {
        test('when RC file does not exist', () {
          final installation = CompletionInstallation(
            logger: logger,
            isWindows: false,
            environment: {
              'HOME': tempDir.path,
            },
            configuration: zshConfiguration,
          );
          final rcFile = File(path.join(tempDir.path, '.zshrc'));

          expect(
            () => installation.uninstall('very_good'),
            throwsA(
              isA<CompletionUnistallationException>().having(
                (e) => e.message,
                'message',
                equals('No shell RC file found at ${rcFile.path}'),
              ),
            ),
          );
        });

        test('when RC file does not have a completion entry', () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final installation = CompletionInstallation(
            logger: logger,
            isWindows: false,
            environment: {
              'HOME': tempDirectory.path,
            },
            configuration: zshConfiguration,
          );

          final rcFile = File(path.join(tempDirectory.path, '.zshrc'))
            ..createSync();

          expect(
            () => installation.uninstall('very_good'),
            throwsA(
              isA<CompletionUnistallationException>().having(
                (e) => e.message,
                'message',
                equals('Completion is not installed at ${rcFile.path}'),
              ),
            ),
          );
        });

        test('when RC file has a completion entry but no script file', () {
          final tempDirectory = Directory.systemTemp.createTempSync();
          addTearDown(() => tempDirectory.deleteSync(recursive: true));

          final configuration = zshConfiguration;
          final installation = CompletionInstallation(
            logger: logger,
            isWindows: false,
            environment: {
              'HOME': tempDirectory.path,
            },
            configuration: configuration,
          );

          final rcFile = File(path.join(tempDirectory.path, '.zshrc'))
            ..createSync();
          const ScriptConfigurationEntry('Completion').appendTo(rcFile);

          final shellCompletionConfigurationFile = File(
            path.join(
              installation.completionConfigDir.path,
              configuration.completionConfigForShellFileName,
            ),
          );

          expect(
            () => installation.uninstall('very_good'),
            throwsA(
              isA<CompletionUnistallationException>().having(
                (e) => e.message,
                'message',
                equals(
                  '''No shell script file found at ${shellCompletionConfigurationFile.path}''',
                ),
              ),
            ),
          );
        });
      });
    });
  });
}

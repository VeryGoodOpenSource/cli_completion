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
      // TODO(alestiago): Add checks that manual install writes into the config.json
      // file when previously uninstalled.
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
              'config.json',
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
              'bash-config.bash',
              'config.json',
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
      // TODO(alestiago): Add checks that uninstall writes into the config.json
      // file when uninstalled.
      test(
          '''deletes entire completion configuration when there is a single command''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final configuration = zshConfiguration;
        final rcFile = File(path.join(tempDirectory.path, '.zshrc'))
          ..createSync();

        const rootCommand = 'very_good';
        final installation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDirectory.path,
          },
          configuration: configuration,
        )
          ..install(rootCommand)
          ..uninstall(rootCommand);

        expect(
          rcFile.existsSync(),
          isTrue,
          reason: 'RC file should not be deleted.',
        );
        expect(
          const ScriptConfigurationEntry('Completion').existsIn(rcFile),
          isFalse,
          reason: 'Completion config entry should be removed from RC file.',
        );
        expect(installation.completionConfigDir.existsSync(), isFalse);
      });

      test(
          '''only deletes shell configuration when there is a single command in multiple shells''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final zshConfig = zshConfiguration;
        final zshRCFile = File(path.join(tempDirectory.path, '.zshrc'))
          ..createSync();

        final bashConfig = bashConfiguration;
        final bashRCFile = File(path.join(tempDirectory.path, '.bash_profile'))
          ..createSync();

        const rootCommand = 'very_good';

        final bashInstallation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDirectory.path,
          },
          configuration: bashConfig,
        )..install(rootCommand);

        final zshInstallation = CompletionInstallation(
          logger: logger,
          isWindows: false,
          environment: {
            'HOME': tempDirectory.path,
          },
          configuration: zshConfig,
        )
          ..install(rootCommand)
          ..uninstall(rootCommand);

        // Zsh should be uninstalled
        expect(
          zshRCFile.existsSync(),
          isTrue,
          reason: 'Zsh RC file should still exist.',
        );
        expect(
          const ScriptConfigurationEntry('Completion').existsIn(zshRCFile),
          isFalse,
          reason: 'Zsh should not have completion entry.',
        );

        final zshCompletionConfigurationFile = File(
          path.join(
            zshInstallation.completionConfigDir.path,
            zshConfig.completionConfigForShellFileName,
          ),
        );
        expect(
          zshCompletionConfigurationFile.existsSync(),
          isFalse,
          reason: 'Zsh completion configuration should be deleted.',
        );

        final zshCommandCompletionConfigurationFile = File(
          path.join(
            zshInstallation.completionConfigDir.path,
            '$rootCommand.zsh',
          ),
        );
        expect(
          zshCommandCompletionConfigurationFile.existsSync(),
          isFalse,
          reason: 'Zsh command completion configuration should be deleted.',
        );

        // Bash should still be installed
        expect(
          bashRCFile.existsSync(),
          isTrue,
          reason: 'Bash RC file should still exist.',
        );
        expect(
          const ScriptConfigurationEntry('Completion').existsIn(bashRCFile),
          isTrue,
          reason: 'Bash should have completion entry.',
        );

        final bashCompletionConfigurationFile = File(
          path.join(
            bashInstallation.completionConfigDir.path,
            bashConfig.completionConfigForShellFileName,
          ),
        );
        expect(
          bashCompletionConfigurationFile.existsSync(),
          isTrue,
          reason: 'Bash completion configuration should still exist.',
        );

        final bashCommandCompletionConfigurationFile = File(
          path.join(
            bashInstallation.completionConfigDir.path,
            '$rootCommand.bash',
          ),
        );
        expect(
          bashCommandCompletionConfigurationFile.existsSync(),
          isTrue,
          reason: 'Bash command completion configuration should still exist.',
        );

        expect(
          bashInstallation.completionConfigDir.existsSync(),
          isTrue,
          reason: 'Completion configuration directory should still exist.',
        );
      });

      test(
          '''only deletes command completion configuration when there are multiple installed commands''',
          () {
        final tempDirectory = Directory.systemTemp.createTempSync();
        addTearDown(() => tempDirectory.deleteSync(recursive: true));

        final configuration = zshConfiguration;
        const commandName = 'very_good';
        const anotherCommandName = 'not_good';

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
          ..install(commandName)
          ..install(anotherCommandName);

        final shellCompletionConfigurationFile = File(
          path.join(
            installation.completionConfigDir.path,
            configuration.completionConfigForShellFileName,
          ),
        );

        installation.uninstall(commandName);

        expect(
          rcFile.existsSync(),
          isTrue,
          reason: 'RC file should not be deleted.',
        );
        expect(
          const ScriptConfigurationEntry('Completion').existsIn(rcFile),
          isTrue,
          reason: 'Completion config entry should not be removed from RC file.',
        );

        expect(
          shellCompletionConfigurationFile.existsSync(),
          isTrue,
          reason: 'Shell completion configuration should still exist.',
        );

        expect(
          const ScriptConfigurationEntry(commandName)
              .existsIn(shellCompletionConfigurationFile),
          isFalse,
          reason:
              '''Command completion for $commandName configuration should be removed.''',
        );
        final commandCompletionConfigurationFile = File(
          path.join(
            installation.completionConfigDir.path,
            '$commandName.zsh',
          ),
        );
        expect(
          commandCompletionConfigurationFile.existsSync(),
          false,
          reason:
              '''Command completion configuration for $commandName should be deleted.''',
        );

        expect(
          const ScriptConfigurationEntry(anotherCommandName)
              .existsIn(shellCompletionConfigurationFile),
          isTrue,
          reason:
              '''Command completion configuration for $anotherCommandName should still exist.''',
        );
        final anotherCommandCompletionConfigurationFile = File(
          path.join(
            installation.completionConfigDir.path,
            '$anotherCommandName.zsh',
          ),
        );
        expect(
          anotherCommandCompletionConfigurationFile.existsSync(),
          isTrue,
          reason:
              '''Command completion configuration for $anotherCommandName should still exist.''',
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
              isA<CompletionUninstallationException>().having(
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
              isA<CompletionUninstallationException>().having(
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
              isA<CompletionUninstallationException>().having(
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

import 'dart:io';

import 'package:cli_completion/src/exceptions.dart';
import 'package:cli_completion/src/install/shell_completion_configuration.dart';
import 'package:cli_completion/src/system_shell.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// {@template shell_completion_installation}
/// A description of a completion installation process for a specific shell.
///
/// Creation should be done via [CompletionInstallation.fromSystemShell].
/// {@endtemplate}
class CompletionInstallation {
  /// {@macro shell_completion_installation}
  @visibleForTesting
  CompletionInstallation({
    required this.configuration,
    required this.logger,
    required this.isWindows,
    required this.environment,
  });

  /// Creates a [CompletionInstallation] given the current [SystemShell].
  factory CompletionInstallation.fromSystemShell({
    required SystemShell? systemShell,
    required Logger logger,
    bool? isWindowsOverride,
    Map<String, String>? environmentOverride,
  }) {
    final isWindows = isWindowsOverride ?? Platform.isWindows;
    final environment = environmentOverride ?? Platform.environment;

    final configuration = systemShell == null
        ? null
        : ShellCompletionConfiguration.fromSystemShell(systemShell);

    return CompletionInstallation(
      configuration: configuration,
      logger: logger,
      isWindows: isWindows,
      environment: environment,
    );
  }

  /// The injected [Logger];
  final Logger logger;

  /// Defines whether the installation is running on windows or not.
  final bool isWindows;

  /// Describes the environment variables. Usually
  /// equals to [Platform.environment].
  final Map<String, String> environment;

  /// The associated [ShellCompletionConfiguration].
  final ShellCompletionConfiguration? configuration;

  /// Define the [Directory] in which the
  /// completion configuration files will be stored.
  @visibleForTesting
  Directory get completionConfigDir {
    if (isWindows) {
      // Use localappdata on windows
      final localAppData = environment['LOCALAPPDATA']!;
      return Directory(path.join(localAppData, 'DartCLICompletion'));
    } else {
      // Use home on posix systems
      final home = environment['HOME']!;
      return Directory(path.join(home, '.dart-cli-completion'));
    }
  }

  /// Install completion configuration hooks for a [rootCommand] in the
  /// current shell.
  void install(String rootCommand) {
    final configuration = this.configuration;

    if (configuration == null) {
      throw CompletionInstallationException(
        message: 'Unknown shell.',
        rootCommand: rootCommand,
      );
    }

    logger.detail(
      'Installing completion for the command $rootCommand '
      'on ${configuration.name}',
    );

    createCompletionConfigDir();
    writeCompletionScriptForCommand(rootCommand);
    writeCompletionConfigForShell(rootCommand);
    writeToShellConfigFile(rootCommand);
  }

  /// Create a directory in which the completion config files shall be saved
  @visibleForTesting
  void createCompletionConfigDir() {
    final completionConfigDirPath = completionConfigDir.path;

    logger.info(
      'Creating completion configuration directory '
      'at $completionConfigDirPath',
    );

    if (completionConfigDir.existsSync()) {
      logger.warn(
        'A ${completionConfigDir.path} directory was already found.',
      );
      return;
    }

    completionConfigDir.createSync();
  }

  /// Creates a configuration file exclusively to [rootCommand] and the
  /// identified shell.
  @visibleForTesting
  void writeCompletionScriptForCommand(String rootCommand) {
    final configuration = this.configuration!;
    final completionConfigDirPath = completionConfigDir.path;
    final commandScriptName = '$rootCommand.${configuration.name}';
    final commandScriptPath = path.join(
      completionConfigDirPath,
      commandScriptName,
    );
    logger.info(
      'Writing completion script for $rootCommand on $commandScriptPath',
    );

    final scriptFile = File(commandScriptPath);

    if (scriptFile.existsSync()) {
      logger.warn(
        'A script file for $rootCommand was already found on '
        '$commandScriptPath.',
      );
      return;
    }

    scriptFile.writeAsStringSync(configuration.scriptTemplate(rootCommand));
  }

  /// Adds a reference for the command-specific config file created on
  /// [writeCompletionScriptForCommand] the the global completion config file.
  @visibleForTesting
  void writeCompletionConfigForShell(String rootCommand) {
    final configuration = this.configuration!;
    final completionConfigDirPath = completionConfigDir.path;

    final configPath = path.join(
      completionConfigDirPath,
      configuration.completionConfigForShellFileName,
    );
    logger.info('Adding config for $rootCommand config entry to $configPath');

    final configFile = File(configPath);

    if (!configFile.existsSync()) {
      logger.info('No file found at $configPath, creating one now');
      configFile.createSync();
    }
    final commandScriptName = '$rootCommand.${configuration.name}';

    final containsLine =
        configFile.readAsStringSync().contains(commandScriptName);

    if (containsLine) {
      logger.warn(
        'A config entry for $rootCommand was already found on $configPath.',
      );
      return;
    }

    _sourceScriptOnFile(
      configFile: configFile,
      scriptName: rootCommand,
      scriptPath: path.join(completionConfigDirPath, commandScriptName),
    );
  }

  String get _shellRCFilePath =>
      _resolveHome(configuration!.shellRCFile, environment);

  /// Write a source to the completion global script in the shell configuration
  /// file, which its location is described by the [configuration]
  @visibleForTesting
  void writeToShellConfigFile(String rootCommand) {
    final configuration = this.configuration!;

    logger.info(
      'Adding dart cli completion config entry '
      'to $_shellRCFilePath',
    );

    final completionConfigDirPath = completionConfigDir.path;

    final completionConfigPath = path.join(
      completionConfigDirPath,
      configuration.completionConfigForShellFileName,
    );

    final shellRCFile = File(_shellRCFilePath);

    if (!shellRCFile.existsSync()) {
      throw CompletionInstallationException(
        rootCommand: rootCommand,
        message: 'No configuration file found at ${shellRCFile.path}',
      );
    }

    final containsLine =
        shellRCFile.readAsStringSync().contains(completionConfigPath);

    if (containsLine) {
      logger.warn('A completion config entry was already found on'
          ' $_shellRCFilePath.');
      return;
    }

    _sourceScriptOnFile(
      configFile: shellRCFile,
      scriptName: 'Completion',
      description: 'Completion scripts setup. '
          'Remove the following line to uninstall',
      scriptPath: path.join(
        completionConfigDir.path,
        configuration.completionConfigForShellFileName,
      ),
    );
  }

  void _sourceScriptOnFile({
    required File configFile,
    required String scriptName,
    required String scriptPath,
    String? description,
  }) {
    assert(
      configFile.existsSync(),
      'Sourcing a script line into an nonexistent config file.',
    );

    final configFilePath = configFile.path;

    description ??= 'Completion config for "$scriptName"';

    configFile.writeAsStringSync(
      mode: FileMode.append,
      '''
## [$scriptName] 
## $description
${configuration!.sourceLineTemplate(scriptPath)}
## [/$scriptName]

''',
    );

    logger.info('Added config to $configFilePath');
  }
}

/// Resolve the home from a path string
String _resolveHome(
  String originalPath,
  Map<String, String> environment,
) {
  final after = originalPath.split('~/').last;
  final home = path.absolute(environment['HOME']!);
  return path.join(home, after);
}

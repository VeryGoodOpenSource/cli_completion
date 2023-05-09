import 'dart:io';

import 'package:cli_completion/installer.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// {@template shell_completion_installation}
/// Manages the installation of completion scripts for the current shell.
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

  /// Creates a [CompletionInstallation] given the current [systemShell].
  ///
  /// If [systemShell] is null, it will assume that the current shell is
  /// unknown and [configuration] will be null.
  ///
  /// Pass [isWindowsOverride] to override the default value of
  /// [Platform.isWindows].
  ///
  /// Pass [environmentOverride] to override the default value of
  /// [Platform.environment].
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

  /// The associated [ShellCompletionConfiguration] inferred from the current
  /// shell. It is null if the current shell is unknown.
  final ShellCompletionConfiguration? configuration;

  /// {@template completion_config_dir}
  /// Define the [Directory] in which the
  /// completion configuration files will be stored.
  ///
  /// If [isWindows] is true, it will return the directory defined by
  /// %LOCALAPPDATA%/DartCLICompletion
  ///
  /// If [isWindows] is false, it will return the directory defined by
  /// $XDG_CONFIG_HOME/.dart_cli_completion or $HOME/.dart_cli_completion
  /// {@endtemplate}
  @visibleForTesting
  Directory get completionConfigDir {
    if (isWindows) {
      // Use localappdata on windows
      final localAppData = environment['LOCALAPPDATA']!;
      return Directory(path.join(localAppData, 'DartCLICompletion'));
    } else {
      // Try using XDG config folder
      var dirPath = environment['XDG_CONFIG_HOME'];
      // Fallback to $HOME if not following XDG specification
      if (dirPath == null || dirPath.isEmpty) {
        dirPath = environment['HOME'];
      }
      return Directory(path.join(dirPath!, '.dart-cli-completion'));
    }
  }

  /// Install completion configuration files for a [rootCommand] in the
  /// current shell.
  ///
  /// It will create:
  /// - A completion script file in [completionConfigDir] that is named after
  /// the [rootCommand] and the current shell (e.g. `very_good.bash`).
  /// - A config file in [completionConfigDir] that is named after the current
  /// shell (e.g. `bash-config.bash`) that sources the aforementioned
  /// completion script file.
  /// - A line in the shell config file (e.g. `.bash_profile`) that sources
  /// the aforementioned config file.
  void install(String rootCommand) {
    final configuration = this.configuration;

    if (configuration == null) {
      throw CompletionInstallationException(
        message: 'Unknown shell.',
        rootCommand: rootCommand,
      );
    }

    logger.detail(
      '''Installing completion for the command $rootCommand on ${configuration.name}''',
    );

    createCompletionConfigDir();
    final completionFileCreated = writeCompletionScriptForCommand(rootCommand);
    writeCompletionConfigForShell(rootCommand);
    writeToShellConfigFile(rootCommand);

    if (completionFileCreated) {
      _logSourceInstructions(rootCommand);
    }
  }

  /// Create a directory in which the completion config files shall be saved.
  /// If the directory already exists, it will do nothing.
  ///
  /// The directory is defined by [completionConfigDir].
  @visibleForTesting
  void createCompletionConfigDir() {
    final completionConfigDirPath = completionConfigDir.path;

    logger.info(
      '''Creating completion configuration directory at $completionConfigDirPath''',
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
  ///
  /// The file will be named after the [rootCommand] and the current shell
  /// (e.g. `very_good.bash`).
  ///
  /// The file will be created in [completionConfigDir].
  ///
  /// If the file already exists, it will do nothing.
  ///
  /// Returns true if the file was created, false otherwise.
  @visibleForTesting
  bool writeCompletionScriptForCommand(String rootCommand) {
    final configuration = this.configuration!;
    final rootCommandScriptFile = RootCommand(
      name: rootCommand,
      shellName: configuration.name,
    ).commandScriptFile(completionConfigDir);

    logger.info(
      '''Writing completion script for $rootCommand on ${rootCommandScriptFile.path}''',
    );
    if (rootCommandScriptFile.existsSync()) {
      logger.warn(
        '''A script file for $rootCommand was already found on ${rootCommandScriptFile.path}''',
      );
      return false;
    }

    rootCommandScriptFile.writeAsStringSync(
      configuration.scriptTemplate(rootCommand),
    );
    return true;
  }

  /// Adds a reference for the command-specific config file created on
  /// [writeCompletionScriptForCommand] the the global completion config file.
  @visibleForTesting
  void writeCompletionConfigForShell(String rootCommand) {
    final configuration = this.configuration!;
    final completionConfig =
        configuration.completionScriptFile(completionConfigDir);

    logger.info(
      '''Adding config for $rootCommand config entry to ${completionConfig.path}''',
    );

    if (!completionConfig.existsSync()) {
      logger.info(
        '''No file found at ${completionConfig.path}, creating one now''',
      );
      completionConfig.createSync();
    }

    final command = RootCommand(
      name: rootCommand,
      shellName: configuration.name,
    );
    final commandEntry = command.entry;

    if (commandEntry.existsIn(completionConfig)) {
      logger.warn(
        '''A config entry for $rootCommand was already found on ${completionConfig.path}.''',
      );
      return;
    }

    final rootCommandScriptFile =
        command.commandScriptFile(completionConfigDir);
    // TODO(alestiago): Use a template function to create the content.
    final content = '''
## {Completion config for "$rootCommand"
${configuration.sourceLineTemplate(rootCommandScriptFile.path)}
''';
    commandEntry.appendTo(completionConfig, content: content);
    logger.info('Added config to ${completionConfig.path}');
  }

  String get _shellRCFilePath =>
      _resolveHome(configuration!.shellRCFile, environment);

  /// Write a source to the completion global script in the shell configuration
  /// file, which its location is described by the [configuration].
  @visibleForTesting
  void writeToShellConfigFile(String rootCommand) {
    final configuration = this.configuration!;

    logger.info(
      '''Adding dart cli completion config entry to $_shellRCFilePath''',
    );

    final shellCompletionConfigFile =
        configuration.completionScriptFile(completionConfigDir);

    final shellRCFile = File(_shellRCFilePath);
    if (!shellRCFile.existsSync()) {
      throw CompletionInstallationException(
        rootCommand: rootCommand,
        message: 'No configuration file found at ${shellRCFile.path}',
      );
    }

    final containsLine =
        shellRCFile.readAsStringSync().contains(shellCompletionConfigFile.path);

    if (containsLine) {
      logger.warn(
        '''A completion config entry was already found on $_shellRCFilePath''',
      );
      return;
    }

    // TODO(alestiago): Define a template function instead.
    final content = '''
Completion scripts setup. Remove the following line to uninstall.
${configuration.sourceLineTemplate(shellCompletionConfigFile.path)}
''';
    const ScriptEntry('Completion').appendTo(
      shellRCFile,
      content: content,
    );
    logger.info('Added config to ${shellRCFile.path}');
  }

  /// Tells the user to source the shell configuration file.
  void _logSourceInstructions(String rootCommand) {
    final level = logger.level;
    logger
      ..level = Level.info
      ..info(
        '\n'
        'Completion files installed. To enable completion, run the following '
        'command in your shell:\n'
        '${lightCyan.wrap('source $_shellRCFilePath')}'
        '\n',
      )
      ..level = level;
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

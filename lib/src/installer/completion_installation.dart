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

  /// Install completion configuration files for a [executableName] in the
  /// current shell.
  ///
  /// It will create:
  /// - A completion script file in [completionConfigDir] that is named after
  /// the [executableName] and the current shell (e.g. `very_good.bash`).
  /// - A config file in [completionConfigDir] that is named after the current
  /// shell (e.g. `bash-config.bash`) that sources the aforementioned
  /// completion script file.
  /// - A line in the shell config file (e.g. `.bash_profile`) that sources
  /// the aforementioned config file.
  void install(String executableName) {
    final configuration = this.configuration;

    if (configuration == null) {
      throw CompletionInstallationException(
        message: 'Unknown shell.',
        executableName: executableName,
      );
    }

    logger.detail(
      '''Installing completion for the command $executableName on ${configuration.name}''',
    );

    createCompletionConfigDir();
    final completionFileCreated =
        writeCompletionScriptForExecutable(executableName);
    writeCompletionConfigForShell(executableName);
    writeToShellConfigFile(executableName);

    if (completionFileCreated) {
      _logSourceInstructions(executableName);
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

  /// Creates a configuration file exclusively to [executableName] and the
  /// identified shell.
  ///
  /// The file will be named after the [executableName] and the current shell
  /// (e.g. `very_good.bash`).
  ///
  /// The file will be created in [completionConfigDir].
  ///
  /// If the file already exists, it will do nothing.
  ///
  /// Returns true if the file was created, false otherwise.
  @visibleForTesting
  bool writeCompletionScriptForExecutable(String executableName) {
    final configuration = this.configuration!;
    final executableCompletionScriptFile =
        ExecutableCompletionConfiguration.fromShellConfiguration(
      executabelName: executableName,
      shellConfiguration: configuration,
    ).completionScriptFile(completionConfigDir);

    logger.info(
      '''Writing completion script for $executableName on ${executableCompletionScriptFile.path}''',
    );
    if (executableCompletionScriptFile.existsSync()) {
      logger.warn(
        '''A script file for $executableName was already found on ${executableCompletionScriptFile.path}''',
      );
      return false;
    }

    executableCompletionScriptFile.writeAsStringSync(
      configuration.scriptTemplate(executableName),
    );
    return true;
  }

  /// Adds a reference for the executable-specific config file created on
  /// [writeCompletionScriptForExecutable] the the global completion config
  /// file.
  @visibleForTesting
  void writeCompletionConfigForShell(String executableName) {
    final configuration = this.configuration!;
    final shellCompletionConfig =
        configuration.completionScriptFile(completionConfigDir);

    logger.info(
      '''Adding config for $executableName config entry to ${shellCompletionConfig.path}''',
    );

    if (!shellCompletionConfig.existsSync()) {
      logger.info(
        '''No file found at ${shellCompletionConfig.path}, creating one now''',
      );
      shellCompletionConfig.createSync();
    }

    final executable = ExecutableCompletionConfiguration.fromShellConfiguration(
      executabelName: executableName,
      shellConfiguration: configuration,
    );
    final executableEntry = executable.entry;

    if (executableEntry.existsIn(shellCompletionConfig)) {
      logger.warn(
        '''A config entry for $executableName was already found on ${shellCompletionConfig.path}.''',
      );
      return;
    }

    final executableScriptFile = executable.completionScriptFile(
      completionConfigDir,
    );
    final content = configuration.completionReferenceTemplate(
      executableName: executableName,
      executableScriptFilePath: executableScriptFile.path,
    );
    executableEntry.appendTo(shellCompletionConfig, content: content);
    logger.info('Added config to ${shellCompletionConfig.path}');
  }

  String get _shellRCFilePath =>
      _resolveHome(configuration!.shellRCFile, environment);

  /// Write a source to the completion global script in the shell configuration
  /// file, which its location is described by the [configuration].
  @visibleForTesting
  void writeToShellConfigFile(String executableName) {
    final configuration = this.configuration!;

    logger.info(
      '''Adding dart cli completion config entry to $_shellRCFilePath''',
    );

    final shellCompletionConfigFile =
        configuration.completionScriptFile(completionConfigDir);

    final shellRCFile = File(_shellRCFilePath);
    if (!shellRCFile.existsSync()) {
      throw CompletionInstallationException(
        executableName: executableName,
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
## Completion scripts setup. Remove the following line to uninstall
${configuration.sourceLineTemplate(shellCompletionConfigFile.path)}''';
    const ScriptEntry('Completion').appendTo(
      shellRCFile,
      content: content,
    );
    logger.info('Added config to ${shellRCFile.path}');
  }

  /// Tells the user to source the shell configuration file.
  void _logSourceInstructions(String executableName) {
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

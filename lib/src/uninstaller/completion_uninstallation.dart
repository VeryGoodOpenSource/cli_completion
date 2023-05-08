import 'dart:io';

// TODO(alestiago): Consider moving ShellCompletionConfiguration to another directory.
import 'package:cli_completion/installer.dart';
import 'package:cli_completion/src/uninstaller/exceptions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// {@template completion_uninstallation}
/// Manages the uninstallation of completion scripts for the current shell.
/// {@macro completion_uninstallation}
class CompletionUninstallation {
  /// {@macro completion_uninstallation}
  @visibleForTesting
  CompletionUninstallation({
    required this.configuration,
    required this.logger,
    required this.isWindows,
    required this.environment,
  });

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

  /// Uninstall completion configuration files for a [rootCommand] in the
  /// current shell.
  ///
  /// It will remove:
  /// - A completion script file in [completionConfigDir] that is named after
  /// the [rootCommand] and the current shell (e.g. `very_good.bash`).
  /// - A config file in [completionConfigDir] that is named after the current
  /// shell (e.g. `bash-config.bash`) that sources the aforementioned
  /// completion script file.
  /// - A line in the shell config file (e.g. `.bash_profile`) that sources
  /// the aforementioned config file.
  void uninstall(String rootCommand) {
    // TODO(alestiago): Consider a global uninstall behaviour.
    final configuration = this.configuration;

    if (configuration == null) {
      throw CompletionUninstallationException(
        message: 'Unknown shell.',
        rootCommand: rootCommand,
      );
    }

    logger.detail(
      '''Uninstalling completion for the command $rootCommand on ${configuration.name}''',
    );

    deleteCompletionScriptForCommand(rootCommand);
    deleteCompletionConfigForShell(rootCommand);
  }

  /// Define the [Directory] in which the
  /// completion configuration files will be stored.
  ///
  /// If [isWindows] is true, it will return the directory defined by
  /// %LOCALAPPDATA%/DartCLICompletion
  ///
  /// If [isWindows] is false, it will return the directory defined by
  /// $XDG_CONFIG_HOME/.dart_cli_completion or $HOME/.dart_cli_completion
  @visibleForTesting
  Directory get completionConfigDir {
    // TODO(alestiago): Abstract this to avoid redundancy with [CompletionInstallation].
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
  bool deleteCompletionScriptForCommand(String rootCommand) {
    final configuration = this.configuration!;
    final completionConfigDirPath = completionConfigDir.path;
    final commandScriptName = '$rootCommand.${configuration.name}';
    final commandScriptPath = path.join(
      completionConfigDirPath,
      commandScriptName,
    );
    logger.info(
      'Deleting completion script for $rootCommand on $commandScriptPath',
    );

    final scriptFile = File(commandScriptPath);

    if (!scriptFile.existsSync()) {
      logger.warn(
        '''A script file for $rootCommand was not found on $commandScriptPath''',
      );
      return false;
    }

    try {
      scriptFile.deleteSync();
    } catch (error) {
      logger.warn(
        '''A script file for $rootCommand found on $commandScriptPath, could not be deleted because of the following error: $error''',
      );
    }

    return true;
  }

  /// Removes the reference for the command-specific config file created on
  /// [deleteCompletionScriptForCommand] the the global completion config file.
  @visibleForTesting
  void deleteCompletionConfigForShell(String rootCommand) {
    final configuration = this.configuration!;
    final completionConfigDirPath = completionConfigDir.path;

    final configPath = path.join(
      completionConfigDirPath,
      configuration.completionConfigForShellFileName,
    );
    logger.info('Removing config for $rootCommand config entry to $configPath');

    final configFile = File(configPath);

    if (!configFile.existsSync()) {
      logger.warn('No file found at $configPath');
      return;
    }

    final commandScriptName = '$rootCommand.${configuration.name}';
    final containsLine =
        configFile.readAsStringSync().contains(commandScriptName);

    if (!containsLine) {
      logger.warn(
        'A config entry for $rootCommand was not found on $configPath.',
      );
      return;
    }

    // TODO(alestiago): Find line using a regular expression and delete it.
  }
}

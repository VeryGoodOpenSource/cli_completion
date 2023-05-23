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

  /// Define the [File] in which the completion configuration is stored.
  @visibleForTesting
  File get completionConfigurationFile {
    return File(path.join(completionConfigDir.path, 'config.json'));
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
  ///
  /// If [force] is true, it will overwrite the command's completion files even
  /// if they already exist. If false, it will check if it has been explicitly
  /// uninstalled before installing it.
  void install(String rootCommand, {bool force = false}) {
    final configuration = this.configuration;

    if (configuration == null) {
      throw CompletionInstallationException(
        message: 'Unknown shell.',
        rootCommand: rootCommand,
      );
    }

    if (!force && !_shouldInstall(rootCommand)) {
      return;
    }

    logger.detail(
      'Installing completion for the command $rootCommand '
      'on ${configuration.shell.name}',
    );

    createCompletionConfigDir();
    final completionFileCreated = writeCompletionScriptForCommand(rootCommand);
    writeCompletionConfigForShell(rootCommand);
    writeToShellConfigFile(rootCommand);

    if (completionFileCreated) {
      _logSourceInstructions(rootCommand);
    }

    final completionConfiguration =
        CompletionConfiguration.fromFile(completionConfigurationFile);
    completionConfiguration
        .copyWith(
          uninstalls: completionConfiguration.uninstalls.exclude(
            command: rootCommand,
            systemShell: configuration.shell,
          ),
        )
        .writeTo(completionConfigurationFile);
  }

  /// Wether the completion configuration files for a [rootCommand] should be
  /// installed or not.
  ///
  /// It will return false if the root command has been explicitly uninstalled.
  bool _shouldInstall(String rootCommand) {
    final completionConfiguration = CompletionConfiguration.fromFile(
      completionConfigurationFile,
    );
    final systemShell = configuration!.shell;
    final isUninstalled = completionConfiguration.uninstalls.contains(
      command: rootCommand,
      systemShell: systemShell,
    );
    return !isUninstalled;
  }

  /// Create a directory in which the completion config files shall be saved.
  /// If the directory already exists, it will do nothing.
  ///
  /// The directory is defined by [completionConfigDir].
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
    final completionConfigDirPath = completionConfigDir.path;
    final commandScriptName = '$rootCommand.${configuration.shell.name}';
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
      return false;
    }

    scriptFile.writeAsStringSync(configuration.scriptTemplate(rootCommand));

    return true;
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

    if (ScriptConfigurationEntry(rootCommand).existsIn(configFile)) {
      logger.warn(
        'A config entry for $rootCommand was already found on $configPath.',
      );
      return;
    }

    final commandScriptName = '$rootCommand.${configuration.shell.name}';
    _sourceScriptOnFile(
      configFile: configFile,
      scriptName: rootCommand,
      scriptPath: path.join(completionConfigDirPath, commandScriptName),
    );
  }

  String get _shellRCFilePath =>
      _resolveHome(configuration!.shellRCFile, environment);

  /// Write a source to the completion global script in the shell configuration
  /// file, which its location is described by the [configuration].
  @visibleForTesting
  void writeToShellConfigFile(String rootCommand) {
    final configuration = this.configuration!;

    logger.info(
      'Adding dart cli completion config entry '
      'to $_shellRCFilePath',
    );

    final shellRCFile = File(_shellRCFilePath);
    if (!shellRCFile.existsSync()) {
      throw CompletionInstallationException(
        rootCommand: rootCommand,
        message: 'No configuration file found at ${shellRCFile.path}',
      );
    }

    if (const ScriptConfigurationEntry('Completion').existsIn(shellRCFile)) {
      logger.warn(
        '''A completion config entry was already found on $_shellRCFilePath.''',
      );
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

    final content = '''
## $description
${configuration!.sourceLineTemplate(scriptPath)}''';
    ScriptConfigurationEntry(scriptName).appendTo(
      configFile,
      content: content,
    );

    logger.info('Added config to $configFilePath');
  }

  /// Uninstalls the completion for the command [rootCommand] on the current
  /// shell.
  ///
  /// Before uninstalling, it checks if the completion is installed:
  /// - The shell has an existing RCFile with a completion
  /// [ScriptConfigurationEntry].
  /// - The shell has an existing completion configuration file with a
  /// [ScriptConfigurationEntry] for the [rootCommand].
  ///
  /// If any of the above is not true, it throws a
  /// [CompletionUninstallationException].
  ///
  /// Upon a successful uninstallation the executable [ScriptConfigurationEntry]
  /// is removed from the shell configuration file. If after this removal the
  /// latter is empty, it is deleted together with the the executable completion
  /// script and the completion [ScriptConfigurationEntry] from the shell RC
  /// file. In the case that there are no other completion scripts installed on
  /// other shells the completion config directory is deleted, leaving the
  /// user's system as it was before the installation.
  void uninstall(String rootCommand) {
    final configuration = this.configuration!;
    logger.detail(
      '''Uninstalling completion for the command $rootCommand on ${configuration.shell.name}''',
    );

    final shellRCFile = File(_shellRCFilePath);
    if (!shellRCFile.existsSync()) {
      throw CompletionUninstallationException(
        rootCommand: rootCommand,
        message: 'No shell RC file found at ${shellRCFile.path}',
      );
    }

    const completionEntry = ScriptConfigurationEntry('Completion');
    if (!completionEntry.existsIn(shellRCFile)) {
      throw CompletionUninstallationException(
        rootCommand: rootCommand,
        message: 'Completion is not installed at ${shellRCFile.path}',
      );
    }

    final shellCompletionConfigurationFile = File(
      path.join(
        completionConfigDir.path,
        configuration.completionConfigForShellFileName,
      ),
    );
    final executableEntry = ScriptConfigurationEntry(rootCommand);
    if (!executableEntry.existsIn(shellCompletionConfigurationFile)) {
      throw CompletionUninstallationException(
        rootCommand: rootCommand,
        message:
            '''No shell script file found at ${shellCompletionConfigurationFile.path}''',
      );
    }

    final executableShellCompletionScriptFile = File(
      path.join(
        completionConfigDir.path,
        '$rootCommand.${configuration.shell.name}',
      ),
    );
    if (executableShellCompletionScriptFile.existsSync()) {
      executableShellCompletionScriptFile.deleteSync();
    }

    executableEntry.removeFrom(
      shellCompletionConfigurationFile,
      shouldDelete: true,
    );
    if (!shellCompletionConfigurationFile.existsSync()) {
      completionEntry.removeFrom(shellRCFile);
    }
    final completionConfigDirContent = completionConfigDir.listSync();
    final onlyHasConfigurationFile = completionConfigDirContent.length == 1 &&
        path.absolute(completionConfigDirContent.first.path) ==
            path.absolute(completionConfigurationFile.path);
    if (completionConfigDirContent.isEmpty || onlyHasConfigurationFile) {
      completionConfigDir.deleteSync(recursive: true);
    } else {
      final completionConfiguration =
          CompletionConfiguration.fromFile(completionConfigurationFile);
      completionConfiguration
          .copyWith(
            uninstalls: completionConfiguration.uninstalls.include(
              command: rootCommand,
              systemShell: configuration.shell,
            ),
          )
          .writeTo(completionConfigurationFile);
    }
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

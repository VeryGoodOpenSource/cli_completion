import 'dart:io';

import 'package:path/path.dart' as path;

/// {@template system_shell}
/// A type definition for a shell.
///
/// The enumerated shells are the supported shells.
/// {@endtemplate}
enum SystemShell {
  /// The Zsh shell: https://www.zsh.org/
  zsh(
    'zsh',
    runCommandFileName: '.zshrc',
  ),

  /// GNU Bash shell: https://www.gnu.org/software/bash/
  bash(
    'bash',
    runCommandFileName: '.bash_profile',
  );

  /// {@macro system_shell}
  const SystemShell(this.name, {required String runCommandFileName})
      : _runCommandFileName = runCommandFileName;

  /// A descriptive string to identify the shell among others.
  final String name;

  /// The name of a config file that is run upon shell start.
  ///
  /// For example: `.bash_profile` or `.zshrc`.
  final String _runCommandFileName;

  /// Retrieves, from the current environment, the run command (RC) [File]
  /// for the shell.
  ///
  /// It is assumed that the RC file is located at the user's home directory.
  File runCommandFile({Map<String, String>? environmentOverride}) {
    final environment = environmentOverride ?? Platform.environment;

    final home = path.absolute(environment['HOME']!);
    final runCommandFilePath = path.join(home, _runCommandFileName);
    return File(runCommandFilePath);
  }

  /// Identifies the current shell based on the [Platform.environment].
  ///
  /// Pass [environmentOverride] to override the default value of
  /// [Platform.environment].
  ///
  /// Based on https://stackoverflow.com/a/3327022
  static SystemShell? current({
    Map<String, String>? environmentOverride,
  }) {
    final environment = environmentOverride ?? Platform.environment;

    // Heuristic: if ZSH_NAME is set, must be zsh
    final isZSH = environment['ZSH_NAME'] != null;
    if (isZSH) {
      return SystemShell.zsh;
    }

    // Heuristic: if BASH is set, must be bash
    final isBash = environment['BASH'] != null;
    if (isBash) {
      return SystemShell.bash;
    }

    final envShell = environment['SHELL'];
    if (envShell == null || envShell.isEmpty) return null;

    final basename = path.basename(envShell);

    if (basename == 'zsh') {
      return SystemShell.zsh;
    } else if (RegExp(r'bash(\.exe)?$').hasMatch(basename)) {
      // On windows basename can be bash.exe
      return SystemShell.bash;
    }

    return null;
  }
}

import 'dart:io';

import 'package:path/path.dart' as path;

/// The supported shells.
enum SystemShell {
  /// The Zsh shell: https://www.zsh.org/
  zsh,

  /// GNU Bash shell: https://www.gnu.org/software/bash/
  bash;

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

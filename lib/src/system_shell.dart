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

    // TODO(renancaraujo): this detects the "login shell", which can be
    // different from the actual shell.
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

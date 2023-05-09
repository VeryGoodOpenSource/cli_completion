import 'dart:io';
import 'package:cli_completion/installer.dart';
import 'package:path/path.dart' as path;

/// {@template root_command}
/// A root command with [name] that has been ran in [shellName].
/// {@endtemplate}
class Executable {
  /// {@macro root_command}
  const Executable({
    required this.name,
    required this.shellName,
  });

  /// The name of the executable.
  ///
  /// For example:
  /// - `flutter` given `flutter create`.
  /// - `git` given `git commit`.
  final String name;

  /// {@macro shell_name}
  ///
  /// Indicates where this [Executable] originated from.
  final String shellName;

  /// The completion script file for this [Executable].
  ///
  /// A completion script file contains the completion script for a specific
  /// command and shell.
  ///
  /// The [completionConfigDir] denotes where the completion script file for
  /// this [Executable] should be located.
  File completionScriptFile(Directory completionConfigDir) {
    final commandScriptPath = path.join(
      completionConfigDir.path,
      '$name.$shellName',
    );
    return File(commandScriptPath);
  }

  /// A script entry for this [Executable].
  ScriptEntry get entry => ScriptEntry(name);
}

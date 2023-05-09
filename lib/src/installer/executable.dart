import 'dart:io';
import 'package:cli_completion/installer.dart';
import 'package:path/path.dart' as path;

/// {@template root_command}
/// An executable that originated from [shellName].
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
  // TODO(alestiago): Consider removing this member from [Executable].
  final String shellName;

  /// The completion script file for this [Executable].
  ///
  /// A completion script file contains the completion script for a specific
  /// executable and shell.
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

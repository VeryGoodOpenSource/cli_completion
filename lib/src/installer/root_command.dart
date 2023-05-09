import 'dart:io';
import 'package:cli_completion/installer.dart';
import 'package:path/path.dart' as path;

/// {@template root_command}
/// A root command with [name] that has been ran in [shellName].
/// {@endtemplate}
class RootCommand {
  /// {@macro root_command}
  const RootCommand({
    required this.name,
    required this.shellName,
  });

  /// The root name of the command.
  ///
  /// For example the name would be `flutter` given `flutter create`.
  final String name;

  /// {@macro shell_name}
  ///
  /// Indicates where this [RootCommand] originated from.
  final String shellName;

  /// The command script file for this [RootCommand].
  ///
  /// A completion script file contains the completion script for a specific
  /// command and shell.
  ///
  /// The [completionConfigDir] denotes where the completion script file for
  /// this [RootCommand] should be located.
  File commandScriptFile(Directory completionConfigDir) {
    final commandScriptPath = path.join(
      completionConfigDir.path,
      '$name.$shellName',
    );
    return File(commandScriptPath);
  }

  /// A script entry for this [RootCommand].
  ScriptEntry get entry => ScriptEntry(name);
}

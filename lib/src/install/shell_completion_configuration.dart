import 'package:meta/meta.dart';

/// A type definition for functions that creates the content of a
/// completion script given a [rootCommand]
typedef CompletionScriptTemplate = String Function(String rootCommand);

/// A type definition for functions that describes
/// the source line given a [scriptPath]
typedef SourceStringTemplate = String Function(String scriptPath);

/// {@template shell_completion_configuration}
/// Describes the configuration of a completion script in a specific shell.
///
/// See:
/// - [zshConfiguration] for zsh
@immutable
class ShellCompletionConfiguration {
  /// {@macro shell_completion_configuration}
  @visibleForTesting
  const ShellCompletionConfiguration({
    required this.name,
    required this.shellRCFile,
    required this.sourceLineTemplate,
    required this.scriptTemplate,
  });

  /// A descriptive string to identify the shell among others.
  final String name;

  /// The location of a config file that is run upon shell start.
  /// Eg: .bashrc or .zshrc
  final String shellRCFile;

  /// Generates a line to sources of a script file.
  final SourceStringTemplate sourceLineTemplate;

  /// Generates the contents of a completion script.
  final CompletionScriptTemplate scriptTemplate;

  /// The name for the config file for this shell.
  String get completionConfigForShellFileName => '$name-config.$name';
}

/// A [ShellCompletionConfiguration] for zsh.
final zshConfiguration = ShellCompletionConfiguration(
  name: 'zsh',
  shellRCFile: '~/.zshrc',
  sourceLineTemplate: (String scriptPath) {
    return '[[ -f $scriptPath ]] && . $scriptPath || true';
  },
  scriptTemplate: (String rootCommand) {
    // Completion script for zsh.
    //
    // Based on https://github.com/mklabs/tabtab/blob/master/lib/scripts/zsh.sh
    return '''
if type compdef &>/dev/null; then
  _${rootCommand}_completion () {
    local reply
    local si=\$IFS

    IFS=\$'\n' reply=(\$(COMP_CWORD="\$((CURRENT-1))" COMP_LINE="\$BUFFER" COMP_POINT="\$CURSOR" $rootCommand completion -- "\${words[@]}"))
    IFS=\$si

    _describe 'values' reply
  }
  compdef _${rootCommand}_completion $rootCommand
fi
''';
  },
);

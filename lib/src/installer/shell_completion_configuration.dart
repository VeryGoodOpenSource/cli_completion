import 'package:cli_completion/installer.dart';
import 'package:meta/meta.dart';

/// A type definition for functions that creates the content of a
/// completion script given a [rootCommand]
typedef CompletionScriptTemplate = String Function(String rootCommand);

/// A type definition for functions that describes
/// the source line given a [scriptPath]
typedef SourceStringTemplate = String Function(String scriptPath);

/// {@template shell_completion_configuration}
/// Describes all the configuration needed to install completion scripts on a
/// specific shell.
///
/// See:
/// - [ShellCompletionConfiguration.fromSystemShell] to retrieve the
/// configuration for a [SystemShell].
/// {@endtemplate}
@immutable
class ShellCompletionConfiguration {
  /// {@macro shell_completion_configuration}
  const ShellCompletionConfiguration._({
    required this.shell,
    required this.shellRCFiles,
    required this.sourceLineTemplate,
    required this.scriptTemplate,
  });

  /// Creates a [ShellCompletionConfiguration] given the current [SystemShell].
  factory ShellCompletionConfiguration.fromSystemShell(
    SystemShell systemShell,
  ) {
    switch (systemShell) {
      case SystemShell.zsh:
        return zshConfiguration;
      case SystemShell.bash:
        return bashConfiguration;
    }
  }

  /// {@macro system_shell}
  final SystemShell shell;

  /// A preferential ordered list of locations of a config file that is run upon
  /// shell start. The list is to allow multiple options eg both .bash_profile
  /// and .bashrc. The first option will  be tried first and and if the file
  /// doesn't exist the next one will be tried.
  /// Eg: .bash_profile or .zshrc
  final List<String> shellRCFiles;

  /// Generates a line to sources of a script file.
  final SourceStringTemplate sourceLineTemplate;

  /// Generates the contents of a completion script.
  final CompletionScriptTemplate scriptTemplate;

  /// The name for the config file for this shell.
  String get completionConfigForShellFileName =>
      '${shell.name}-config.${shell.name}';
}

/// A [ShellCompletionConfiguration] for zsh.
@visibleForTesting
final zshConfiguration = ShellCompletionConfiguration._(
  shell: SystemShell.zsh,
  shellRCFiles: const ['~/.zshrc'],
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

    if [[ -z "\$reply" ]]; then
        _path_files
    else 
        _describe 'values' reply
    fi
  }
  compdef _${rootCommand}_completion $rootCommand
fi
''';
  },
);

/// A [ShellCompletionConfiguration] for bash.
@visibleForTesting
final bashConfiguration = ShellCompletionConfiguration._(
  shell: SystemShell.bash,
  shellRCFiles: const ['~/.bashrc', '~/.bash_profile'],
  sourceLineTemplate: (String scriptPath) {
    return '[ -f $scriptPath ] && . $scriptPath || true';
  },
  scriptTemplate: (String rootCommand) {
    // Completion script for bash.
    //
    // Based on https://github.com/mklabs/tabtab/blob/master/lib/scripts/bash.sh
    return '''
if type complete &>/dev/null; then
  _${rootCommand}_completion () {
    local words cword
    if type _get_comp_words_by_ref &>/dev/null; then
      _get_comp_words_by_ref -n = -n @ -n : -w words -i cword
    else
      cword="\$COMP_CWORD"
      words=("\${COMP_WORDS[@]}")
    fi
    local si="\$IFS"
    IFS=\$'\n' COMPREPLY=(\$(COMP_CWORD="\$cword" \\
                           COMP_LINE="\$COMP_LINE" \\
                           COMP_POINT="\$COMP_POINT" \\
                           $rootCommand completion -- "\${words[@]}" \\
                           2>/dev/null)) || return \$?
    IFS="\$si"
    if type __ltrim_colon_completions &>/dev/null; then
      __ltrim_colon_completions "\${words[cword]}"
    fi
  }
  complete -o default -F _${rootCommand}_completion $rootCommand
fi
''';
  },
);

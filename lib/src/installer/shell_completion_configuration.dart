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
@immutable
class ShellCompletionConfiguration {
  /// {@macro shell_completion_configuration}
  const ShellCompletionConfiguration._({
    required this.name,
    required this.shellRCFile,
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

  /// A descriptive string to identify the shell among others.
  final String name;

  /// The location of a config file that is run upon shell start.
  /// Eg: .bash_profile or .zshrc
  final String shellRCFile;

  /// Generates a line to sources of a script file.
  final SourceStringTemplate sourceLineTemplate;

  /// Generates the contents of a completion script.
  final CompletionScriptTemplate scriptTemplate;

  /// The name for the config file for this shell.
  String get completionConfigForShellFileName => '$name-config.$name';
}

/// A [ShellCompletionConfiguration] for zsh.
@visibleForTesting
final zshConfiguration = ShellCompletionConfiguration._(
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
  name: 'bash',
  shellRCFile: '~/.bash_profile',
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

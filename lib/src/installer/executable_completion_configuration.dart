import 'dart:io';
import 'package:cli_completion/installer.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

/// A type definition for functions that creates the content of a
/// completion script given a [executableName].
typedef CompletionScriptTemplate = String Function(String executableName);

/// {@template executable_completion_configuration}
/// An executable that originated from [shellName].
/// {@endtemplate}
class ExecutableCompletionConfiguration {
  /// {@macro executable_completion_configuration}
  const ExecutableCompletionConfiguration({
    required this.name,
    required this.shellName,
    required this.sourceLineTemplate,
  });

  /// Creates a [ExecutableCompletionConfiguration] given the current
  /// [ShellCompletionConfiguration].
  factory ExecutableCompletionConfiguration.fromShellConfiguration({
    required String executabelName,
    required ShellCompletionConfiguration shellConfiguration,
  }) {
    final CompletionScriptTemplate scriptTemplate;
    switch (shellConfiguration.name) {
      case 'zsh':
        scriptTemplate = zshCompletionScriptTemplate;
        break;
      case 'bash':
    }

    return ExecutableCompletionConfiguration(
      name: executabelName,
      shellName: shellConfiguration.name,
      sourceLineTemplate: shellConfiguration.sourceLineTemplate,
    );
  }

  /// The name of the executable.
  ///
  /// For example:
  /// - `flutter` given `flutter create`.
  /// - `git` given `git commit`.
  final String name;

  /// {@macro shell_name}
  ///
  /// Indicates where this [ExecutableCompletionConfiguration] originated from.
  final String shellName;

  /// {@macro source_line_template}
  final SourceStringTemplate sourceLineTemplate;

  /// The completion script file for this [ExecutableCompletionConfiguration].
  ///
  /// A completion script file contains the completion script for a specific
  /// executable and shell.
  ///
  /// The [completionConfigDir] denotes where the completion script file for
  /// this [ExecutableCompletionConfiguration] should be located.
  File completionScriptFile(Directory completionConfigDir) {
    final commandScriptPath = path.join(
      completionConfigDir.path,
      '$name.$shellName',
    );
    return File(commandScriptPath);
  }

  /// A script entry for this [ExecutableCompletionConfiguration].
  ScriptEntry get entry => ScriptEntry(name);
}

/// The [CompletionScriptTemplate] for a zsh shell.
@visibleForTesting
CompletionScriptTemplate zshCompletionScriptTemplate = (
  String executableName,
) {
  // Completion script for zsh.
  //
  // Based on https://github.com/mklabs/tabtab/blob/master/lib/scripts/zsh.sh
  return '''
if type compdef &>/dev/null; then
  _${executableName}_completion () {
    local reply
    local si=\$IFS

    IFS=\$'\n' reply=(\$(COMP_CWORD="\$((CURRENT-1))" COMP_LINE="\$BUFFER" COMP_POINT="\$CURSOR" $executableName completion -- "\${words[@]}"))
    IFS=\$si

    if [[ -z "\$reply" ]]; then
        _path_files
    else 
        _describe 'values' reply
    fi
  }
  compdef _${executableName}_completion $executableName
fi
''';
};

/// The [CompletionScriptTemplate] for a bash shell.
@visibleForTesting
CompletionScriptTemplate bashCompletionScriptTemplate = (
  String executableName,
) {
  // Completion script for bash.
  //
  // Based on https://github.com/mklabs/tabtab/blob/master/lib/scripts/bash.sh
  return '''
if type complete &>/dev/null; then
  _${executableName}_completion () {
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
                           $executableName completion -- "\${words[@]}" \\
                           2>/dev/null)) || return \$?
    IFS="\$si"
    if type __ltrim_colon_completions &>/dev/null; then
      __ltrim_colon_completions "\${words[cword]}"
    fi
  }
  complete -o default -F _${executableName}_completion $executableName
fi
''';
};

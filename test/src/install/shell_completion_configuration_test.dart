import 'package:cli_completion/install.dart';
import 'package:cli_completion/src/install/shell_completion_configuration.dart';
import 'package:test/test.dart';

void main() {
  group('ShellCompletionConfiguration', () {
    group('zshConfiguration', () {
      late ShellCompletionConfiguration zshConfiguration;

      setUp(() {
        zshConfiguration =
            ShellCompletionConfiguration.fromSystemShell(SystemShell.zsh);
      });

      test('name', () {
        expect(zshConfiguration.name, 'zsh');
      });

      test('shellRCFile', () {
        expect(zshConfiguration.shellRCFile, '~/.zshrc');
      });

      test('sourceStringTemplate', () {
        final result = zshConfiguration.sourceLineTemplate('./pans/snaps');
        expect(result, '[[ -f ./pans/snaps ]] && . ./pans/snaps || true');
      });

      test('completionScriptTemplate', () {
        final result = zshConfiguration.scriptTemplate('very_good');
        expect(result, '''
if type compdef &>/dev/null; then
  _very_good_completion () {
    local reply
    local si=\$IFS

    IFS=\$'\n' reply=(\$(COMP_CWORD="\$((CURRENT-1))" COMP_LINE="\$BUFFER" COMP_POINT="\$CURSOR" very_good completion -- "\${words[@]}"))
    IFS=\$si

    _describe 'values' reply
  }
  compdef _very_good_completion very_good
fi
''');
      });

      test('completionConfigForShellFileName', () {
        expect(
          zshConfiguration.completionConfigForShellFileName,
          'zsh-config.zsh',
        );
      });
    });

    group('bashConfiguration', () {
      late ShellCompletionConfiguration bashConfiguration;

      setUp(() {
        bashConfiguration =
            ShellCompletionConfiguration.fromSystemShell(SystemShell.bash);
      });

      test('name', () {
        expect(bashConfiguration.name, 'bash');
      });

      test('shellRCFile', () {
        expect(bashConfiguration.shellRCFile, '~/.bash_profile');
      });

      test('sourceStringTemplate', () {
        final result = bashConfiguration.sourceLineTemplate('./pans/snaps');
        expect(result, '[ -f ./pans/snaps ] && . ./pans/snaps || true');
      });

      test('completionScriptTemplate', () {
        final result = bashConfiguration.scriptTemplate('very_good');
        expect(result, '''
if type complete &>/dev/null; then
  _very_good_completion () {
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
                           very_good completion -- "\${words[@]}" \\
                           2>/dev/null)) || return \$?
    IFS="\$si"
    if type __ltrim_colon_completions &>/dev/null; then
      __ltrim_colon_completions "\${words[cword]}"
    fi
  }
  complete -o default -F _very_good_completion very_good
fi
''');
      });

      test('completionConfigForShellFileName', () {
        expect(
          bashConfiguration.completionConfigForShellFileName,
          'bash-config.bash',
        );
      });
    });
  });
}

import 'package:cli_completion/src/install/shell_completion_configuration.dart';
import 'package:test/test.dart';

void main() {
  group('ShellCompletionConfiguration', () {
    group('zshConfiguration', () {
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
  });
}

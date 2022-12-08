
# CLI Completion

[![Very Good Ventures][logo_white]][very_good_ventures_link_dark]
[![Very Good Ventures][logo_black]][very_good_ventures_link_light]


[![pub package][pub_badge]][pub_link]
[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![License: MIT][license_badge]][license_link]

---

Completion functionality for Dart Command-Line Interfaces built using CommandRunner.

Developed with 💙 by [Very Good Ventures][very_good_ventures_link] 🦄


## Installation 💻

**❗ In order to start using CLI Completion you must have the [Dart SDK][dart_install_link] installed
on your machine.**

```
flutter pub add cli_completion
```



## Usage ✨

On your `CommandRunner` class, extend `CompletionCommandRunner` :

```dart
import 'package:cli_completion/cli_completion.dart';

class ExampleCommandRunner extends CompletionCommandRunner<int> {
...
```
This will make the first command run to install the completion files automatically. To disable that behavior, set `enableAutoInstall` to false:

```dart
class ExampleCommandRunner extends **CompletionCommandRunner**<int> {
  
  @override
  bool get enableAutoInstall => false;
...
```

When `enableAutoInstall` is set to false, users will have to call `install-completion-files` to install these files manually.

```bash
$ example_cli install-completion-files
```

## Documentation 📝

For an overview of how this package works, check out the [documentation][docs_link].

### ⚠️ Using analytics

Handling completion requests should be straightforward.

If there are any checks (like analytics, telemetry, or anything that you may have on `run` or `runCommand` overrides) before running subcommands, make sure you fast track the `completion` command to skip all of the unnecessary computations.

Example:

```dart
@override
Future<int?> runCommand(ArgResults topLevelResults) async {
  if (topLevelResults.command?.name == 'completion') {
    super.runCommand(topLevelResults);
		return;
	}
  // ... analytics and other unrelated stuff 
```

[dart_install_link]: https://dart.dev/get-dart
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
[docs_link]: doc/
[pub_link]: https://cli_completion.pckg.pub
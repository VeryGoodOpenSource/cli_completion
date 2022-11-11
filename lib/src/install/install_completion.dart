import 'package:cli_completion/src/exceptions.dart';
import 'package:cli_completion/src/install/shell_completion_installation.dart';

import 'package:mason_logger/mason_logger.dart';

/// Install completion configuration hooks for a [rootCommand] in the
/// current shell.
void installCompletion({
  required Logger logger,
  required String rootCommand,
  bool? isWindowsOverride,
  Map<String, String>? environmentOverride,
}) {
  logger
    ..detail('Completion installation for $rootCommand started')
    ..detail('Identifying system shell');

  final completionInstallation = ShellCompletionInstallation.fromCurrentShell(
    logger: logger,
    isWindowsOverride: isWindowsOverride,
    environmentOverride: environmentOverride,
  );

  if (completionInstallation == null) {
    throw CompletionInstallationException(
      message: 'Unknown shell.',
      rootCommand: rootCommand,
    );
  }

  logger.detail(
    'Shell identified as ${completionInstallation.configuration.name}',
  );

  completionInstallation.install(rootCommand);
}

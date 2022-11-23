import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/src/handling/arg_parser_extension.dart';
import 'package:meta/meta.dart';

/// {@template completion_level}
/// The necessary information to produce completion for [CommandRunner] based
/// cli applications.
/// {@endtemplate}
///
/// Generally, the [grammar], [visibleSubcommands] and [visibleOptions]
///
/// See also [find] to learn how it is created.
@immutable
class CompletionLevel {
  /// {@macro completion_level}
  @visibleForTesting
  const CompletionLevel({
    required this.grammar,
    required this.rawArgs,
    required this.visibleSubcommands,
    required this.visibleOptions,
  });

  /// Given a user input [rootArgs] and the [runnerGrammar], it finds the
  /// innermost context that needs completion.
  ///
  /// If the user input did not type any sub command, the runner itself
  /// will be taken as the completion context.
  ///
  /// Example:
  /// ```
  /// root_command -f command1 command2 -o
  /// ```
  /// Consider `root_command` the cli executable being completed and
  /// `command1`  a sub command of `root_command` and `command2` a sub
  /// command of `command1`.
  ///
  /// In a scenario where the user requests completion for this line, all
  /// possible suggestions (options, flags and sub commands) should be delcared
  /// under the [ArgParser] object belonging to `command2`, all the args
  /// preceding `command2` are irrelevant for completion.
  ///
  /// if the user input does not respect the known structure of commands,
  /// it returns null.
  static CompletionLevel? find(
    Iterable<String> rootArgs,
    ArgParser runnerGrammar,
    Map<String, Command<dynamic>> runnerCommands,
  ) {
    // Parse args regarding only commands
    final commandsOnlyResults = runnerGrammar.tryParseCommandsOnly(rootArgs);

    // If it cannot parse commands, bail out.
    if (commandsOnlyResults == null) {
      return null;
    }

    // Find the leaf-most parsed command, starting from the root level

    // The user-declared argParser in the current command, starting as the one
    // on the runner and substituted by the ones belonging to the
    // parsed subcommands, if any.
    var originalGrammar = runnerGrammar;

    // The available sub commands of the current level, starting as the
    // commands declared on the runner and substituted by the
    // parsed subcommands, if any.
    Map<String, Command<dynamic>>? subcommands = runnerCommands;

    var nextLevelResults = commandsOnlyResults.command;
    String? commandName;
    while (nextLevelResults != null) {
      originalGrammar = originalGrammar.commands[nextLevelResults.name]!;
      // This can be null if .addSubCommand was sued directly
      subcommands = subcommands?[nextLevelResults.name]?.subcommands;
      commandName = nextLevelResults.name;
      nextLevelResults = nextLevelResults.command;
    }

    // rawArgs should be only the args after the last parsed command
    final List<String> rawArgs;
    if (commandName != null) {
      rawArgs =
          rootArgs.skipWhile((value) => value != commandName).skip(1).toList();
    } else {
      rawArgs = rootArgs.toList();
    }

    final visibleSubcommands = subcommands?.values.where((command) {
          return !command.hidden;
        }).toList() ??
        [];

    final visibleOptions = originalGrammar.options.values.where((option) {
      return !option.hide;
    }).toList();

    return CompletionLevel(
      grammar: originalGrammar,
      rawArgs: rawArgs,
      visibleSubcommands: visibleSubcommands,
      visibleOptions: visibleOptions,
    );
  }

  /// The [ArgParser] declared in the [CommandRunner] or [Command] that
  /// needs completion.
  final ArgParser grammar;

  /// The user input that needs completion starting from the
  /// command/sub_command being completed.
  final List<String> rawArgs;

  /// The not-hidden commands declared by [grammar] in the form of [Command]
  /// instances.
  final List<Command<dynamic>> visibleSubcommands;

  /// The not-hidden options declared by [grammar].
  final List<Option> visibleOptions;
}

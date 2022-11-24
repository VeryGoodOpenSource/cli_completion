import 'package:args/args.dart';

/// Extends [ArgParser] with utility methods that allow parsing a completion
/// input, which in most cases only regards part of the rules.
extension ArgParserExtension on ArgParser {
  /// Parses [args] with this [ArgParser]'s command structure only, ignore
  /// option strict rules (mandatory, allowed values, non negatable flags,
  /// default values);
  ///
  /// Still breaks if an unknown option/alias is passed.
  ///
  /// Returns null if there is an error when parsing, which means the given args
  /// do not respect the known command structure.
  ArgResults? tryParseCommandsOnly(Iterable<String> args) {
    final commandsOnlyGrammar = _looseOptions();

    try {
      return commandsOnlyGrammar
          .parse(args.where((arg) => arg.isNotEmpty));
    } on ArgParserException {
      return null;
    }
  }

  /// Recursively copies this [ArgParser] with the options mapping way less
  /// strict.;
  ArgParser _looseOptions() {
    final clonedArgParser = ArgParser(
      allowTrailingOptions: allowTrailingOptions,
    );

    for (final entry in commands.entries) {
      final parser = entry.value._looseOptions();
      clonedArgParser.addCommand(entry.key, parser);
    }

    // The intention is to disregard options altogheter.
    // That is not doable because ArgParser breaks if there is an input to an
    // unmapped option,producing false negatives.
    // Since it is impossible to extend ArgParser, we just clone an existing
    // instance with way less restrictive option rules instead.
    // This can be significantly more expensive if we have lots of options
    // trough out the cli.
    for (final entry in options.entries) {
      final option = entry.value;

      if (option.isFlag) {
        clonedArgParser.addFlag(
          option.name,
          abbr: option.abbr,
          aliases: option.aliases,
        );
      }

      if (option.isSingle) {
        clonedArgParser.addOption(
          option.name,
          abbr: option.abbr,
          aliases: option.aliases,
        );
      }

      if (option.isMultiple) {
        clonedArgParser.addMultiOption(
          option.name,
          abbr: option.abbr,
          aliases: option.aliases,
        );
      }
    }

    return clonedArgParser;
  }
}

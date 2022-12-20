import 'package:args/args.dart';

final _optionRegex = RegExp(r'^--(([a-zA-Z\-_0-9]+)(=(.*))?)?$');

/// Defines if [string] complies with the GNU argument syntax.
///
/// Does not match abbreviated options.
bool isOption(String string) => _optionRegex.hasMatch(string);

final _abbrRegex = RegExp(r'^-(([a-zA-Z0-9]+)(.*))?$');

/// Defines if [string] complies with the GNU argument syntax in an
/// abbreviated form.
bool isAbbr(String string) => _abbrRegex.hasMatch(string);

/// Extends [ArgParser] with utility methods that allow parsing a completion
/// input, which in most cases only regards part of the rules.
extension ArgParserExtension on ArgParser {
  /// Tries to parse the minimal subset of valid [args] as valid options.
  ArgResults? findValidOptions(List<String> args) {
    final loosenOptionsGramamar = _looseOptions();
    var currentArgs = args;
    while (currentArgs.isNotEmpty) {
      try {
        return loosenOptionsGramamar.parse(currentArgs);
      } catch (_) {
        currentArgs = currentArgs.take(currentArgs.length - 1).toList();
      }
    }
    return null;
  }

  /// Parses [args] with this [ArgParser]'s command structure only, ignore
  /// option strict rules (mandatory, allowed values, non negatable flags,
  /// default values, etc);
  ///
  /// Still breaks if an unknown option/alias is passed.
  ///
  /// Returns null if there is an error when parsing, which means the given args
  /// do not respect the known command structure.
  ArgResults? tryParseCommandsOnly(Iterable<String> args) {
    final commandsOnlyGrammar = _cloneCommandsOnly();

    final filteredArgs = args.where((element) {
      return !isAbbr(element) && !isOption(element) && element.isNotEmpty;
    });

    try {
      return commandsOnlyGrammar
          .parse(filteredArgs.where((element) => element.isNotEmpty));
    } on ArgParserException {
      return null;
    }
  }

  /// Recursively copies this [ArgParser] without options.
  ArgParser _cloneCommandsOnly() {
    final clonedArgParser = ArgParser(
      allowTrailingOptions: allowTrailingOptions,
    );

    for (final entry in commands.entries) {
      final parser = entry.value._cloneCommandsOnly();
      clonedArgParser.addCommand(entry.key, parser);
    }

    return clonedArgParser;
  }

  /// Copies this [ArgParser] with a less strict option mapping.
  ///
  /// It preserves only the options names, types, abbreviations and aliases.
  ///
  /// It disregard subcommands.
  ArgParser _looseOptions() {
    final clonedArgParser = ArgParser(
      allowTrailingOptions: allowTrailingOptions,
    );

    for (final entry in options.entries) {
      final option = entry.value;

      if (option.isFlag) {
        clonedArgParser.addFlag(
          option.name,
          abbr: option.abbr,
          aliases: option.aliases,
          negatable: option.negatable ?? true,
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

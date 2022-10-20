// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:cli_completion/cli_completion.dart';
// ignore_for_file: prefer_const_constructors
import 'package:test/test.dart';

void main() {
  group('CliCompletion', () {
    test('can be instantiated', () {
      expect(CliCompletion(), isNotNull);
    });
  });
}

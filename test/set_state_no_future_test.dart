import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `setState(() => field = someFuture())` returns the Future from the closure,
/// which Flutter rejects ("setState() callback argument returned a Future").
/// Use a block body instead: `setState(() { field = someFuture(); });`.
void main() {
  test('no setState arrow closure assigns a Future-returning call', () {
    final pattern = RegExp(
      r'setState\(\(\)\s*=>\s*_?\w*[Ff]uture\w*\s*=',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

import 'dart:io';

import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every literal fontSize in lib/ is on the app type scale', () {
    // 40 = workout timer, 64 = emoji illustration; both are intentional.
    final allowed = {...AppType.scale, 40.0, 64.0};
    final pattern = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)(?:\.sp)?\s*[,)]');
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final m in pattern.allMatches(line)) {
          final v = double.parse(m.group(1)!);
          if (!allowed.contains(v)) {
            offenders.add('${entity.path}:${i + 1} fontSize $v');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}

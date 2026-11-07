// Generates placeholder launcher icons, one colour per flavor, so `make icons`
// works out of the box and dev/staging/prod are easy to tell apart on a device.
// Replace the PNGs in assets/launcher/ with real artwork and run `make icons`.
//
// Usage: dart run tool/placeholder_icons.dart
import 'dart:io';

import 'package:image/image.dart' as img;

const _flavors = {
  'dev': (0xF7, 0x90, 0x09, 'DEV'),
  'staging': (0x7A, 0x3E, 0xC8, 'STG'),
  'prod': (0x3F, 0x51, 0xB5, ''),
};

void main() {
  Directory('assets/launcher').createSync(recursive: true);
  for (final MapEntry(key: flavor, value: (r, g, b, label)) in _flavors.entries) {
    final icon = img.Image(width: 1024, height: 1024);
    img.fill(icon, color: img.ColorRgb8(r, g, b));
    // White rounded square in the middle as a stand-in logo.
    img.fillRect(
      icon,
      x1: 312,
      y1: 312,
      x2: 712,
      y2: 712,
      radius: 80,
      color: img.ColorRgb8(255, 255, 255),
    );
    if (label.isNotEmpty) {
      img.fillRect(icon, x1: 0, y1: 800, x2: 1024, y2: 1024, color: img.ColorRgb8(0, 0, 0));
      img.drawString(
        icon,
        label,
        font: img.arial48,
        x: 512 - label.length * 14,
        y: 885,
        color: img.ColorRgb8(255, 255, 255),
      );
    }
    File('assets/launcher/icon_$flavor.png').writeAsBytesSync(img.encodePng(icon));
    stdout.writeln('assets/launcher/icon_$flavor.png');
  }
}

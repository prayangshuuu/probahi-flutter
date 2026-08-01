import 'dart:io';

import 'package:image/image.dart' as img;

/// Writes a plain placeholder logo (a solid neutral-900 square with a
/// centered white circle) to [outputPath]. Used as the template's default
/// branding asset, and by `tool/brand_app.dart` when no `--logo` is given.
///
/// Deliberately has no text/font rendering — a real logo should replace
/// this before shipping a build to an academy.
void createPlaceholderLogo({required String outputPath, int size = 1024}) {
  final image = img.Image(width: size, height: size);
  img.fill(image, color: img.ColorRgb8(0x17, 0x17, 0x17));
  img.fillCircle(
    image,
    x: size ~/ 2,
    y: size ~/ 2,
    radius: (size * 0.28).round(),
    color: img.ColorRgb8(0xFF, 0xFF, 0xFF),
  );

  final file = File(outputPath);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
}

void main(List<String> args) {
  final outputPath = args.isNotEmpty ? args[0] : 'assets/branding/logo.png';
  createPlaceholderLogo(outputPath: outputPath);
  stdout.writeln('Wrote placeholder logo to $outputPath');
}

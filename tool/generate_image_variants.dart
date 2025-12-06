import 'dart:io';
import 'package:image/image.dart' as img;

void main(List<String> args) async {
  if (args.isEmpty) {
    stdout.writeln('usage: dart run tool/generate_image_variants.dart <asset_path> [base_scale]');
    exit(1);
  }
  final inputPath = args[0];
  final baseScale = args.length > 1 ? double.tryParse(args[1]) ?? 4.0 : 4.0;
  final file = File(inputPath);
  if (!file.existsSync()) {
    stdout.writeln('not found: $inputPath');
    exit(1);
  }

  final bytes = await file.readAsBytes();
  final src = img.decodeImage(bytes);
  if (src == null) {
    stdout.writeln('decode failed');
    exit(1);
  }

  final dir = file.parent;
  final name = file.uri.pathSegments.last;
  final baseWidth = (src.width / baseScale).round();
  final baseHeight = (src.height / baseScale).round();

  Future<void> writeScaled(String subdir, double scale) async {
    final w = (baseWidth * scale).round();
    final h = (baseHeight * scale).round();
    final resized = img.copyResize(src, width: w, height: h, interpolation: img.Interpolation.cubic);
    final outDir = Directory('${dir.path}/$subdir');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final outFile = File('${outDir.path}/$name');
    final ext = name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final outBytes = ext == 'png' ? img.encodePng(resized, level: 6) : img.encodeJpg(resized, quality: 85);
    await outFile.writeAsBytes(outBytes, flush: true);
    stdout.writeln('generated $subdir/$name (${w}x$h)');
  }

  await writeScaled('1.0x', 1.0);
  await writeScaled('1.5x', 1.5);
  await writeScaled('2.0x', 2.0);
  await writeScaled('3.0x', 3.0);
  await writeScaled('4.0x', 4.0);

  stdout.writeln('done');
}

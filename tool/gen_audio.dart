// ignore_for_file: avoid_print
// Synthesizes placeholder sound effects and a short music loop into
// assets/audio/. Original tones, no third-party material.
//   dart run tool/gen_audio.dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int rate = 22050;

Uint8List wav(List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(
      44 + i * 2,
      (samples[i].clamp(-1.0, 1.0) * 32000).round(),
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}

List<double> tone(
  List<(double freq, double secs)> notes, {
  double gain = 0.5,
  bool square = false,
}) {
  final out = <double>[];
  for (final (f, secs) in notes) {
    final n = (secs * rate).round();
    for (var i = 0; i < n; i++) {
      final t = i / rate;
      final env = math.min(1.0, i / (rate * 0.005)) * math.pow(1 - i / n, 1.5);
      var v = f == 0 ? 0.0 : math.sin(2 * math.pi * f * t);
      if (square) v = v >= 0 ? 0.6 : -0.6;
      out.add(v * env * gain);
    }
  }
  return out;
}

void main() {
  final dir = Directory('assets/audio')..createSync(recursive: true);
  final sounds = <String, List<double>>{
    'tap': tone([(880, 0.05)], gain: 0.3),
    'move': tone([(523, 0.06), (659, 0.06)], gain: 0.35),
    'pickup': tone([(659, 0.07), (784, 0.07), (988, 0.09)], gain: 0.4),
    'rescue': tone([
      (784, 0.08),
      (988, 0.08),
      (1175, 0.08),
      (1568, 0.16),
    ], gain: 0.4),
    'action': tone([(392, 0.06), (523, 0.1)], gain: 0.4, square: true),
    'warning': tone([(330, 0.12), (262, 0.18)], gain: 0.35),
    'win': tone([
      (523, 0.12),
      (659, 0.12),
      (784, 0.12),
      (1047, 0.3),
    ], gain: 0.45),
  };
  // Theme: 8-bar C-major arpeggio loop, ~9.6 s.
  const bars = [
    [262.0, 330.0, 392.0, 330.0],
    [220.0, 262.0, 330.0, 262.0],
    [175.0, 220.0, 262.0, 220.0],
    [196.0, 247.0, 294.0, 247.0],
  ];
  final theme = <(double, double)>[];
  for (var rep = 0; rep < 2; rep++) {
    for (final bar in bars) {
      for (var beat = 0; beat < 2; beat++) {
        for (final f in bar) {
          theme.add((f, 0.15));
        }
      }
    }
  }
  sounds['theme'] = tone(theme, gain: 0.25);
  for (final e in sounds.entries) {
    File('${dir.path}/${e.key}.wav').writeAsBytesSync(wav(e.value));
  }
  stdout.writeln('wrote ${sounds.length} files to ${dir.path}');
}

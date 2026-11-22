import 'dart:typed_data';

/// Zero-dependency RFC 6234 streaming SHA-256 implementation for APK verification.
class Sha256Sink {
  static const List<int> _k = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];

  final Uint32List _h = Uint32List.fromList(const [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ]);
  final Uint8List _buf = Uint8List(64);
  final Uint32List _w = Uint32List(64);
  int _bufLen = 0;
  int _totalBytes = 0;

  void add(List<int> data) {
    var offset = 0;
    final len = data.length;
    _totalBytes += len;
    if (_bufLen > 0) {
      final take = (64 - _bufLen) < len ? (64 - _bufLen) : len;
      for (var i = 0; i < take; i++) {
        _buf[_bufLen + i] = data[i] & 0xff;
      }
      _bufLen += take;
      offset += take;
      if (_bufLen == 64) {
        _compress(_buf, 0);
        _bufLen = 0;
      }
    }
    while (offset + 64 <= len) {
      _compress(data, offset);
      offset += 64;
    }
    while (offset < len) {
      _buf[_bufLen++] = data[offset++] & 0xff;
    }
  }

  String digestHex() {
    final totalBits = _totalBytes * 8;
    _buf[_bufLen++] = 0x80;
    if (_bufLen > 56) {
      while (_bufLen < 64) {
        _buf[_bufLen++] = 0;
      }
      _compress(_buf, 0);
      _bufLen = 0;
    }
    while (_bufLen < 56) {
      _buf[_bufLen++] = 0;
    }
    final highBits = (totalBits ~/ 0x100000000) & 0xffffffff;
    final lowBits = totalBits & 0xffffffff;
    _buf[56] = (highBits >> 24) & 0xff;
    _buf[57] = (highBits >> 16) & 0xff;
    _buf[58] = (highBits >> 8) & 0xff;
    _buf[59] = highBits & 0xff;
    _buf[60] = (lowBits >> 24) & 0xff;
    _buf[61] = (lowBits >> 16) & 0xff;
    _buf[62] = (lowBits >> 8) & 0xff;
    _buf[63] = lowBits & 0xff;
    _compress(_buf, 0);

    final sb = StringBuffer();
    for (var i = 0; i < 8; i++) {
      sb.write(_h[i].toRadixString(16).padLeft(8, '0'));
    }
    return sb.toString();
  }

  static int _rotr(int x, int n) => ((x >>> n) | (x << (32 - n))) & 0xffffffff;

  void _compress(List<int> block, int offset) {
    for (var i = 0; i < 16; i++) {
      final j = offset + i * 4;
      _w[i] = ((block[j] & 0xff) << 24) |
          ((block[j + 1] & 0xff) << 16) |
          ((block[j + 2] & 0xff) << 8) |
          (block[j + 3] & 0xff);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = _rotr(_w[i - 15], 7) ^ _rotr(_w[i - 15], 18) ^ (_w[i - 15] >>> 3);
      final s1 = _rotr(_w[i - 2], 17) ^ _rotr(_w[i - 2], 19) ^ (_w[i - 2] >>> 10);
      _w[i] = (_w[i - 16] + s0 + _w[i - 7] + s1) & 0xffffffff;
    }

    var a = _h[0];
    var b = _h[1];
    var c = _h[2];
    var d = _h[3];
    var e = _h[4];
    var f = _h[5];
    var g = _h[6];
    var h = _h[7];

    for (var i = 0; i < 64; i++) {
      final s1 = _rotr(e, 6) ^ _rotr(e, 11) ^ _rotr(e, 25);
      final ch = (e & f) ^ ((~e & 0xffffffff) & g);
      final t1 = (h + s1 + ch + _k[i] + _w[i]) & 0xffffffff;
      final s0 = _rotr(a, 2) ^ _rotr(a, 13) ^ _rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & 0xffffffff;

      h = g;
      g = f;
      f = e;
      e = (d + t1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xffffffff;
    }

    _h[0] = (_h[0] + a) & 0xffffffff;
    _h[1] = (_h[1] + b) & 0xffffffff;
    _h[2] = (_h[2] + c) & 0xffffffff;
    _h[3] = (_h[3] + d) & 0xffffffff;
    _h[4] = (_h[4] + e) & 0xffffffff;
    _h[5] = (_h[5] + f) & 0xffffffff;
    _h[6] = (_h[6] + g) & 0xffffffff;
    _h[7] = (_h[7] + h) & 0xffffffff;
  }
}

String sha256Hex(List<int> bytes) {
  final sink = Sha256Sink()..add(bytes);
  return sink.digestHex();
}

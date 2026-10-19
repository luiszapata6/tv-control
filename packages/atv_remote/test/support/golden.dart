import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Golden vectors produced by tools/codegen/gen_golden.py from the reference
/// Python implementation.
final Map<String, dynamic> golden = jsonDecode(File('test/fixtures/golden.json').readAsStringSync()) as Map<String, dynamic>;

Map<String, String> goldenSection(String name) => (golden[name] as Map<String, dynamic>).cast<String, String>();

Uint8List hexBytes(String hex) =>
    Uint8List.fromList([for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)]);

String toHex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

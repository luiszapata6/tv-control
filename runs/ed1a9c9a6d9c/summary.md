# CI FAIL — ed1a9c9a6d9c

Run: https://github.com/luiszapata6/tv-control/actions/runs/39343582181
Commit: feat: protocol simulator, golden vectors and atv_remote Dart package
Job results: [
  "success",
  "failure"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | FAIL | 1s |
| dart | atv-test | FAIL | 4s |
| dart | setup | PASS | 4s |
| python | codegen-up-to-date | PASS | 0s |
| python | pip | PASS | 3s |
| python | sim-tests | PASS | 7s |

## dart / atv-analyze (last 150 lines)

```
Analyzing atv_remote...

warning - lib/src/crypto/certificate.dart:135:20 - Unnecessary cast. Try removing the cast. - unnecessary_cast
warning - lib/src/crypto/certificate.dart:136:21 - Unnecessary cast. Try removing the cast. - unnecessary_cast
warning - test/protocol_test.dart:26:28 - Dead code. Try removing the code, or fixing the code before it so that it can be reached. - dead_code
warning - test/protocol_test.dart:82:45 - The '!' will have no effect because the receiver can't be null. Try removing the '!' operator. - unnecessary_non_null_assertion

4 issues found.
```

## dart / atv-test (last 150 lines)

```
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -2: loading test/misc_test.dart [E]
  Failed to load "test/misc_test.dart":
  lib/src/proto/remotemessage.pb.dart:1220:64: Error: The parameter 'editInfo' can't have a value of 'null' because of its type 'List<RemoteEditInfo>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'RemoteEditInfo' is from 'package:atv_remote/src/proto/remotemessage.pb.dart' ('lib/src/proto/remotemessage.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    RemoteImeBatchEdit({this.imeCounter, this.fieldCounter, this.editInfo});
                                                                 ^^^^^^^^
  lib/src/proto/polo.pb.dart:314:17: Error: The parameter 'inputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                  ^^^^^^^^^^^^^^
  lib/src/proto/polo.pb.dart:314:38: Error: The parameter 'outputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -3: loading test/integration_sim_test.dart [E]
  Failed to load "test/integration_sim_test.dart":
  lib/src/proto/remotemessage.pb.dart:1220:64: Error: The parameter 'editInfo' can't have a value of 'null' because of its type 'List<RemoteEditInfo>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'RemoteEditInfo' is from 'package:atv_remote/src/proto/remotemessage.pb.dart' ('lib/src/proto/remotemessage.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    RemoteImeBatchEdit({this.imeCounter, this.fieldCounter, this.editInfo});
                                                                 ^^^^^^^^
  lib/src/proto/polo.pb.dart:314:17: Error: The parameter 'inputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                  ^^^^^^^^^^^^^^
  lib/src/proto/polo.pb.dart:314:38: Error: The parameter 'outputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -4: loading test/framing_test.dart [E]
  Failed to load "test/framing_test.dart":
  lib/src/proto/remotemessage.pb.dart:1220:64: Error: The parameter 'editInfo' can't have a value of 'null' because of its type 'List<RemoteEditInfo>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'RemoteEditInfo' is from 'package:atv_remote/src/proto/remotemessage.pb.dart' ('lib/src/proto/remotemessage.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    RemoteImeBatchEdit({this.imeCounter, this.fieldCounter, this.editInfo});
                                                                 ^^^^^^^^
  lib/src/proto/polo.pb.dart:314:17: Error: The parameter 'inputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                  ^^^^^^^^^^^^^^
  lib/src/proto/polo.pb.dart:314:38: Error: The parameter 'outputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -5: loading test/proto_golden_test.dart [E]
  Failed to load "test/proto_golden_test.dart":
  lib/src/proto/remotemessage.pb.dart:1220:64: Error: The parameter 'editInfo' can't have a value of 'null' because of its type 'List<RemoteEditInfo>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'RemoteEditInfo' is from 'package:atv_remote/src/proto/remotemessage.pb.dart' ('lib/src/proto/remotemessage.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    RemoteImeBatchEdit({this.imeCounter, this.fieldCounter, this.editInfo});
                                                                 ^^^^^^^^
  lib/src/proto/polo.pb.dart:314:17: Error: The parameter 'inputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                  ^^^^^^^^^^^^^^
  lib/src/proto/polo.pb.dart:314:38: Error: The parameter 'outputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -6: loading test/protocol_test.dart [E]
  Failed to load "test/protocol_test.dart":
  lib/src/proto/remotemessage.pb.dart:1220:64: Error: The parameter 'editInfo' can't have a value of 'null' because of its type 'List<RemoteEditInfo>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'RemoteEditInfo' is from 'package:atv_remote/src/proto/remotemessage.pb.dart' ('lib/src/proto/remotemessage.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    RemoteImeBatchEdit({this.imeCounter, this.fieldCounter, this.editInfo});
                                                                 ^^^^^^^^
  lib/src/proto/polo.pb.dart:314:17: Error: The parameter 'inputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                  ^^^^^^^^^^^^^^
  lib/src/proto/polo.pb.dart:314:38: Error: The parameter 'outputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -7: loading test/pairing_secret_test.dart [E]
  Failed to load "test/pairing_secret_test.dart":
  lib/src/proto/remotemessage.pb.dart:1220:64: Error: The parameter 'editInfo' can't have a value of 'null' because of its type 'List<RemoteEditInfo>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'RemoteEditInfo' is from 'package:atv_remote/src/proto/remotemessage.pb.dart' ('lib/src/proto/remotemessage.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    RemoteImeBatchEdit({this.imeCounter, this.fieldCounter, this.editInfo});
                                                                 ^^^^^^^^
  lib/src/proto/polo.pb.dart:314:17: Error: The parameter 'inputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                  ^^^^^^^^^^^^^^
  lib/src/proto/polo.pb.dart:314:38: Error: The parameter 'outputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -8: loading test/certificate_test.dart [E]
  Failed to load "test/certificate_test.dart":
  lib/src/proto/remotemessage.pb.dart:1220:64: Error: The parameter 'editInfo' can't have a value of 'null' because of its type 'List<RemoteEditInfo>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'RemoteEditInfo' is from 'package:atv_remote/src/proto/remotemessage.pb.dart' ('lib/src/proto/remotemessage.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    RemoteImeBatchEdit({this.imeCounter, this.fieldCounter, this.editInfo});
                                                                 ^^^^^^^^
  lib/src/proto/polo.pb.dart:314:17: Error: The parameter 'inputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                  ^^^^^^^^^^^^^^
  lib/src/proto/polo.pb.dart:314:38: Error: The parameter 'outputEncodings' can't have a value of 'null' because of its type 'List<Options_Encoding>', but the implicit default value is 'null'.
   - 'List' is from 'dart:core'.
   - 'Options_Encoding' is from 'package:atv_remote/src/proto/polo.pb.dart' ('lib/src/proto/polo.pb.dart').
  Try adding either an explicit non-'null' default value or the 'required' modifier.
    Options({this.inputEncodings, this.outputEncodings, this.preferredRole});
                                       ^^^^^^^^^^^^^^^
00:00 +0 -8: Some tests failed.

Failing tests:
  test/certificate_test.dart: loading test/certificate_test.dart
  test/client_test.dart: loading test/client_test.dart
  test/framing_test.dart: loading test/framing_test.dart
  test/integration_sim_test.dart: loading test/integration_sim_test.dart
  ... and 4 more
```

# CI FAIL — 5362b8d6280f

Run: https://github.com/luiszapata6/tv-control/actions/runs/39522929682
Commit: feat: iOS widgets, Control Center, Live Activity and Siri (TVKit); Mac menu-bar app; launcher audit fixes; handoff docs
Job results: [
  "success",
  "success",
  "success",
  "failure",
  "failure"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | PASS | 2s |
| dart | atv-test | PASS | 11s |
| dart | companion-analyze | PASS | 0s |
| dart | companion-test | PASS | 5s |
| dart | setup | PASS | 6s |
| ios | ios-build | FAIL | 108s |
| ios | ios-ipa | FAIL | 0s |
| ios | ios-pub | PASS | 2s |
| ios | macos-build | FAIL | 67s |
| launcher | launcher-analyze | PASS | 7s |
| launcher | launcher-apk | PASS | 170s |
| launcher | launcher-kotlin-tests | PASS | 36s |
| launcher | launcher-pub | PASS | 3s |
| launcher | launcher-test | PASS | 9s |
| python | codegen-up-to-date | PASS | 1s |
| python | pip | PASS | 5s |
| python | sim-tests | PASS | 9s |
| remote | remote-analyze | FAIL | 10s |
| remote | remote-pub | PASS | 8s |
| remote | remote-test | FAIL | 23s |

## ios / ios-build (last 150 lines)

```
Runner.xcodeproj updated
Warning: Building for device with codesigning disabled. You will have to manually codesign before deploying to device.
Xcode is fetching Swift Package Manager dependencies. This may take several minutes...
  Fetching from https://github.com/mattgallagher/CwlCatchException.git...     
Building com.luiszapata.tvcontrol.tvRemote for device (ios-release)...
** BUILD FAILED **
    export VERBOSE_PBXCP\=NO
    export VERSIONING_SYSTEM\=apple-generic
    export VERSIONPLIST_PATH\=Runner.app/version.plist
    export VERSION_INFO_BUILDER\=runner
    export VERSION_INFO_FILE\=Runner_vers.c
    export VERSION_INFO_STRING\=\"@\(\#\)PROGRAM:Runner\ \ PROJECT:Runner-1\"
    export WORKSPACE_DIR\=/Users/runner/work/tv-control/tv-control/apps/remote/ios
    export WRAPPER_EXTENSION\=app
    export WRAPPER_NAME\=Runner.app
    export WRAPPER_SUFFIX\=.app
    export WRAP_ASSET_PACKS_IN_SEPARATE_DIRECTORIES\=NO
    export XCODE_APP_SUPPORT_DIR\=/Applications/Xcode_26.6.app/Contents/Developer/Library/Xcode
    export XCODE_PRODUCT_BUILD_VERSION\=17F113
    export XCODE_VERSION_ACTUAL\=2660
    export XCODE_VERSION_MAJOR\=2600
    export XCODE_VERSION_MINOR\=2660
    export XPCSERVICES_FOLDER_PATH\=Runner.app/XPCServices
    export YACC\=yacc
    export _DISCOVER_COMMAND_LINE_LINKER_INPUTS\=YES
    export _DISCOVER_COMMAND_LINE_LINKER_INPUTS_INCLUDE_WL\=YES
    export _LD_MULTIARCH\=YES
    export _WRAPPER_CONTENTS_DIR_SHALLOW_BUNDLE_NO\=/Contents
    export _WRAPPER_PARENT_PATH_SHALLOW_BUNDLE_NO\=/..
    export _WRAPPER_RESOURCES_DIR_SHALLOW_BUNDLE_NO\=/Resources
    export __DIAGNOSE_DEPRECATED_ARCHS\=YES
    export __IS_NOT_MACOS\=YES
    export __IS_NOT_MACOS_macosx\=NO
    export __IS_NOT_SIMULATOR\=YES
    export __IS_NOT_SIMULATOR_simulator\=NO
    export __ORIGINAL_SDK_DEFINED_LLVM_TARGET_TRIPLE_SYS\=ios
    export arch\=undefined_arch
    export variant\=normal
    /bin/sh -c /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Intermediates.noindex/Runner.build/Release-iphoneos/Runner.build/Script-9740EEB61CF901F6004384FC.sh
lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
      useDataProtectionKeyChain: false,
      ^^^^^^^^^^^^^^^^^^^^^^^^^
../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
  const MacOsOptions({
        ^^^^^^^^^^^^
Target kernel_snapshot_program failed: Exception
Failed to package /Users/runner/work/tv-control/tv-control/apps/remote.
Command PhaseScriptExecution failed with a nonzero exit code

Copy /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/Runner.app/shared_preferences_foundation_shared_preferences_foundation.bundle /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/shared_preferences_foundation_shared_preferences_foundation.bundle (in target 'Runner' from project 'Runner')
    cd /Users/runner/work/tv-control/tv-control/apps/remote/ios
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/shared_preferences_foundation_shared_preferences_foundation.bundle /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/Runner.app

Copy /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/Runner.app/flutter_secure_storage_darwin_flutter_secure_storage_darwin.bundle /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/flutter_secure_storage_darwin_flutter_secure_storage_darwin.bundle (in target 'Runner' from project 'Runner')
    cd /Users/runner/work/tv-control/tv-control/apps/remote/ios
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/flutter_secure_storage_darwin_flutter_secure_storage_darwin.bundle /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Products/Release-iphoneos/Runner.app

note: Run script build phase 'Run Script' will be run during every build because the option to run the script phase "Based on dependency analysis" is unchecked. (in target 'Runner' from project 'Runner')
note: Run script build phase 'Thin Binary' will be run during every build because the option to run the script phase "Based on dependency analysis" is unchecked. (in target 'Runner' from project 'Runner')
** BUILD FAILED **


The following build commands failed:
	PhaseScriptExecution Run\ Script /Users/runner/work/tv-control/tv-control/apps/remote/build/xcode/Build/Intermediates.noindex/Runner.build/Release-iphoneos/Runner.build/Script-9740EEB61CF901F6004384FC.sh (in target 'Runner' from project 'Runner')
	Building workspace Runner with scheme Runner and configuration Release
(2 failures)
```

## ios / ios-ipa (last 150 lines)

```
missing apps/remote/build/ios/iphoneos/Runner.app
```

## ios / macos-build (last 150 lines)

```
Xcode is fetching Swift Package Manager dependencies. This may take several minutes...
  Fetching from https://github.com/mattgallagher/CwlCatchException.git (cached)...     
Building macOS application...                                   
lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
      useDataProtectionKeyChain: false,
      ^^^^^^^^^^^^^^^^^^^^^^^^^
../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
  const MacOsOptions({
        ^^^^^^^^^^^^
Target kernel_snapshot_program failed: Exception
Failed to package /Users/runner/work/tv-control/tv-control/apps/remote.
Command PhaseScriptExecution failed with a nonzero exit code
warning: Run script build phase 'Run Script' will be run during every build because it does not specify any outputs. To address this issue, either add output dependencies to the script phase, or configure it to run in every build by unchecking "Based on dependency analysis" in the script phase. (in target 'Flutter Assemble' from project 'Runner')
** BUILD FAILED **

Build process failed
```

## remote / remote-analyze (last 150 lines)

```
Analyzing remote...                                             

  error • The named parameter 'useDataProtectionKeyChain' isn't defined. Try correcting the name to an existing named parameter's name, or defining a named parameter with the name 'useDataProtectionKeyChain' • lib/src/services/storage.dart:21:7 • undefined_named_parameter

1 issue found. (ran in 9.2s)
```

## remote / remote-test (last 150 lines)

```
00:00 +0: loading /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart
lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
      useDataProtectionKeyChain: false,
      ^^^^^^^^^^^^^^^^^^^^^^^^^
../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
  const MacOsOptions({
        ^^^^^^^^^^^^
00:00 +0 -1: loading /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart [E]
  Failed to load "/home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart":
  Compilation failed for testPath=/home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
        useDataProtectionKeyChain: false,
        ^^^^^^^^^^^^^^^^^^^^^^^^^
  ../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
    const MacOsOptions({
          ^^^^^^^^^^^^
  .
  Error: The Dart compiler exited unexpectedly.
  package:flutter_tools/src/base/common.dart 34:3  throwToolExit
  package:flutter_tools/src/compile.dart 1024:11   DefaultResidentCompiler._compile.<fn>
  dart:async/zone_root.dart 48:47                  _rootRunUnary
  dart:async/zone.dart 816:35                      _CustomZone.runUnary
  dart:async/future_impl.dart 948:45               Future._propagateToListeners.handleValueCallback
  dart:async/future_impl.dart 977:13               Future._propagateToListeners
  dart:async/future_impl.dart 862:9                Future._propagateToListeners
  dart:async/future_impl.dart 720:5                Future._completeWithValue
  dart:async/future_impl.dart 804:7                Future._asyncCompleteWithValue.<fn>
  dart:async/zone_root.dart 35:13                  _rootRun
  dart:async/zone.dart 810:35                      _CustomZone.run
  dart:async/zone.dart 702:7                       _CustomZone.runGuarded
  dart:async/zone.dart 743:23                      _CustomZone.bindCallbackGuarded.<fn>
  dart:async/schedule_microtask.dart 40:35         _microtaskLoop
  dart:async/schedule_microtask.dart 49:5          _startMicrotaskLoop
  dart:isolate-patch/isolate_patch.dart 127:13     _runPendingImmediateCallback
  dart:isolate-patch/isolate_patch.dart 193:5      _RawReceivePort._handleMessage
  
lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
      useDataProtectionKeyChain: false,
      ^^^^^^^^^^^^^^^^^^^^^^^^^
../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
  const MacOsOptions({
        ^^^^^^^^^^^^
00:00 +0 -2: loading /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart [E]
  Failed to load "/home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart":
  Compilation failed for testPath=/home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
        useDataProtectionKeyChain: false,
        ^^^^^^^^^^^^^^^^^^^^^^^^^
  ../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
    const MacOsOptions({
          ^^^^^^^^^^^^
  .
00:00 +0 -2: loading /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart [E]
  Error: The Dart compiler exited unexpectedly.
  package:flutter_tools/src/base/common.dart 34:3  throwToolExit
  package:flutter_tools/src/compile.dart 1024:11   DefaultResidentCompiler._compile.<fn>
  dart:async/zone_root.dart 48:47                  _rootRunUnary
  dart:async/zone.dart 816:35                      _CustomZone.runUnary
  dart:async/future_impl.dart 948:45               Future._propagateToListeners.handleValueCallback
  dart:async/future_impl.dart 977:13               Future._propagateToListeners
  dart:async/future_impl.dart 862:9                Future._propagateToListeners
  dart:async/future_impl.dart 720:5                Future._completeWithValue
  dart:async/future_impl.dart 804:7                Future._asyncCompleteWithValue.<fn>
  dart:async/zone_root.dart 35:13                  _rootRun
  dart:async/zone.dart 810:35                      _CustomZone.run
  dart:async/zone.dart 702:7                       _CustomZone.runGuarded
  dart:async/zone.dart 743:23                      _CustomZone.bindCallbackGuarded.<fn>
  dart:async/schedule_microtask.dart 40:35         _microtaskLoop
  dart:async/schedule_microtask.dart 49:5          _startMicrotaskLoop
  dart:isolate-patch/isolate_patch.dart 127:13     _runPendingImmediateCallback
  dart:isolate-patch/isolate_patch.dart 193:5      _RawReceivePort._handleMessage
  
lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
      useDataProtectionKeyChain: false,
      ^^^^^^^^^^^^^^^^^^^^^^^^^
../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
  const MacOsOptions({
        ^^^^^^^^^^^^
00:00 +0 -3: loading /home/runner/work/tv-control/tv-control/apps/remote/test/shared_sync_test.dart [E]
  Failed to load "/home/runner/work/tv-control/tv-control/apps/remote/test/shared_sync_test.dart":
  Compilation failed for testPath=/home/runner/work/tv-control/tv-control/apps/remote/test/shared_sync_test.dart: lib/src/services/storage.dart:21:7: Error: No named parameter with the name 'useDataProtectionKeyChain'.
        useDataProtectionKeyChain: false,
        ^^^^^^^^^^^^^^^^^^^^^^^^^
  ../../../../../.pub-cache/hosted/pub.dev/flutter_secure_storage-10.3.4/lib/options/macos_options.dart:8:9: Context: Found this candidate, but the arguments don't match.
    const MacOsOptions({
          ^^^^^^^^^^^^
  .
00:00 +0 -3: Some tests failed.

Failing tests:
  /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: loading /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart
  /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: loading /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart
  /home/runner/work/tv-control/tv-control/apps/remote/test/shared_sync_test.dart: loading /home/runner/work/tv-control/tv-control/apps/remote/test/shared_sync_test.dart
```

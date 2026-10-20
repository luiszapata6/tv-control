# CI FAIL — f24652e5b560

Run: https://github.com/luiszapata6/tv-control/actions/runs/39344969686
Commit: feat: Android TV launcher (Flutter UI + Kotlin companion service) with tests
Job results: [
  "success",
  "failure",
  "failure"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | PASS | 2s |
| dart | atv-test | FAIL | 12s |
| dart | companion-analyze | PASS | 1s |
| dart | companion-test | PASS | 6s |
| dart | setup | PASS | 6s |
| launcher | launcher-analyze | FAIL | 6s |
| launcher | launcher-apk | FAIL | 195s |
| launcher | launcher-kotlin-tests | FAIL | 8s |
| launcher | launcher-pub | PASS | 5s |
| launcher | launcher-test | FAIL | 6s |
| python | codegen-up-to-date | PASS | 1s |
| python | pip | PASS | 5s |
| python | sim-tests | PASS | 8s |

## dart / atv-test (last 150 lines)

```
00:00 +0: loading test/protocol_test.dart
00:00 +0: test/protocol_test.dart: (setUpAll)
00:00 +0: test/integration_sim_test.dart: (setUpAll)
00:00 +1: test/integration_sim_test.dart: (setUpAll)
00:00 +2: test/integration_sim_test.dart: (setUpAll)
00:00 +3: test/integration_sim_test.dart: (setUpAll)
00:00 +4: test/integration_sim_test.dart: (setUpAll)
00:00 +4: test/protocol_test.dart: pairing flow a TV that never answers times out
00:00 +5: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +6: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +6 -1: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +6 -1: test/protocol_test.dart: remote connection keys, long presses, text and app links are sent as expected [E]
  Expected: [5, 2]
    Actual: [null, null]
     Which: at location [0] is <null> instead of <5>
  counters echo what the TV sent
  
  package:matcher                expect
  test/protocol_test.dart 153:7  main.<fn>.<fn>
  
00:00 +7 -1: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +7 -2: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +7 -2: test/protocol_test.dart: remote connection state pushes are published once per change [E]
  Expected: an object with length of <3>
    Actual: [
              AtvState:AtvState(on: true, AtvVolume(18/100), app: null, Hisense 65U6GA (5.2)),
              AtvState:AtvState(on: true, AtvVolume(18/100), app: com.google.android.tvlauncher, Hisense 65U6GA (5.2)),
              AtvState:AtvState(on: true, AtvVolume(30/100, muted), app: com.google.android.tvlauncher, Hisense 65U6GA (5.2)),
              AtvState:AtvState(on: false, AtvVolume(30/100, muted), app: com.google.android.tvlauncher, Hisense 65U6GA (5.2)),
              AtvState:AtvState(on: false, AtvVolume(30/100, muted), app: com.netflix.ninja, Hisense 65U6GA (5.2))
            ]
     Which: has length of <5>
  
  package:matcher                expect
  test/protocol_test.dart 181:7  main.<fn>.<fn>
  
00:00 +8 -2: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +9 -2: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +10 -2: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +11 -2: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +12 -2: test/integration_sim_test.dart: pairs with the code the TV shows
00:01 +13 -2: test/integration_sim_test.dart: reads name and MAC without pairing
00:01 +14 -2: test/integration_sim_test.dart: connects, reads state and drives the TV
00:01 +15 -2: test/integration_sim_test.dart: connects, reads state and drives the TV
00:01 +16 -2: test/integration_sim_test.dart: connects, reads state and drives the TV
00:01 +17 -2: test/client_test.dart: backs off while unreachable and retryNow skips the wait
00:03 +18 -2: test/client_test.dart: backs off while unreachable and retryNow skips the wait
00:04 +19 -2: test/client_test.dart: backs off while unreachable and retryNow skips the wait
00:04 +19 -3: test/integration_sim_test.dart: an unknown identity is rejected and needs pairing
00:04 +19 -3: test/client_test.dart: backs off while unreachable and retryNow skips the wait [E]
  TimeoutException after 0:00:03.000000: Future not completed
  test/client_test.dart 61:5  main.<fn>
  
00:04 +20 -3: test/client_test.dart: stops and reports needsPairing when the TV rejects the identity
00:04 +21 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +22 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +23 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +24 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +25 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +26 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +27 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +28 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +29 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +30 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +31 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +32 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +33 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +34 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +35 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +36 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +37 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +38 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +39 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +40 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +41 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +42 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +43 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +44 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +45 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +46 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +47 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +48 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +49 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +50 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +51 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +52 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +53 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +54 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +55 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +56 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +57 -3: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +58 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +59 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +60 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +61 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +62 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +63 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +64 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +65 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +66 -3: test/integration_sim_test.dart: (tearDownAll)
00:04 +67 -3: test/integration_sim_test.dart: (tearDownAll)
00:05 +68 -3: test/integration_sim_test.dart: (tearDownAll)
00:05 +69 -3: test/integration_sim_test.dart: (tearDownAll)
00:05 +70 -3: test/integration_sim_test.dart: (tearDownAll)
00:05 +70 -3: test/certificate_test.dart: parsing certificates made by the reference (cryptography) server certificate: RSA numbers, subject, signature
00:05 +71 -3: test/certificate_test.dart: parsing certificates made by the reference (cryptography) client certificate from PEM
00:05 +72 -3: test/certificate_test.dart: parsing certificates made by the reference (cryptography) garbage is rejected with AtvProtocolException
00:05 +73 -3: test/certificate_test.dart: TV subject SHIELD style common name
00:05 +74 -3: test/framing_test.dart: frames match the reference
00:05 +75 -3: test/framing_test.dart: frames match the reference
00:05 +76 -3: test/framing_test.dart: frames match the reference
00:05 +77 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +78 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +79 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +80 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +81 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +82 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +83 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +84 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +85 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +86 -3: test/certificate_test.dart: generated identity (setUpAll)
00:05 +86 -3: test/certificate_test.dart: generated identity is a valid self-signed RSA 2048 certificate
00:05 +87 -3: test/certificate_test.dart: generated identity private key PEM is PKCS#1 and matches the certificate modulus
00:05 +88 -3: test/certificate_test.dart: generated identity JSON round trip
00:05 +89 -3: test/certificate_test.dart: generated identity dart:io accepts it for TLS
00:05 +90 -3: test/certificate_test.dart: generated identity (tearDownAll)
00:05 +90 -3: test/certificate_test.dart: DER INTEGER pads positive values with a high bit
00:05 +91 -3: test/certificate_test.dart: DER OID encoding
00:05 +92 -3: test/certificate_test.dart: DER long lengths
00:05 +93 -3: test/certificate_test.dart: DER times switch to GeneralizedTime from 2050
00:05 +94 -3: Some tests failed.

Failing tests:
  test/client_test.dart: backs off while unreachable and retryNow skips the wait
  test/protocol_test.dart: remote connection keys, long presses, text and app links are sent as expected
  test/protocol_test.dart: remote connection state pushes are published once per change

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
```

## launcher / launcher-analyze (last 150 lines)

```
Analyzing launcher...                                           

   info • The import of 'dart:typed_data' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/foundation.dart'. Try removing the import directive • lib/src/home_controller.dart:2:8 • unnecessary_import
   info • The import of 'dart:typed_data' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/services.dart'. Try removing the import directive • lib/src/platform.dart:2:8 • unnecessary_import
  error • 'LauncherApp' isn't a function. Try correcting the name to match an existing function, or define a method or function named 'LauncherApp' • test/launcher_test.dart:23:29 • invocation_of_non_function
  error • The name 'LauncherApp' is defined in the libraries 'package:tv_launcher/main.dart' and 'package:tv_launcher/src/platform.dart'. Try using 'as prefix' for one of the import directives, or hiding the name from all but one of the imports • test/launcher_test.dart:23:29 • ambiguous_import

4 issues found. (ran in 6.1s)
```

## launcher / launcher-apk (last 150 lines)

```
Running Gradle task 'assembleRelease'...                        
Loading package information...                                                  
Loading local repository...                                                     
[                                       ] 3% Loading local repository...        
[                                       ] 3% Fetch remote repository...         
[=                                      ] 3% Fetch remote repository...         
[=                                      ] 4% Fetch remote repository...         
[=                                      ] 5% Fetch remote repository...         
[==                                     ] 5% Fetch remote repository...         
[==                                     ] 6% Fetch remote repository...         
[==                                     ] 7% Fetch remote repository...         
[==                                     ] 7% Computing updates...               
[===                                    ] 8% Computing updates...               
[===                                    ] 10% Computing updates...              
[===                                    ] 10% Installing NDK (Side by side) 28.2
[===                                    ] 10% Downloading android-ndk-r28c-linux
[====                                   ] 10% Downloading android-ndk-r28c-linux
[====                                   ] 11% Downloading android-ndk-r28c-linux
[====                                   ] 12% Downloading android-ndk-r28c-linux
[=====                                  ] 13% Downloading android-ndk-r28c-linux
[=====                                  ] 14% Downloading android-ndk-r28c-linux
[=====                                  ] 15% Downloading android-ndk-r28c-linux
[======                                 ] 15% Downloading android-ndk-r28c-linux
[======                                 ] 16% Downloading android-ndk-r28c-linux
[======                                 ] 17% Downloading android-ndk-r28c-linux
[=======                                ] 18% Downloading android-ndk-r28c-linux
[=======                                ] 19% Downloading android-ndk-r28c-linux
[=======                                ] 20% Downloading android-ndk-r28c-linux
[========                               ] 20% Downloading android-ndk-r28c-linux
[========                               ] 21% Downloading android-ndk-r28c-linux
[========                               ] 22% Downloading android-ndk-r28c-linux
[=========                              ] 23% Downloading android-ndk-r28c-linux
[=========                              ] 24% Downloading android-ndk-r28c-linux
[=========                              ] 25% Downloading android-ndk-r28c-linux
[==========                             ] 25% Downloading android-ndk-r28c-linux
[==========                             ] 26% Downloading android-ndk-r28c-linux
[==========                             ] 27% Downloading android-ndk-r28c-linux
[===========                            ] 28% Downloading android-ndk-r28c-linux
[===========                            ] 29% Downloading android-ndk-r28c-linux
[===========                            ] 30% Downloading android-ndk-r28c-linux
[============                           ] 30% Downloading android-ndk-r28c-linux
[============                           ] 31% Downloading android-ndk-r28c-linux
[============                           ] 32% Downloading android-ndk-r28c-linux
[============                           ] 33% Downloading android-ndk-r28c-linux
[============                           ] 33% Unzipping...                      
[============                           ] 33% Unzipping... android-ndk-r28c/    
[============                           ] 33% Unzipping... android-ndk-r28c/READ
[=============                          ] 33% Unzipping... android-ndk-r28c/READ
[=============                          ] 33% Unzipping... android-ndk-r28c/meta
[=============                          ] 33% Unzipping... android-ndk-r28c/shad
[=============                          ] 33% Unzipping... android-ndk-r28c/ndk-
[=============                          ] 33% Unzipping... android-ndk-r28c/wrap
[=============                          ] 33% Unzipping... android-ndk-r28c/ndk-
[=============                          ] 33% Unzipping... android-ndk-r28c/tool
[=============                          ] 34% Unzipping... android-ndk-r28c/tool
[=============                          ] 35% Unzipping... android-ndk-r28c/tool
[==============                         ] 35% Unzipping... android-ndk-r28c/tool
[==============                         ] 36% Unzipping... android-ndk-r28c/tool
[==============                         ] 37% Unzipping... android-ndk-r28c/tool
[===============                        ] 38% Unzipping... android-ndk-r28c/tool
[===============                        ] 39% Unzipping... android-ndk-r28c/tool
[===============                        ] 40% Unzipping... android-ndk-r28c/tool
[================                       ] 40% Unzipping... android-ndk-r28c/tool
[================                       ] 41% Unzipping... android-ndk-r28c/tool
[================                       ] 42% Unzipping... android-ndk-r28c/tool
[=================                      ] 43% Unzipping... android-ndk-r28c/tool
[=================                      ] 44% Unzipping... android-ndk-r28c/tool
[=================                      ] 45% Unzipping... android-ndk-r28c/tool
[==================                     ] 45% Unzipping... android-ndk-r28c/tool
[==================                     ] 46% Unzipping... android-ndk-r28c/tool
[==================                     ] 47% Unzipping... android-ndk-r28c/tool
[===================                    ] 48% Unzipping... android-ndk-r28c/tool
[===================                    ] 49% Unzipping... android-ndk-r28c/tool
[===================                    ] 50% Unzipping... android-ndk-r28c/tool
[====================                   ] 50% Unzipping... android-ndk-r28c/tool
[====================                   ] 51% Unzipping... android-ndk-r28c/tool
[====================                   ] 52% Unzipping... android-ndk-r28c/tool
[=====================                  ] 53% Unzipping... android-ndk-r28c/tool
[=====================                  ] 54% Unzipping... android-ndk-r28c/tool
[=====================                  ] 54% Unzipping... android-ndk-r28c/buil
[=====================                  ] 54% Unzipping... android-ndk-r28c/sour
[=====================                  ] 54% Unzipping... android-ndk-r28c/NOTI
[=====================                  ] 54% Unzipping... android-ndk-r28c/ndk-
[=====================                  ] 54% Unzipping... android-ndk-r28c/NOTI
[=====================                  ] 54% Unzipping... android-ndk-r28c/pyth
[=====================                  ] 54% Unzipping... android-ndk-r28c/preb
[=====================                  ] 54% Unzipping... android-ndk-r28c/ndk-
[=====================                  ] 54% Unzipping... android-ndk-r28c/sour
[=====================                  ] 54% Unzipping... android-ndk-r28c/simp
[=====================                  ] 55% Unzipping... android-ndk-r28c/simp
[=====================                  ] 55% Unzipping... android-ndk-r28c/CHAN
[=======================================] 100% Unzipping... android-ndk-r28c/CHA

Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 4136 bytes (99.7% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Caught exception: Already watching path: /home/runner/work/tv-control/tv-control/apps/launcher/android
e: file:///home/runner/work/tv-control/tv-control/apps/launcher/android/app/src/main/kotlin/com/luiszapata/tvcontrol/tv_launcher/core/NowPlayingTracker.kt:87:28 Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'MediaMetadata?'.
e: file:///home/runner/work/tv-control/tv-control/apps/launcher/android/app/src/main/kotlin/com/luiszapata/tvcontrol/tv_launcher/core/NowPlayingTracker.kt:88:20 Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'MediaMetadata?'.
e: file:///home/runner/work/tv-control/tv-control/apps/launcher/android/app/src/main/kotlin/com/luiszapata/tvcontrol/tv_launcher/core/NowPlayingTracker.kt:89:28 Only safe (?.) or non-null asserted (!!.) calls are allowed on a nullable receiver of type 'MediaMetadata?'.

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileReleaseKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > Compilation error. See log for more details

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 3m 12s
Running Gradle task 'assembleRelease'...                          194.1s
Gradle task assembleRelease failed with exit code 1
```

## launcher / launcher-kotlin-tests (last 150 lines)

```

Welcome to Gradle 9.3.1!

Here are the highlights of this release:
 - Test reporting improvements
 - Error and warning improvements
 - Build authoring improvements

For more details see https://docs.gradle.org/9.3.1/release-notes.html

To honour the JVM settings for this build a single-use Daemon process will be forked. For more on this, please refer to https://docs.gradle.org/9.3.1/userguide/gradle_daemon.html#sec:disabling_the_daemon in the Gradle documentation.
Daemon will be stopped at the end of the build 
> Task :gradle:checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :gradle:compileKotlin UP-TO-DATE
> Task :gradle:compileJava NO-SOURCE
> Task :gradle:compileGroovy NO-SOURCE
> Task :gradle:pluginDescriptors UP-TO-DATE
> Task :gradle:processResources UP-TO-DATE
> Task :gradle:classes UP-TO-DATE
> Task :gradle:jar UP-TO-DATE

> Configure project :app
WARNING: The option setting 'android.builtInKotlin=false' is deprecated.
The current default is 'true'.
It will be removed in version 10.0 of the Android Gradle plugin.
WARNING: The option setting 'android.newDsl=false' is deprecated.
The current default is 'true'.
It will be removed in version 10.0 of the Android Gradle plugin.
w: ⚠️ Deprecated 'org.jetbrains.kotlin.android' plugin usage
The 'org.jetbrains.kotlin.android' plugin in project ':app' is no longer required for Kotlin support since AGP 9.0.
Solution: Remove both `android.builtInKotlin=true` and `android.newDsl=false` from `gradle.properties`, then migrate to built-in Kotlin.
See https://kotl.in/gradle/agp-built-in-kotlin for more details.


[Incubating] Problems report is available at: file:///home/runner/work/tv-control/tv-control/apps/launcher/build/reports/problems/problems-report.html

FAILURE: Build failed with an exception.

* What went wrong:
Cannot locate tasks that match ':app:testReleaseUnitTest' as task 'testReleaseUnitTest' not found in project ':app'.

* Try:
> Run gradlew tasks to get a list of available tasks.
> For more on name expansion, please refer to https://docs.gradle.org/9.3.1/userguide/command_line_interface.html#sec:name_abbreviation in the Gradle documentation.
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 8s
4 actionable tasks: 4 up-to-date
```

## launcher / launcher-test (last 150 lines)

```
00:00 +0: loading /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart
test/launcher_test.dart:23:29: Error: 'LauncherApp' is imported from both 'package:tv_launcher/main.dart' and 'package:tv_launcher/src/platform.dart'.
    await tester.pumpWidget(LauncherApp(controller: controller, now: () => DateTime(2026, 10, 18, 21, 5)));
                            ^^^^^^^^^^^
00:00 +0 -1: loading /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart [E]
  Failed to load "/home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart":
  Compilation failed for testPath=/home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: test/launcher_test.dart:23:29: Error: 'LauncherApp' is imported from both 'package:tv_launcher/main.dart' and 'package:tv_launcher/src/platform.dart'.
      await tester.pumpWidget(LauncherApp(controller: controller, now: () => DateTime(2026, 10, 18, 21, 5)));
                              ^^^^^^^^^^^
  .
00:00 +0 -1: Some tests failed.

Failing tests:
  /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: loading /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart
```

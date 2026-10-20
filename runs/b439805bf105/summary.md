# CI FAIL — b439805bf105

Run: https://github.com/luiszapata6/tv-control/actions/runs/39346751458
Commit: feat: iPhone remote app, its tests, iOS build and rolling release
Job results: [
  "success",
  "success",
  "failure",
  "failure",
  "failure"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | PASS | 2s |
| dart | atv-test | PASS | 12s |
| dart | companion-analyze | PASS | 1s |
| dart | companion-test | PASS | 7s |
| dart | setup | PASS | 7s |
| ios | ios-build | FAIL | 82s |
| ios | ios-ipa | FAIL | 0s |
| ios | ios-pub | PASS | 11s |
| launcher | launcher-analyze | FAIL | 8s |
| launcher | launcher-apk | PASS | 222s |
| launcher | launcher-kotlin-tests | PASS | 44s |
| launcher | launcher-pub | PASS | 5s |
| launcher | launcher-test | FAIL | 8s |
| python | codegen-up-to-date | PASS | 0s |
| python | pip | PASS | 3s |
| python | sim-tests | PASS | 8s |
| remote | remote-analyze | FAIL | 10s |
| remote | remote-pub | PASS | 8s |
| remote | remote-test | FAIL | 11s |

## ios / ios-build (last 150 lines)

```
Warning: Building for device with codesigning disabled. You will have to manually codesign before deploying to device.
Xcode is fetching Swift Package Manager dependencies. This may take several minutes...
  Fetching from https://github.com/mattgallagher/CwlCatchException.git...     
Building com.luiszapata.tvcontrol.tvRemote for device (ios-release)...
Running Xcode build...                                          
Xcode build done.                                           58.9s
Failed to build iOS app
════════════════════════════════════════════════════════════════════════════════
Building a deployable iOS app requires a selected Development Team with a 
Provisioning Profile. Please ensure that a Development Team is selected by:
  1- Open the Flutter project's Xcode target with
       open ios/Runner.xcworkspace
  2- Select the 'Runner' project in the navigator then the 'Runner' target
     in the project settings
  3- Make sure a 'Development Team' is selected under Signing & Capabilities > Team. 
     You may need to:
         - Log in with your Apple ID in Xcode first
         - Ensure you have a valid unique Bundle ID
         - Register your device with your Apple Developer Account
         - Let Xcode automatically provision a profile for your app
  4- Build or run your project again

For more information, please visit:
  https://flutter.dev/to/ios-development-team

Or run on an iOS simulator without code signing
════════════════════════════════════════════════════════════════════════════════
Encountered error while building for device.
```

## ios / ios-ipa (last 150 lines)

```
missing apps/remote/build/ios/iphoneos/Runner.app
```

## launcher / launcher-analyze (last 150 lines)

```
Analyzing launcher...                                           

warning • The value of the local variable 'get' isn't used. Try removing the variable or using it • test/launcher_test.dart:16:18 • unused_local_variable
  error • Expected to find ';' • test/launcher_test.dart:16:18 • expected_token
  error • Functions must have an explicit list of parameters. Try adding a parameter list • test/launcher_test.dart:16:33 • missing_function_parameters
  error • Unexpected text 'set'. Try removing the text • test/launcher_test.dart:17:3 • unexpected_token
warning • The declaration 'controller' isn't referenced. Try removing the declaration of 'controller' • test/launcher_test.dart:17:7 • unused_element
  error • The name 'controller' is already defined. Try renaming one of the declarations • test/launcher_test.dart:17:7 • duplicate_definition
  error • Functions can't be assigned a value • test/launcher_test.dart:23:5 • assignment_to_function
  error • The method 'start' isn't defined for the type 'Function'. Try correcting the name to the name of an existing method, or defining a method named 'start' • test/launcher_test.dart:24:22 • undefined_method
  error • The argument type 'HomeController Function()' can't be assigned to the parameter type 'HomeController'.  • test/launcher_test.dart:25:52 • argument_type_not_assignable
  error • Functions can't be assigned a value • test/launcher_test.dart:134:7 • assignment_to_function
  error • The method 'refresh' isn't defined for the type 'Function'. Try correcting the name to the name of an existing method, or defining a method named 'refresh' • test/launcher_test.dart:135:24 • undefined_method
  error • The getter 'pinned' isn't defined for the type 'HomeController Function()'. Try importing the library that defines 'pinned', correcting the name to the name of an existing getter, or defining a getter or field named 'pinned' • test/launcher_test.dart:136:25 • undefined_getter
  error • The method 'hide' isn't defined for the type 'Function'. Try correcting the name to the name of an existing method, or defining a method named 'hide' • test/launcher_test.dart:137:24 • undefined_method
  error • The getter 'pinned' isn't defined for the type 'HomeController Function()'. Try importing the library that defines 'pinned', correcting the name to the name of an existing getter, or defining a getter or field named 'pinned' • test/launcher_test.dart:137:40 • undefined_getter
  error • The getter 'visibleApps' isn't defined for the type 'HomeController Function()'. Try importing the library that defines 'visibleApps', correcting the name to the name of an existing getter, or defining a getter or field named 'visibleApps' • test/launcher_test.dart:140:25 • undefined_getter

15 issues found. (ran in 7.1s)
```

## launcher / launcher-test (last 150 lines)

```
00:00 +0: loading /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart
test/launcher_test.dart:16:18: Error: Expected ';' after this.
  HomeController get controller => controllerRef!;
                 ^^^
test/launcher_test.dart:16:33: Error: A function declaration needs an explicit list of parameters.
Try adding a parameter list to the function declaration.
  HomeController get controller => controllerRef!;
                                ^^
test/launcher_test.dart:17:3: Error: Unexpected token 'set'.
  set controller(HomeController c) => controllerRef = c;
  ^^^
test/launcher_test.dart:17:7: Error: 'controller' is already declared in this scope.
  set controller(HomeController c) => controllerRef = c;
      ^^^^^^^^^^
test/launcher_test.dart:16:22: Context: Previous declaration of 'controller'.
  HomeController get controller => controllerRef!;
                     ^^^^^^^^^^
test/launcher_test.dart:23:5: Error: Can't assign to the final variable 'controller'.
    controller = HomeController(platform, weather: WeatherService(get: (_) async => '{"current":{"temperature_2m":22.4,"weather_code":2,"is_day":1}}'));
    ^^^^^^^^^^
test/launcher_test.dart:134:7: Error: Can't assign to the final variable 'controller'.
      controller = HomeController(platform, weather: WeatherService(get: (_) async => '{}'));
      ^^^^^^^^^^
test/launcher_test.dart:24:22: Error: The method 'start' isn't defined for the type 'HomeController Function()'.
 - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
Try correcting the name to the name of an existing method, or defining a method named 'start'.
    await controller.start();
                     ^^^^^
test/launcher_test.dart:25:52: Error: The argument type 'HomeController Function()' can't be assigned to the parameter type 'HomeController'.
 - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
    await tester.pumpWidget(TvLauncher(controller: controller, now: () => DateTime(2026, 10, 18, 21, 5)));
                                                   ^
test/launcher_test.dart:135:24: Error: The method 'refresh' isn't defined for the type 'HomeController Function()'.
 - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
Try correcting the name to the name of an existing method, or defining a method named 'refresh'.
      await controller.refresh();
                       ^^^^^^^
test/launcher_test.dart:136:25: Error: The getter 'pinned' isn't defined for the type 'HomeController Function()'.
 - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'pinned'.
      expect(controller.pinned.map((a) => a.label), ['YouTube', 'Netflix', 'Disney+']);
                        ^^^^^^
test/launcher_test.dart:137:40: Error: The getter 'pinned' isn't defined for the type 'HomeController Function()'.
 - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'pinned'.
      await controller.hide(controller.pinned.first);
                                       ^^^^^^
test/launcher_test.dart:137:24: Error: The method 'hide' isn't defined for the type 'HomeController Function()'.
 - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
Try correcting the name to the name of an existing method, or defining a method named 'hide'.
      await controller.hide(controller.pinned.first);
                       ^^^^
test/launcher_test.dart:140:25: Error: The getter 'visibleApps' isn't defined for the type 'HomeController Function()'.
 - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
Try correcting the name to the name of an existing getter, or defining a getter or field named 'visibleApps'.
      expect(controller.visibleApps.map((a) => a.label), isNot(contains('YouTube')));
                        ^^^^^^^^^^^
00:00 +0 -1: loading /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart [E]
  Failed to load "/home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart":
  Compilation failed for testPath=/home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: test/launcher_test.dart:16:18: Error: Expected ';' after this.
    HomeController get controller => controllerRef!;
                   ^^^
  test/launcher_test.dart:16:33: Error: A function declaration needs an explicit list of parameters.
  Try adding a parameter list to the function declaration.
    HomeController get controller => controllerRef!;
                                  ^^
  test/launcher_test.dart:17:3: Error: Unexpected token 'set'.
    set controller(HomeController c) => controllerRef = c;
    ^^^
  test/launcher_test.dart:17:7: Error: 'controller' is already declared in this scope.
    set controller(HomeController c) => controllerRef = c;
        ^^^^^^^^^^
  test/launcher_test.dart:16:22: Context: Previous declaration of 'controller'.
    HomeController get controller => controllerRef!;
                       ^^^^^^^^^^
  test/launcher_test.dart:23:5: Error: Can't assign to the final variable 'controller'.
      controller = HomeController(platform, weather: WeatherService(get: (_) async => '{"current":{"temperature_2m":22.4,"weather_code":2,"is_day":1}}'));
      ^^^^^^^^^^
  test/launcher_test.dart:134:7: Error: Can't assign to the final variable 'controller'.
        controller = HomeController(platform, weather: WeatherService(get: (_) async => '{}'));
        ^^^^^^^^^^
  test/launcher_test.dart:24:22: Error: The method 'start' isn't defined for the type 'HomeController Function()'.
   - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
  Try correcting the name to the name of an existing method, or defining a method named 'start'.
      await controller.start();
                       ^^^^^
  test/launcher_test.dart:25:52: Error: The argument type 'HomeController Function()' can't be assigned to the parameter type 'HomeController'.
   - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
      await tester.pumpWidget(TvLauncher(controller: controller, now: () => DateTime(2026, 10, 18, 21, 5)));
                                                     ^
  test/launcher_test.dart:135:24: Error: The method 'refresh' isn't defined for the type 'HomeController Function()'.
   - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
  Try correcting the name to the name of an existing method, or defining a method named 'refresh'.
        await controller.refresh();
                         ^^^^^^^
  test/launcher_test.dart:136:25: Error: The getter 'pinned' isn't defined for the type 'HomeController Function()'.
   - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pinned'.
        expect(controller.pinned.map((a) => a.label), ['YouTube', 'Netflix', 'Disney+']);
                          ^^^^^^
  test/launcher_test.dart:137:40: Error: The getter 'pinned' isn't defined for the type 'HomeController Function()'.
   - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'pinned'.
        await controller.hide(controller.pinned.first);
                                         ^^^^^^
  test/launcher_test.dart:137:24: Error: The method 'hide' isn't defined for the type 'HomeController Function()'.
   - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
  Try correcting the name to the name of an existing method, or defining a method named 'hide'.
        await controller.hide(controller.pinned.first);
                         ^^^^
  test/launcher_test.dart:140:25: Error: The getter 'visibleApps' isn't defined for the type 'HomeController Function()'.
   - 'HomeController' is from 'package:tv_launcher/src/home_controller.dart' ('lib/src/home_controller.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'visibleApps'.
        expect(controller.visibleApps.map((a) => a.label), isNot(contains('YouTube')));
                          ^^^^^^^^^^^
  .
00:00 +0 -1: Some tests failed.

Failing tests:
  /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: loading /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart
```

## remote / remote-analyze (last 150 lines)

```
Analyzing remote...                                             

   info • 'onReorder' is deprecated and shouldn't be used. Use the onReorderItem callback instead. The onReorderItem callback adjusts the newIndex parameter for a removed item at the oldIndex. This feature was deprecated after v3.41.0-0.0.pre. Try replacing the use of the deprecated member with the replacement • lib/src/screens/home/apps_page.dart:311:9 • deprecated_member_use
   info • Unnecessary use of multiple underscores. Try using '_' • lib/src/screens/home/control_page.dart:251:31 • unnecessary_underscores
   info • Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' • lib/src/screens/home/settings_sheet.dart:37:55 • use_null_aware_elements
   info • Unnecessary use of multiple underscores. Try using '_' • lib/src/screens/onboarding/discover_screen.dart:93:49 • unnecessary_underscores
   info • 'localeId' is deprecated and shouldn't be used. Use SpeechListenOptions.localeId instead. Try replacing the use of the deprecated member with the replacement • lib/src/services/dictation.dart:27:7 • deprecated_member_use
   info • 'listenFor' is deprecated and shouldn't be used. Use SpeechListenOptions.listenFor instead. Try replacing the use of the deprecated member with the replacement • lib/src/services/dictation.dart:28:7 • deprecated_member_use
   info • 'pauseFor' is deprecated and shouldn't be used. Use SpeechListenOptions.pauseFor instead. Try replacing the use of the deprecated member with the replacement • lib/src/services/dictation.dart:29:7 • deprecated_member_use
   info • The import of 'dart:typed_data' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/foundation.dart'. Try removing the import directive • lib/src/services/tv_session.dart:2:8 • unnecessary_import
   info • Use the null-aware marker '?' rather than a null check via an 'if'. Try using '?' • lib/src/services/tv_session.dart:351:9 • use_null_aware_elements
  error • Invalid constant value • lib/src/theme/theme.dart:37:27 • invalid_constant
  error • The function 'CupertinoPageTransitionsBuilder' isn't defined. Try importing the library that defines 'CupertinoPageTransitionsBuilder', correcting the name to the name of an existing function, or defining a function named 'CupertinoPageTransitionsBuilder' • lib/src/theme/theme.dart:37:27 • undefined_function
  error • The values in a const map literal must be constant. Try removing the keyword 'const' from the map literal • lib/src/theme/theme.dart:37:27 • non_constant_map_value
  error • The function 'CupertinoPageTransitionsBuilder' isn't defined. Try importing the library that defines 'CupertinoPageTransitionsBuilder', correcting the name to the name of an existing function, or defining a function named 'CupertinoPageTransitionsBuilder' • lib/src/theme/theme.dart:38:29 • undefined_function
  error • The values in a const map literal must be constant. Try removing the keyword 'const' from the map literal • lib/src/theme/theme.dart:38:29 • non_constant_map_value
  error • The function 'CupertinoPageTransitionsBuilder' isn't defined. Try importing the library that defines 'CupertinoPageTransitionsBuilder', correcting the name to the name of an existing function, or defining a function named 'CupertinoPageTransitionsBuilder' • lib/src/theme/theme.dart:39:31 • undefined_function
  error • The values in a const map literal must be constant. Try removing the keyword 'const' from the map literal • lib/src/theme/theme.dart:39:31 • non_constant_map_value
warning • Unused import: 'package:material_symbols_icons/symbols.dart'. Try removing the import directive • lib/src/widgets/common.dart:4:8 • unused_import

17 issues found. (ran in 8.9s)
```

## remote / remote-test (last 150 lines)

```
00:00 +0: loading /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart
00:00 +0: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: (setUpAll)
00:00 +0: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: connects and mirrors the TV state
00:00 +1: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: volume drag steps the TV towards the target
lib/src/theme/theme.dart:37:27: Error: Method not found: 'CupertinoPageTransitionsBuilder'.
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
lib/src/theme/theme.dart:38:29: Error: Method not found: 'CupertinoPageTransitionsBuilder'.
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
lib/src/theme/theme.dart:39:31: Error: Method not found: 'CupertinoPageTransitionsBuilder'.
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
00:01 +2: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: text mirroring: full text, then deletes when cleared
00:01 +3: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: power wakes the TV over the network when it is not connected
00:01 +4: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: without the launcher, apps fall back to well-known ones and app links
00:01 +5: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: companion: pairing, real apps, launching and layout
00:01 +6: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: companion: a stored token connects directly
00:01 +7: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: device store save, select, remove and persist
00:01 +8: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: device store identity is generated once and kept in the secret store
00:01 +9: /home/runner/work/tv-control/tv-control/apps/remote/test/session_test.dart: (tearDownAll)
00:02 +9 -1: loading /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart [E]
  Failed to load "/home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart":
  Compilation failed for testPath=/home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: lib/src/theme/theme.dart:37:27: Error: Method not found: 'CupertinoPageTransitionsBuilder'.
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  lib/src/theme/theme.dart:38:29: Error: Method not found: 'CupertinoPageTransitionsBuilder'.
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  lib/src/theme/theme.dart:39:31: Error: Method not found: 'CupertinoPageTransitionsBuilder'.
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  .
00:02 +9 -1: Some tests failed.

Failing tests:
  /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: loading /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart
```

# CI FAIL — c4323b48631f

Run: https://github.com/luiszapata6/tv-control/actions/runs/39347637306
Commit: fix: audit findings in protocol client and iPhone app; xcodebuild iOS build; ADB install scripts
Job results: [
  "success",
  "failure",
  "failure",
  "failure",
  "success"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | PASS | 1s |
| dart | atv-test | FAIL | 11s |
| dart | companion-analyze | PASS | 1s |
| dart | companion-test | PASS | 6s |
| dart | setup | PASS | 5s |
| ios | ios-build | PASS | 137s |
| ios | ios-ipa | PASS | 2s |
| ios | ios-pub | PASS | 13s |
| launcher | launcher-analyze | FAIL | 8s |
| launcher | launcher-apk | PASS | 214s |
| launcher | launcher-kotlin-tests | PASS | 44s |
| launcher | launcher-pub | PASS | 5s |
| launcher | launcher-test | FAIL | 9s |
| python | codegen-up-to-date | PASS | 0s |
| python | pip | PASS | 4s |
| python | sim-tests | PASS | 8s |
| remote | remote-analyze | FAIL | 12s |
| remote | remote-pub | PASS | 9s |
| remote | remote-test | FAIL | 24s |

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
00:00 +7: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +8: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +9: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +10: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +11: test/integration_sim_test.dart: pairs with the code the TV shows
00:00 +12: test/protocol_test.dart: remote connection a TV that never sends remote_start times out
00:00 +13: test/protocol_test.dart: remote connection a TV that never sends remote_start times out
00:00 +14: test/integration_sim_test.dart: connects, reads state and drives the TV
00:00 +15: test/integration_sim_test.dart: connects, reads state and drives the TV
00:00 +16: test/integration_sim_test.dart: connects, reads state and drives the TV
00:01 +17: test/integration_sim_test.dart: connects, reads state and drives the TV
00:01 +18: test/integration_sim_test.dart: connects, reads state and drives the TV
00:01 +19: test/integration_sim_test.dart: connects, reads state and drives the TV
00:01 +20: test/client_test.dart: stops and reports needsPairing when the TV rejects the identity
00:01 +21: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +21 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +21 -1: test/client_test.dart: repeated handshake drops end in needsPairing, a single one does not [E]
  Bad state: Cannot fire new event. Controller is already firing an event
  dart:async                                 _BroadcastStreamController.add
  package:atv_remote/src/client.dart 78:36   AtvClient._setStatus
  package:atv_remote/src/client.dart 196:5   AtvClient.stop
  package:atv_remote/src/client.dart 201:11  AtvClient.dispose
  test/client_test.dart 90:18                main.<fn>
  
00:01 +22 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +23 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +24 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +25 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +26 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +27 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +28 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +29 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +30 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +31 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +32 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +33 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +34 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +35 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +36 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +37 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +38 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +39 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +40 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +41 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +42 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +43 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +44 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +45 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +46 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +47 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +48 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +49 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +50 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +51 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +52 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +53 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +54 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +55 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +56 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +57 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +58 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +59 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +60 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +61 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +62 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +63 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +64 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +65 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +66 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +67 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +68 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:01 +69 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +70 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +71 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +72 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +73 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +74 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +75 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +76 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +77 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +78 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +79 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +80 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +81 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +82 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +83 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +84 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +85 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +86 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +87 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +88 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +89 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +90 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +91 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +92 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +93 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +94 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +95 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:02 +96 -1: test/integration_sim_test.dart: receives changes made on the TV and answers pings
00:03 +97 -1: test/integration_sim_test.dart: client reconnects after the TV drops the connection
00:03 +98 -1: test/integration_sim_test.dart: an unknown identity is rejected and needs pairing
00:04 +99 -1: test/integration_sim_test.dart: a wrong code is rejected by the TV
00:04 +100 -1: test/integration_sim_test.dart: (tearDownAll)
00:04 +100 -1: Some tests failed.

Failing tests:
  test/client_test.dart: repeated handshake drops end in needsPairing, a single one does not

Consider enabling the flag chain-stack-traces to receive more detailed exceptions.
For example, 'dart test --chain-stack-traces'.
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

15 issues found. (ran in 7.6s)
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

  error • The function 'FakeConnector' isn't defined. Try importing the library that defines 'FakeConnector', correcting the name to the name of an existing function, or defining a function named 'FakeConnector' • test/session_test.dart:83:20 • undefined_function
  error • The function 'FakeRemoteTv' isn't defined. Try importing the library that defines 'FakeRemoteTv', correcting the name to the name of an existing function, or defining a function named 'FakeRemoteTv' • test/session_test.dart:83:68 • undefined_function

2 issues found. (ran in 11.2s)
```

## remote / remote-test (last 150 lines)

```
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:03 +2 -8: /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: remote apps page opens well-known apps without the launcher [E]
  Test failed. See exception logs above.
  The test description was: apps page opens well-known apps without the launcher
  
00:03 +2 -8: /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: remote settings sheet lists TVs and changes the accent
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 2.0 pixels on the bottom.

The relevant error-causing widget was:
  Column
  Column:file:///home/runner/work/tv-control/tv-control/apps/remote/lib/src/screens/home/header.dart:148:30

The overflowing RenderFlex has an orientation of Axis.vertical.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#58442 relayoutBoundary=up7 OVERFLOWING:
  creator: Column ← Padding ← DecoratedBox ← Container ← AnimatedContainer ← Transform ←
    ScaleTransition ← AnimatedScale ← TweenAnimationBuilder<double> ← Opacity ← Listener ← Semantics ←
    ⋯
  parentData: offset=Offset(0.0, 0.0) (can use size)
  constraints: BoxConstraints(w=84.0, 0.0<=h<=54.0)
  size: Size(84.0, 54.0)
  direction: vertical
  mainAxisAlignment: center
  mainAxisSize: max
  crossAxisAlignment: center
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 8.8 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///home/runner/work/tv-control/tv-control/apps/remote/lib/src/screens/home/control_page.dart:144:22

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#c257a OVERFLOWING:
  creator: Row ← SizedBox ← Padding ← DecoratedBox ← Container ← Surface ← Transform ← ScaleTransition
    ← AnimatedScale ← TweenAnimationBuilder<double> ← Opacity ← Listener ← ⋯
  parentData: <none> (can use size)
  constraints: BoxConstraints(w=106.7, h=60.0)
  size: Size(106.7, 60.0)
  direction: horizontal
  mainAxisAlignment: center
  mainAxisSize: max
  crossAxisAlignment: center
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════
The following assertion was thrown:
ListTile background color or ink splashes may be invisible.
The ListTile is wrapped in a DecoratedBox that has a background color. Because ListTile paints its
background and ink splashes on the nearest Material ancestor, this DecoratedBox will hide those
effects.
To fix this, wrap the ListTile in its own Material widget, or remove the background color from the
intermediate DecoratedBox.

ListTile:
  ListTile(selectedColor: Color(alpha: 1.0000, red: 0.5412, green: 0.5922, blue: 1.0000, colorSpace: ColorSpace.sRGB), onTap: Closure: () => void)
DecoratedBox:
  DecoratedBox(bg: BoxDecoration(color: Color(alpha: 1.0000, red: 0.1176, green: 0.1412, blue: 0.2118, colorSpace: ColorSpace.sRGB), border: Border.all(BorderSide(color: Color(alpha: 0.0510, red: 1.0000, green: 1.0000, blue: 1.0000, colorSpace: ColorSpace.sRGB))), borderRadius: BorderRadius.circular(22.0)))
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 9.5 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///home/runner/work/tv-control/tv-control/apps/remote/lib/src/screens/home/settings_sheet.dart:139:32

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#94ee3 OVERFLOWING:
  creator: Row ← Padding ← DecoratedBox ← ConstrainedBox ← Container ← AnimatedContainer ← Transform ←
    ScaleTransition ← AnimatedScale ← TweenAnimationBuilder<double> ← Opacity ← Listener ← ⋯
  parentData: offset=Offset(2.0, 2.0) (can use size)
  constraints: BoxConstraints(w=106.0, h=60.0)
  size: Size(106.0, 60.0)
  direction: horizontal
  mainAxisAlignment: center
  mainAxisSize: max
  crossAxisAlignment: center
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER FRAMEWORK ╞═════════════════════════════════════════════════════════
The following assertion was thrown:
ListTile background color or ink splashes may be invisible.
The ListTile is wrapped in a DecoratedBox that has a background color. Because ListTile paints its
background and ink splashes on the nearest Material ancestor, this DecoratedBox will hide those
effects.
To fix this, wrap the ListTile in its own Material widget, or remove the background color from the
intermediate DecoratedBox.

ListTile:
  ListTile(selectedColor: Color(alpha: 1.0000, red: 0.9686, green: 0.7412, blue: 0.3608, colorSpace: ColorSpace.sRGB), onTap: Closure: () => void)
DecoratedBox:
  DecoratedBox(bg: BoxDecoration(color: Color(alpha: 1.0000, red: 0.1176, green: 0.1412, blue: 0.2118, colorSpace: ColorSpace.sRGB), border: Border.all(BorderSide(color: Color(alpha: 0.0510, red: 1.0000, green: 1.0000, blue: 1.0000, colorSpace: ColorSpace.sRGB))), borderRadius: BorderRadius.circular(22.0)))
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (5) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:03 +2 -9: /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: remote settings sheet lists TVs and changes the accent [E]
  Test failed. See exception logs above.
  The test description was: settings sheet lists TVs and changes the accent
  
00:03 +2 -9: /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: (tearDownAll)
00:03 +2 -9: Some tests failed.

Failing tests:
  /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: pairing with the code shown on the TV saves it and opens the remote
  /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: remote D-pad, OK and navigation buttons send keys
  /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: remote apps page opens well-known apps without the launcher
  /home/runner/work/tv-control/tv-control/apps/remote/test/app_test.dart: remote dock switches pages: touchpad gestures and keyboard text
  ... and 5 more
```

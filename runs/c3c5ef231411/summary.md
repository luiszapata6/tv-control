# CI FAIL — c3c5ef231411

Run: https://github.com/luiszapata6/tv-control/actions/runs/39345707206
Commit: fix: reconnect race, launcher name clash and Kotlin nullability; WIP iPhone app
Job results: [
  "success",
  "success",
  "failure"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | PASS | 1s |
| dart | atv-test | PASS | 11s |
| dart | companion-analyze | PASS | 1s |
| dart | companion-test | PASS | 5s |
| dart | setup | PASS | 6s |
| launcher | launcher-analyze | FAIL | 8s |
| launcher | launcher-apk | PASS | 201s |
| launcher | launcher-kotlin-tests | FAIL | 36s |
| launcher | launcher-pub | PASS | 5s |
| launcher | launcher-test | FAIL | 11s |
| python | codegen-up-to-date | PASS | 0s |
| python | pip | PASS | 4s |
| python | sim-tests | PASS | 9s |

## launcher / launcher-analyze (last 150 lines)

```
Analyzing launcher...                                           

   info • The import of 'package:flutter/material.dart' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/services.dart'. Try removing the import directive • test/launcher_test.dart:2:8 • unnecessary_import

1 issue found. (ran in 7.4s)
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


> Task :app:checkKotlinGradlePluginConfigurationErrors SKIPPED
> Task :app:cleanMergeDebugAssets UP-TO-DATE
> Task :app:compileFlutterBuildDebug
> Task :app:generateDebugAssets UP-TO-DATE
> Task :app:validateCompileSdkVersion
> Task :app:preBuild
> Task :app:preDebugBuild
> Task :app:mergeDebugAssets
> Task :app:copyFlutterAssetsDebug
> Task :app:generateDebugResources
> Task :app:packageDebugResources
> Task :app:processDebugNavigationResources
> Task :app:javaPreCompileDebug
> Task :app:mapDebugSourceSetPaths
> Task :app:checkDebugAarMetadata
> Task :app:parseDebugLocalResources
> Task :app:compileDebugNavigationResources
> Task :app:generateDebugRFile
> Task :app:mergeDebugResources
> Task :app:createDebugCompatibleScreenManifests
> Task :app:extractDeepLinksDebug
> Task :app:processDebugMainManifest
> Task :app:outputDebugAppLinkSettings
> Task :app:processDebugManifest
> Task :app:preDebugUnitTestBuild
> Task :app:javaPreCompileDebugUnitTest
> Task :app:processDebugManifestForPackage
> Task :app:processDebugResources
> Task :app:compileDebugKotlin
> Task :app:compileDebugJavaWithJavac
> Task :app:bundleDebugClassesToCompileJar
> Task :app:bundleDebugClassesToRuntimeJar
> Task :app:processDebugJavaRes

> Task :app:compileDebugUnitTestKotlin FAILED
e: file:///home/runner/work/tv-control/tv-control/apps/launcher/android/app/src/test/kotlin/com/luiszapata/tvcontrol/tv_launcher/companion/CompanionHandlerTest.kt:94:26 Unresolved reference 'similar'.
e: file:///home/runner/work/tv-control/tv-control/apps/launcher/android/app/src/test/kotlin/com/luiszapata/tvcontrol/tv_launcher/companion/FixturesTest.kt:21:69 Unresolved reference 'similar'.

[Incubating] Problems report is available at: file:///home/runner/work/tv-control/tv-control/apps/launcher/build/reports/problems/problems-report.html

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileDebugUnitTestKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > Compilation error. See log for more details

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

Deprecated Gradle features were used in this build, making it incompatible with Gradle 10.

You can use '--warning-mode all' to show the individual deprecation warnings and determine if they come from your own scripts or plugins.

For more on this, please refer to https://docs.gradle.org/9.3.1/userguide/command_line_interface.html#sec:command_line_warnings in the Gradle documentation.

BUILD FAILED in 35s
33 actionable tasks: 28 executed, 5 up-to-date
```

## launcher / launcher-test (last 150 lines)

```
The following assertion was thrown during layout:
A RenderFlex overflowed by 84 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///home/runner/work/tv-control/tv-control/apps/launcher/lib/src/screens/home_screen.dart:107:12

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#8b8b5 relayoutBoundary=up4 OVERFLOWING:
  creator: Row ← _Header ← Column ← Padding ← Stack ← ListenableBuilder ←
    KeyedSubtree-[GlobalKey#18b20] ← _BodyBuilder ← MediaQuery ← LayoutId-[<_ScaffoldSlot.body>] ←
    CustomMultiChildLayout ← _ActionsScope ← ⋯
  parentData: offset=Offset(0.0, 0.0); flex=null; fit=null (can use size)
  constraints: BoxConstraints(0.0<=w<=840.0, 0.0<=h<=Infinity)
  size: Size(840.0, 111.0)
  direction: horizontal
  mainAxisAlignment: start
  mainAxisSize: max
  crossAxisAlignment: end
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
00:01 +0 -8: layout changes from the iPhone update the grid [E]
  Test failed. See exception logs above.
  The test description was: layout changes from the iPhone update the grid
  
00:01 +0 -8: settings cycles grid columns

Warning: A call to tap() with finder "Found 1 widget with a semantics label named "Ajustes": [
  Semantics(container: false, properties: SemanticsProperties, label: "Ajustes", dependencies: [Directionality], renderObject: RenderSemanticsAnnotations#831fb),
]" derived an Offset (Offset(1916.0, 258.0)) that would not hit test on the specified widget.
Maybe the widget is actually off-screen, or another widget is obscuring it, or the widget cannot receive pointer events.
The finder corresponds to this RenderBox: RenderSemanticsAnnotations#831fb
The hit test result at that offset is: HitTestResult(_RenderInkFeatures#c1af3@Offset(958.0, 129.0), RenderPhysicalModel#2bcb7@Offset(958.0, 129.0), RenderSemanticsAnnotations#e7e23@Offset(958.0, 129.0), RenderRepaintBoundary#f63cc@Offset(958.0, 129.0), RenderIgnorePointer#da133@Offset(958.0, 129.0), RenderAnimatedOpacity#b99fd@Offset(958.0, 129.0), RenderAnimatedOpacity#1b337@Offset(958.0, 129.0), _RenderColoredBox#daf90@Offset(958.0, 129.0), RenderAnimatedOpacity#7f4b5@Offset(958.0, 129.0), RenderIgnorePointer#17883@Offset(958.0, 129.0), RenderAnimatedOpacity#383b7@Offset(958.0, 129.0), RenderRepaintBoundary#2fb60@Offset(958.0, 129.0), RenderSemanticsAnnotations#44905@Offset(958.0, 129.0), RenderOffstage#58675@Offset(958.0, 129.0), RenderSemanticsAnnotations#5b7b0@Offset(958.0, 129.0), _RenderTheater#bd5e6@Offset(958.0, 129.0), RenderAbsorbPointer#0857f@Offset(958.0, 129.0), RenderPointerListener#d134e@Offset(958.0, 129.0), RenderSemanticsAnnotations#945ad@Offset(958.0, 129.0), RenderConstrainedBox#a1c14@Offset(958.0, 129.0), RenderFittedBox#f8453@Offset(1916.0, 258.0), _RenderColoredBox#105d0@Offset(1916.0, 258.0), RenderSemanticsAnnotations#1a180@Offset(1916.0, 258.0), RenderSemanticsAnnotations#67c38@Offset(1916.0, 258.0), RenderSemanticsAnnotations#e416a@Offset(1916.0, 258.0), RenderTapRegionSurface#889cf@Offset(1916.0, 258.0), RenderSemanticsAnnotations#aa7b0@Offset(1916.0, 258.0), RenderSemanticsAnnotations#88e60@Offset(1916.0, 258.0), RenderSemanticsAnnotations#0b8d2@Offset(1916.0, 258.0), HitTestEntry<HitTestTarget>#0440a(_ReusableRenderView#25df7), HitTestEntry<HitTestTarget>#71fb9(<AutomatedTestWidgetsFlutterBinding>))
#0      WidgetController._getElementPoint (package:flutter_test/src/controller.dart:2165:25)
#1      WidgetController.getCenter (package:flutter_test/src/controller.dart:1947:12)
#2      WidgetController.tap (package:flutter_test/src/controller.dart:1080:7)
#3      main.<anonymous closure> (file:///home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart:116:18)
<asynchronous suspension>
#4      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#5      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1953:5)
<asynchronous suspension>
#6      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
To silence this warning, pass "warnIfMissed: false" to "tap()".
To make this warning fatal, set WidgetController.hitTestWarningShouldBeFatal to true.

══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞═════════════════════════════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 84 pixels on the right.

The relevant error-causing widget was:
  Row
  Row:file:///home/runner/work/tv-control/tv-control/apps/launcher/lib/src/screens/home_screen.dart:107:12

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and
black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the
RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be
seen. If the content is legitimately bigger than the available space, consider clipping it with a
ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex,
like a ListView.
The specific RenderFlex in question is: RenderFlex#89ae6 relayoutBoundary=up4 OVERFLOWING:
  creator: Row ← _Header ← Column ← Padding ← Stack ← ListenableBuilder ←
    KeyedSubtree-[GlobalKey#5e96a] ← _BodyBuilder ← MediaQuery ← LayoutId-[<_ScaffoldSlot.body>] ←
    CustomMultiChildLayout ← _ActionsScope ← ⋯
  parentData: offset=Offset(0.0, 0.0); flex=null; fit=null (can use size)
  constraints: BoxConstraints(0.0<=w<=840.0, 0.0<=h<=Infinity)
  size: Size(840.0, 111.0)
  direction: horizontal
  mainAxisAlignment: start
  mainAxisSize: max
  crossAxisAlignment: end
  textDirection: ltr
  verticalDirection: down
  spacing: 0.0
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following TestFailure was thrown running a test:
Expected: exactly one matching candidate
  Actual: _TextWidgetFinder:<Found 0 widgets with text "Columnas en inicio": []>
   Which: means none were found but one was expected

When the exception was thrown, this was the stack:
#4      main.<anonymous closure> (file:///home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart:118:5)
<asynchronous suspension>
#5      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:15)
<asynchronous suspension>
#6      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1953:5)
<asynchronous suspension>
<asynchronous suspension>
(elided one frame from package:stack_trace)

This was caught by the test expectation on the following line:
  file:///home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart line 118
The test description was:
  settings cycles grid columns
════════════════════════════════════════════════════════════════════════════════════════════════════
══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════════════════════════════════════════════════════
The following message was thrown:
Multiple exceptions (2) were detected during the running of the current test, and at least one was
unexpected.
════════════════════════════════════════════════════════════════════════════════════════════════════
00:02 +0 -9: settings cycles grid columns [E]
  Test failed. See exception logs above.
  The test description was: settings cycles grid columns
  
00:02 +0 -9: controller without a layout, non-system apps are suggested and editing materializes them
00:02 +1 -9: formatting and weather dates in Spanish
00:02 +1 -10: formatting and weather dates in Spanish [E]
  A HomeController was used after being disposed.
  Once you have called dispose() on a HomeController, it can no longer be used.
  package:flutter/src/foundation/change_notifier.dart 184:9   ChangeNotifier.debugAssertNotDisposed.<fn>
  package:flutter/src/foundation/change_notifier.dart 191:6   ChangeNotifier.debugAssertNotDisposed
  package:flutter/src/foundation/change_notifier.dart 377:27  ChangeNotifier.dispose
  package:tv_launcher/src/home_controller.dart 146:11         HomeController.dispose
  test/launcher_test.dart 28:29                               main.<fn>
  
00:02 +1 -10: formatting and weather open-meteo parsing
00:02 +1 -11: formatting and weather open-meteo parsing [E]
  A HomeController was used after being disposed.
  Once you have called dispose() on a HomeController, it can no longer be used.
  package:flutter/src/foundation/change_notifier.dart 184:9   ChangeNotifier.debugAssertNotDisposed.<fn>
  package:flutter/src/foundation/change_notifier.dart 191:6   ChangeNotifier.debugAssertNotDisposed
  package:flutter/src/foundation/change_notifier.dart 377:27  ChangeNotifier.dispose
  package:tv_launcher/src/home_controller.dart 146:11         HomeController.dispose
  test/launcher_test.dart 28:29                               main.<fn>
  
00:02 +1 -11: Some tests failed.

Failing tests:
  /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: D-pad moves focus and select opens the app
  /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: HDMI input opens
  /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: all apps lists every visible app and can pin one
  /home/runner/work/tv-control/tv-control/apps/launcher/test/launcher_test.dart: formatting and weather dates in Spanish
  ... and 7 more
```

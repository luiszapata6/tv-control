# R8 rewrites WebSocketServer.run() (synchronized blocks) into bytecode that
# Android 9's verifier rejects (VerifyError: "expected to be within a
# catch-all ... monitor is held"); the Hisense runs Android 9. Leave the
# library as compiled.
-keep class org.java_websocket.** { *; }

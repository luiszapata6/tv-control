# CI PASS — 196b54d5dade

Run: https://github.com/luiszapata6/tv-control/actions/runs/39528893806
Commit: fix(install): restore re-enabled only the first package (adb shell ate the loop's stdin); verified install/restore round trip on a Google TV 14 emulator
Job results: [
  "success",
  "success",
  "cancelled",
  "success",
  "cancelled"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | PASS | 2s |
| dart | atv-test | PASS | 11s |
| dart | companion-analyze | PASS | 1s |
| dart | companion-test | PASS | 6s |
| dart | setup | PASS | 4s |
| ios | ios-pub | PASS | 2s |
| launcher | launcher-analyze | PASS | 8s |
| launcher | launcher-pub | PASS | 1s |
| launcher | launcher-test | PASS | 11s |
| python | codegen-up-to-date | PASS | 1s |
| python | pip | PASS | 5s |
| python | sim-tests | PASS | 8s |
| remote | remote-analyze | PASS | 11s |
| remote | remote-pub | PASS | 6s |
| remote | remote-test | PASS | 16s |

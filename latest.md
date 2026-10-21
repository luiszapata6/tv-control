# CI FAIL — 82837428efc4

Run: https://github.com/luiszapata6/tv-control/actions/runs/39545130772
Commit: fix(ios): 'Encender/Apagar la TV' read the TV's state and press power only if needed (the Hisense ignores SLEEP/WAKEUP); handoff with Fase 0 results
Job results: [
  "success",
  "success",
  "failure",
  "success",
  "success"
]

| job | step | result | time |
| --- | --- | --- | --- |
| dart | atv-analyze | PASS | 1s |
| dart | atv-test | PASS | 12s |
| dart | companion-analyze | PASS | 1s |
| dart | companion-test | PASS | 7s |
| dart | setup | PASS | 8s |
| ios | ios-build | PASS | 165s |
| ios | ios-ipa | PASS | 1s |
| ios | ios-pub | PASS | 2s |
| ios | macos-build | PASS | 143s |
| python | codegen-up-to-date | PASS | 0s |
| python | pip | PASS | 4s |
| python | sim-tests | PASS | 8s |
| remote | remote-analyze | PASS | 13s |
| remote | remote-pub | PASS | 1s |
| remote | remote-test | PASS | 19s |

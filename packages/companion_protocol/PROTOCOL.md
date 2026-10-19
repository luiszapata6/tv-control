# Companion protocol v1

The launcher on the TV runs a small WebSocket server so the iPhone can do what
the Android TV Remote protocol cannot: list installed apps with their icons,
open any app, rearrange the launcher, list HDMI inputs, see what is playing,
read usage, and back up the launcher configuration.

* Transport: WebSocket, `ws://<tv>:7790/v1`, UTF-8 JSON text frames.
* Discovery: mDNS `_tvcontrol._tcp`, TXT `v=1`, `id=<device id>`, `name=<tv name>`.
* Every frame is a JSON object with a `type`.

## Requests and responses

Requests carry an integer `id`; the answer echoes it.

```json
{"id": 3, "type": "apps.launch", "package": "com.netflix.ninja"}
{"id": 3, "type": "result", "data": {}}
{"id": 3, "type": "error", "code": "not_found", "message": "app not installed"}
```

Error codes: `auth_required`, `bad_code`, `locked`, `not_found`, `bad_request`,
`unsupported`, `internal`.

## Authentication

1. `hello` `{client, version, token?}` — first frame. Valid token: result
   `{authenticated: true, server: {name, version, deviceId}}`. Otherwise
   error `auth_required`.
2. `pair.request` `{client}` — the TV shows a 6 digit code. Result `{pending: true}`.
3. `pair.confirm` `{code}` — result `{token}`; error `bad_code`; after 5 wrong
   codes `locked` for 60 s. The token is 32 random bytes, base64url.

Until authenticated only `hello`, `pair.request`, `pair.confirm` and `ping`
are accepted.

## Methods

| type | request | result `data` |
| --- | --- | --- |
| `ping` | | `{time}` epoch ms |
| `apps.list` | | `{apps: [App]}` |
| `apps.icon` | `{package}` | `{package, png}` base64 PNG, max 192 px |
| `apps.launch` | `{package}` | `{}` |
| `launcher.get` | | `{layout: Layout}` |
| `launcher.set` | `{layout: Layout}` | `{layout: Layout}` |
| `inputs.list` | | `{inputs: [Input]}` |
| `inputs.open` | `{input}` (an Input id) | `{}` |
| `nowPlaying.get` | | `{nowPlaying: NowPlaying \| null}` |
| `usage.get` | `{days}` 1..30 | `{since, entries: [Usage]}` |
| `backup.export` | | `{backup: Backup}` |
| `backup.import` | `{backup: Backup}` | `{layout: Layout}` |

* App: `{package, label, versionCode, isSystem}`
* Layout: `{order: [package], hidden: [package], columns}` (columns 4..8)
* Input: `{id, label, kind}` kind is `hdmi`, `tuner` or `other`
* NowPlaying: `{package, title, subtitle?, state, positionMs?, durationMs?}`, state is `playing`, `paused`, `buffering` or `stopped`
* Usage: `{package, label, foregroundMs}`
* Backup: `{version: 1, layout: Layout, exportedAt}`

## Events

Pushed by the TV after authentication: `{"type": "event", "event": <name>, "data": {...}}`

| event | data |
| --- | --- |
| `nowPlaying` | `{nowPlaying: NowPlaying \| null}` |
| `foregroundApp` | `{package}` |
| `layoutChanged` | `{layout: Layout}` |
| `appsChanged` | `{}` |
| `pairingCode` | never sent to clients; the launcher shows it on screen |

`fixtures/messages.json` holds one example of every frame. Both the Dart
client and the Kotlin server tests parse and re-encode them.

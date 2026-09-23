# Known-Good Settings

Captured live from `http://192.168.4.1/status` on **2026-09-22** after a full reset-to-defaults plus the intentional changes below. Verified working: face detection, lock, and laser hold steady on a stationary target (no more ~1.5 s lock-loss cycle).

## Intentional changes vs. code defaults

| Setting | Live value | Code default | Purpose |
|---|---|---|---|
| deadbandPx | 41 | 12 | Wider no-correction radius, calmer holding |
| invertPan | true | false | Pan servo wiring direction |
| invertTilt | true | false | Tilt servo wiring direction |
| scanSpeed | 9.0 | 25.0 | Slower lost-target sweep |
| scanTilt | 88.0 | 90.0 | Scan altitude |
| trackTiltMax | 84.0 | 110.0 | Tracking never tilts above this |
| aimFrac | 0.65 | 0.25 | Aim lower down the body box |
| personThr | 0.85 | 0.5 | Stricter person-box score threshold |
| faceTimeout | 25000 ms | 1500 ms | Long grace before dropping color torso track |
| autoFire | true | false | Laser follows lock state |
| motionMinCells | 49 | 3 | Higher motion trigger bar |
| hmirror | true | false | Mirror image for web view |

All other settings are at code defaults (kp=18, smooth=0.35, maxStep=3, settle=350, lost=2500, scan=true, lockMs=600, lockRelease=3.0, aimBelow=2.30, torso=true, redetect=300, torsoConf=0.12, autoFire aside, mthr=22, quality=80, panTrim=0, tiltTrim=0, bootMode=1/Person, mode=Person, detector=espdet-person, vflip=false).

## Full live status snapshot (2026-09-22, untracked/scanning state)

```json
{"mode":1,"pan":53.6,"tilt":88.0,"panSet":53.3,"tiltSet":88.0,"found":false,"fresh":false,"tx":0,"ty":0,"tw":0,"th":0,"score":0.00,"locked":false,"scanning":true,"laser":false,"moving":true,"fps":4.0,"infer":194,"rssi":0,"heap":116376,"psram":6814724,"uptime":2145,"resetReason":1,"faceOk":false,"kp":18.0,"smooth":0.35,"maxStep":3.0,"dead":41,"invPan":true,"invTilt":true,"settle":350,"lost":2500,"scan":true,"scanSpeed":9.0,"scanTilt":88.0,"trackTiltMax":84.0,"lockMs":600,"lockRelease":3.0,"aimBelow":2.30,"torso":true,"redetect":300,"torsoConf":0.12,"kind":0,"faceAge":-1,"faceTimeout":25000,"aimFrac":0.65,"personThr":0.85,"detector":"espdet-person","autoFire":true,"mthr":22,"mmin":49,"quality":80,"hmirror":true,"vflip":false,"panTrim":0.0,"tiltTrim":0.0,"bootMode":1}
```

## Reapplying from scratch (via web API)

Device is AP-mode: SSID `turret`, pass `turret123`, IP `192.168.4.1` (defaults; fine in source).
Endpoint: `GET /control?var=<name>&val=<value>&save=1` (param names per `web.cpp:120-172`).

```
/control?var=invpan&val=1&save=1
/control?var=invtilt&val=1&save=1
/control?var=dead&val=41&save=1
/control?var=scanspeed&val=9.0&save=1
/control?var=scantilt&val=88.0&save=1
/control?var=ttmax&val=84.0&save=1
/control?var=aimfrac&val=0.65&save=1
/control?var=personthr&val=0.85&save=1
/control?var=facetmo&val=25000&save=1
/control?var=autofire&val=1&save=1
/control?var=mmin&val=49&save=1
/control?var=hmirror&val=1&save=1
```

Notes:
- Keep `redetect` (300) well below `faceTimeout` (25000). The original lock-loss bug was `redetect=3700` > old `faceTimeout=1500`, which force-dropped the torso track every 1.5 s (`main.cpp:288`, `tracker.cpp:91`).
- `faceTimeout` is exposed in status as `faceTimeout` but set via var name `facetmo` (`web.cpp:149`).
- The Windows Wi-Fi profile for `turret` was set to auto-connect (connection mode was "manual"), so the AP link now survives device reboots without a manual `netsh wlan connect`.

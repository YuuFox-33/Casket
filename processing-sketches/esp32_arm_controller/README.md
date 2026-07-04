# ESP32 Arm Controller

Status: **Working**

5-DOF robotic arm controller (Base / Shoulder / Elbow / Wrist Pitch / Wrist
Roll) talking to an ESP32 over WiFi via a raw TCP socket
(`processing.net.Client`).

## Setup
1. Flash your ESP32 with firmware that opens a TCP server on `espPort`
   (default `12345`) and accepts the commands below.
2. Update `espIP` at the top of the sketch to match your ESP32's IP (check
   its serial monitor output on boot).
3. Run the sketch - it auto-reconnects every 3 seconds if the socket drops.

## Features
- Five draggable sliders, one per servo, sent as `"v0,v1,v2,v3,v4\n"`
- Recording / playback / loop of manual moves
- Built-in gesture patterns: wiggle, wave, nod, dance, scan, shake, circle, random
- Presets: rest, point, grab, center
- Reads back live position from the ESP32 via `"POS:v0,v1,v2,v3,v4"` messages
  and syncs the sliders to match
- Keyboard shortcuts for everything (press `?` in the running sketch to print
  the full list to console)

## Protocol (Processing → ESP32)
Single ASCII characters/strings, newline-terminated:

| Command | Meaning |
|---|---|
| `M` | Manual mode |
| `R` / `S` | Start / stop recording |
| `P` / `A` / `X` | Play / loop / stop playback |
| `W` / `L` / `C` | Save / load / clear recording |
| `I` / `T` | Info / test |
| `Q E N D G H J Y Z` | Pattern: wiggle/wave/nod/dance/scan/shake/circle/random/stop |
| `v0,v1,v2,v3,v4` | Direct servo angles (also sent continuously while dragging sliders) |
| `V1.5` / `V0.5` | Speed multiplier up/down |
| `B15` / `B45` | Amplitude down/up |

## Known limitations
- Connection attempts are non-blocking (see `connectToESP32()` /
  `checkPendingConnection()`) with a 1.5s timeout (`connectTimeout`) - raise
  this if your ESP32 is on a slow/congested network and needs longer to
  accept the socket.
- `handleButton()`'s direct `esp32Client.write()` calls don't independently
  check `esp32Client.active()` before writing - if the socket dies between
  reconnect checks, a button press in that window can silently no-op.

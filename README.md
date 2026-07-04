# casket ⚰️

A resting place for old, unfinished, or "might need this someday" code —
mostly bench-test tools and control panels from robotics/electronics
projects. Nothing here is meant to be a polished product; the goal is just
to keep working (or working-ish) code from getting lost in a random folder.

## Rules for this repo
- No PR reviews, no gatekeeping on code quality — if it exists and might be
  useful later, it goes in.
- Every sketch/script gets its own folder with its own README covering setup,
  protocol, and known limitations.
- If something graduates into an active project's own repo, leave a note
  here pointing to where it went.

## Contents

| Sketch | Description | Status |
|---|---|---|
| [`servo_control_panel`](processing-sketches/servo_control_panel) | Single-servo control panel over Serial — slider, presets, arrow keys | ✅ Working |
| [`esp32_arm_controller`](processing-sketches/esp32_arm_controller) | 5-DOF arm controller over WiFi TCP — recording, playback, gesture patterns | ✅ Working |
| [`mpu6050_orientation_box`](processing-sketches/mpu6050_orientation_box) | Live 3D orientation display from an MPU6050 accel+gyro, complementary filter | ✅ Working (pitch/roll only) |

Each folder's README has the full setup, wiring/protocol details, and any
known rough edges.

## Requirements
- [Processing](https://processing.org/download) 3.x or 4.x
- `processing.serial` (bundled with Processing) for the Serial-based sketches
- `processing.net` (bundled with Processing) for the WiFi-based sketch
- An Arduino or ESP32 running matching firmware for whichever sketch you're using

## License
[MIT](LICENSE) — do whatever you want with it.

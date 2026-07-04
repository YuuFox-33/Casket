# casket ⚰️

Where old, unfinished, half-working, or "might need this someday" code goes to rest.
Not meant to be clean or maintained — just kept alive instead of lost in a random folder.

## Rules for this repo
- No PR reviews, no "make it good first." If it exists and might be useful later, it goes in.
- Each sketch/script gets its own folder with a short note below on what state it's in.
- If something graduates into an actual project repo, leave a note here pointing to where it went.

## Contents

### processing-sketches/

**servo_control_panel/**
Single-servo Processing control panel — slider, preset angle buttons, arrow-key control, live
angle visualization. Talks to Arduino over Serial (9600 baud), auto-picks COM5 or falls back to
last available port.
Status: works. Known issue — holding arrow keys can flood serial writes with no throttling
(no debounce on `keyPressed`), can cause jittery motion under fast key-repeat.

**esp32_arm_controller/**
5-DOF arm controller (Base/Shoulder/Elbow/Wrist P/Wrist R) over WiFi TCP to an ESP32. Supports
manual slider control, recording/playback, gesture patterns (wiggle/wave/nod/dance/scan/shake/
circle/random), presets (rest/point/grab/center), and reads back live position from the ESP32.
Status: most complete of the three, but `connectToESP32()` uses a blocking `delay(200)` inside
`draw()` during auto-reconnect — causes a UI freeze every reconnect attempt and can falsely
report "FAILED" if the ESP32 takes longer than 200ms to accept the connection. Fix before relying
on this for real bench work: make the reconnect non-blocking.

**mpu6050_orientation_box/**
Reads accel+gyro over Serial (115200 baud) from an MPU6050, draws a 3D box in Processing that
tilts based on the readings.
Status: cosmetic only, not a real orientation estimate — it maps raw accelerometer counts
directly to rotation angles instead of computing actual pitch/roll (and yaw isn't observable
from accel alone at all). Gyro values are parsed but unused. Would need a complementary filter
(gyro integration + accel correction) to be trustworthy — same approach already used in the
Arduino-side fin stabilization firmware, just needs porting into this sketch.

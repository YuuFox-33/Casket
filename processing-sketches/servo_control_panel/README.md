# Servo Control Panel

Status: **Working**

Single-servo control panel built in Processing. Talks to an Arduino over
Serial at 9600 baud and sends target angles as newline-terminated integers
(`"90\n"`, etc.).

## Features
- Draggable slider (0-180°)
- Preset angle buttons (0/45/90/135/180)
- Arrow-key control (↑/↓ = ±10°, ←/→ = ±1°)
- Number keys 0-9 jump to `preset * 20°`
- Space bar resets to 90°
- Live rotating-arm visualization matching the commanded angle
- Auto-detects COM5, falls back to the last available port if COM5 isn't found

## Arduino side
Expects a sketch that reads an integer angle from Serial and writes it to a
servo, e.g.:
```cpp
if (Serial.available()) {
  int angle = Serial.parseInt();
  myServo.write(angle);
}
```

## Known limitations
- Arrow-key sends are throttled to one write per 50ms (`keySendInterval`) to
  avoid flooding the Arduino's UART during OS key-repeat. If your Arduino-side
  parsing is slow, you may want to raise this further.

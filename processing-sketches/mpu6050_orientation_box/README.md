# MPU6050 Orientation Box

Status: **Working** (pitch/roll only - no yaw, see below)

Reads accelerometer + gyro data over Serial (115200 baud) from an MPU6050 and
renders a 3D box in Processing that tracks the sensor's real-world pitch and
roll via a complementary filter.

## Expected serial format
One line per reading, matching:
```
a/g: <ax> <ay> <az> <gx> <gy> <gz>
```
e.g. from an Arduino running the standard MPU6050 example that prints
`Serial.print("a/g:\t"); ... ` with tab or space-separated values.

## How the filter works
- **Accelerometer** gives an absolute tilt reading via `atan2`, but is noisy
  and reacts to any linear acceleration (shaking, vibration), not just tilt.
- **Gyroscope** gives a smooth, responsive rotation *rate*, but integrating
  it over time drifts steadily off true.
- The complementary filter (`FILTER_ALPHA = 0.98`) blends the two: mostly
  trusts the integrated gyro moment-to-moment, and slowly pulls the estimate
  back toward the accel reading to cancel drift.

## Why there's no yaw
Gravity looks identical no matter which way the sensor is facing around the
vertical axis, so accelerometer data alone cannot observe yaw. Getting a real
heading would need either a magnetometer (compass) fused in, or accepting
pure gyro-integrated yaw with unbounded drift. Neither is implemented here -
the box only ever rotates about the pitch and roll axes.

## Known limitations
- Hardcoded to `Serial.list()[2]` with no fallback - if your port list order
  changes, this connects to the wrong device or throws an index error.
- Gyro sensitivity (131 LSB/°/s) assumes the MPU6050's default ±250°/s range.
  If your Arduino sketch configures a wider range, update the divisor in
  `updateOrientation()` to match.

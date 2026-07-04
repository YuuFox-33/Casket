import processing.serial.*;

Serial myPort;
String inString;

// Raw sensor values as reported by the Arduino ("a/g: ax ay az gx gy gz")
float ax, ay, az, gx, gy, gz;

// Complementary-filtered orientation estimate (degrees)
float pitch = 0;
float roll = 0;

// Complementary filter weight: how much we trust the integrated gyro vs.
// the accelerometer correction each step. Gyro is smooth but drifts over
// time; accel is noisy but has no long-term drift, so we lean on gyro for
// short-term motion and let accel slowly correct the drift.
final float FILTER_ALPHA = 0.98;

long lastUpdateMicros = 0;

void setup() {
  size(600, 600, P3D);
  println(Serial.list());
  // Pick correct COM port from the list:
  myPort = new Serial(this, Serial.list()[2], 115200);
  myPort.bufferUntil('\n');
  lastUpdateMicros = System.nanoTime() / 1000;
}

void draw() {
  background(30);
  lights();
  translate(width/2, height/2, 0);

  rotateX(radians(pitch));
  rotateZ(radians(roll));

  fill(0, 150, 255);
  box(200, 40, 100);

  // On-screen readout - handy for sanity-checking against a known-flat surface
  camera();
  fill(255);
  textAlign(LEFT, TOP);
  textSize(14);
  text("Pitch: " + nf(pitch, 1, 1) + "deg", 10, 10);
  text("Roll:  " + nf(roll, 1, 1) + "deg", 10, 28);
}

void serialEvent(Serial p) {
  inString = p.readStringUntil('\n');
  if (inString == null) return;

  inString = trim(inString);
  if (!inString.startsWith("a/g:")) return;

  // Remove "a/g:" prefix
  inString = inString.substring(4).trim();
  String[] values = splitTokens(inString, "\t ");
  if (values.length != 6) return;

  ax = float(values[0]);
  ay = float(values[1]);
  az = float(values[2]);
  gx = float(values[3]);
  gy = float(values[4]);
  gz = float(values[5]);

  updateOrientation();
}

// Complementary filter: blend gyro-integrated angle (responsive, drifts)
// with accel-derived angle (noisy, no drift) so the box tracks real
// pitch/roll instead of just wobbling with raw accel counts.
//
// Note: yaw (rotation about vertical) is NOT computed here, because gravity
// alone can't observe it - you'd need the gyro-Z integration on its own
// (which drifts unbounded with nothing to correct it) or a magnetometer for
// a real heading. That's why this sketch only ever rotates about X and Z.
void updateOrientation() {
  long nowMicros = System.nanoTime() / 1000;
  float dt = (nowMicros - lastUpdateMicros) / 1000000.0;
  lastUpdateMicros = nowMicros;
  if (dt <= 0 || dt > 0.5) return; // guard against startup/serial-hiccup spikes

  // Accel-only estimate of tilt, valid when the sensor is roughly static.
  // atan2 naturally handles the full range and avoids division-by-zero
  // issues a plain atan would have when az approaches 0.
  float accelPitch = degrees(atan2(-ax, sqrt(ay * ay + az * az)));
  float accelRoll  = degrees(atan2(ay, az));

  // Gyro is in deg/s once divided by the MPU6050's default sensitivity
  // (131 LSB per deg/s at +-250deg/s full scale - adjust if your Arduino
  // sketch configures a different gyro range).
  float gyroPitchRate = gx / 131.0;
  float gyroRollRate  = gy / 131.0;

  pitch = FILTER_ALPHA * (pitch + gyroPitchRate * dt) + (1 - FILTER_ALPHA) * accelPitch;
  roll  = FILTER_ALPHA * (roll  + gyroRollRate  * dt) + (1 - FILTER_ALPHA) * accelRoll;
}

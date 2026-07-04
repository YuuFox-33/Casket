import processing.serial.*;
Serial myPort;
String inString;
float ax, ay, az, gx, gy, gz;
void setup() {
  size(600, 600, P3D);
  println(Serial.list()); 
  // Pick correct COM port from the list:
  myPort = new Serial(this, Serial.list()[2], 115200);  
  myPort.bufferUntil('\n');
}
void draw() {
  background(30);
  lights();
  translate(width/2, height/2, 0);
  // Simple orientation mapping from accel
  rotateX(radians(ay / 200.0));
  rotateY(radians(ax / 200.0));
  rotateZ(radians(az / 200.0));
  fill(0, 150, 255);
  box(200, 40, 100);
}
void serialEvent(Serial myPort) {
  inString = myPort.readStringUntil('\n');
  if (inString != null) {
    inString = trim(inString);
    if (inString.startsWith("a/g:")) {
      // Remove "a/g:" part
      inString = inString.substring(4).trim();
      String[] values = splitTokens(inString, "\t ");
      if (values.length == 6) {
        ax = float(values[0]);
        ay = float(values[1]);
        az = float(values[2]);
        gx = float(values[3]);
        gy = float(values[4]);
        gz = float(values[5]);
      }
    }
  }
}

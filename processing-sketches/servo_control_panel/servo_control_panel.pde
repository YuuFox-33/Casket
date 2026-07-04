import processing.serial.*;

Serial myPort;
int angle = 90; // Start at center position
int targetAngle = 90;
boolean connected = false;
boolean dragging = false;

// Throttles serial writes from key-repeat so holding an arrow key doesn't
// flood the Arduino with a write every ~16-33ms (OS key-repeat rate).
int lastKeySend = 0;
int keySendInterval = 50; // ms between sends while a key is held

// UI Elements
int sliderX = 100;
int sliderY = 400;
int sliderWidth = 600;
int sliderHeight = 20;

// Colors
color bgColor = color(30, 30, 40);
color accentColor = color(100, 150, 255);
color successColor = color(80, 200, 120);
color warningColor = color(255, 100, 100);

void setup() {
  size(800, 600);
  smooth();
  
  println("=== Available Serial Ports ===");
  printArray(Serial.list());
  println("==============================");
  
  // Try to connect to Arduino
  try {
    if (Serial.list().length > 0) {
      // Try COM5 first, then try the last port in the list
      String portName = "COM5";
      
      // Check if COM5 exists
      boolean com5Exists = false;
      for (String port : Serial.list()) {
        if (port.equals("COM5")) {
          com5Exists = true;
          break;
        }
      }
      
      if (!com5Exists) {
        portName = Serial.list()[Serial.list().length - 1];
        println("COM5 not found. Using: " + portName);
      }
      
      myPort = new Serial(this, portName, 9600);
      myPort.bufferUntil('\n');
      connected = true;
      println("✓ Connected to: " + portName);
      
      // Send initial angle
      delay(2000); // Wait for Arduino to initialize
      sendAngle(angle);
    } else {
      println("✗ No serial ports found!");
    }
  } catch (Exception e) {
    println("✗ Connection failed: " + e.getMessage());
    println("Please check:");
    println("  - Arduino is connected");
    println("  - Correct COM port");
    println("  - Arduino IDE Serial Monitor is closed");
  }
}

void draw() {
  background(bgColor);
  
  // Connection status
  drawConnectionStatus();
  
  // Title
  fill(255);
  textAlign(CENTER);
  textSize(32);
  text("🎛️ Servo Control Panel", width/2, 60);
  
  // Instructions
  textSize(16);
  fill(200);
  text("Use slider, arrow keys, or click preset angles", width/2, 100);
  
  // Draw servo visualization
  drawServoVisualization();
  
  // Draw angle slider
  drawSlider();
  
  // Draw preset buttons
  drawPresetButtons();
  
  // Draw current angle display
  drawAngleDisplay();
  
  // Draw controls legend
  drawControlsLegend();
  
  // Smooth angle transition
  if (abs(angle - targetAngle) > 1) {
    angle += (targetAngle - angle) * 0.2;
  } else {
    angle = targetAngle;
  }
}

void drawConnectionStatus() {
  if (connected) {
    fill(successColor);
    circle(30, 30, 20);
    fill(255);
    textAlign(LEFT);
    textSize(14);
    text("Connected", 50, 36);
  } else {
    fill(warningColor);
    circle(30, 30, 20);
    fill(255);
    textAlign(LEFT);
    textSize(14);
    text("Disconnected", 50, 36);
  }
}

void drawServoVisualization() {
  pushMatrix();
  translate(width/2, 220);
  
  // Servo body
  fill(60, 60, 80);
  stroke(100);
  strokeWeight(2);
  rect(-60, -30, 120, 60, 5);
  
  // Servo shaft
  fill(80, 80, 100);
  circle(0, 0, 30);
  
  // Servo arm (rotating)
  pushMatrix();
  rotate(radians(map(angle, 0, 180, -90, 90)));
  strokeWeight(8);
  stroke(accentColor);
  line(0, 0, 100, 0);
  
  // Arm tip
  fill(accentColor);
  noStroke();
  circle(100, 0, 20);
  popMatrix();
  
  // Angle arc
  noFill();
  stroke(accentColor, 100);
  strokeWeight(2);
  arc(0, 0, 180, 180, radians(-90), radians(map(angle, 0, 180, -90, 90)));
  
  popMatrix();
  
  // Angle markers
  textAlign(CENTER);
  textSize(12);
  fill(150);
  text("0°", width/2 - 100, 240);
  text("90°", width/2, 170);
  text("180°", width/2 + 100, 240);
}

void drawSlider() {
  // Slider background
  fill(50, 50, 70);
  stroke(100);
  strokeWeight(2);
  rect(sliderX, sliderY, sliderWidth, sliderHeight, 10);
  
  // Slider filled portion
  fill(accentColor);
  noStroke();
  float fillWidth = map(angle, 0, 180, 0, sliderWidth);
  rect(sliderX, sliderY, fillWidth, sliderHeight, 10);
  
  // Slider handle
  float handleX = map(angle, 0, 180, sliderX, sliderX + sliderWidth);
  fill(255);
  stroke(accentColor);
  strokeWeight(3);
  circle(handleX, sliderY + sliderHeight/2, 30);
  
  // Slider label
  fill(255);
  textAlign(CENTER);
  textSize(14);
  text("Drag slider or use arrow keys", width/2, sliderY - 10);
}

void drawPresetButtons() {
  String[] labels = {"0°", "45°", "90°", "135°", "180°"};
  int[] angles = {0, 45, 90, 135, 180};
  int buttonWidth = 100;
  int buttonHeight = 40;
  int spacing = 20;
  int startX = (width - (buttonWidth * 5 + spacing * 4)) / 2;
  int buttonY = 470;
  
  textAlign(CENTER, CENTER);
  textSize(16);
  
  for (int i = 0; i < 5; i++) {
    int x = startX + i * (buttonWidth + spacing);
    
    // Check if mouse is over button
    boolean hover = mouseX > x && mouseX < x + buttonWidth && 
                    mouseY > buttonY && mouseY < buttonY + buttonHeight;
    
    // Check if this is current angle
    boolean isCurrent = abs(targetAngle - angles[i]) < 5;
    
    // Draw button
    if (isCurrent) {
      fill(accentColor);
    } else if (hover) {
      fill(70, 70, 90);
    } else {
      fill(50, 50, 70);
    }
    
    stroke(100);
    strokeWeight(2);
    rect(x, buttonY, buttonWidth, buttonHeight, 5);
    
    // Draw label
    fill(255);
    text(labels[i], x + buttonWidth/2, buttonY + buttonHeight/2);
  }
  
  // Preset label
  fill(200);
  textSize(14);
  text("Quick Presets", width/2, buttonY - 15);
}

void drawAngleDisplay() {
  // Large angle display
  fill(50, 50, 70);
  stroke(accentColor);
  strokeWeight(3);
  rectMode(CENTER);
  rect(width/2, 320, 150, 60, 10);
  rectMode(CORNER);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(36);
  text(int(angle) + "°", width/2, 320);
}

void drawControlsLegend() {
  fill(150);
  textAlign(CENTER);
  textSize(12);
  text("↑/↓ Keys: ±10°  |  Left/Right Keys: ±1°  |  Space: Reset to 90°", width/2, 560);
}

void keyPressed() {
  // Arrow keys for control
  if (keyCode == UP && targetAngle < 180) {
    targetAngle += 10;
    targetAngle = constrain(targetAngle, 0, 180);
    sendAngleThrottled(targetAngle);
  }
  if (keyCode == DOWN && targetAngle > 0) {
    targetAngle -= 10;
    targetAngle = constrain(targetAngle, 0, 180);
    sendAngleThrottled(targetAngle);
  }
  if (keyCode == RIGHT && targetAngle < 180) {
    targetAngle += 1;
    targetAngle = constrain(targetAngle, 0, 180);
    sendAngleThrottled(targetAngle);
  }
  if (keyCode == LEFT && targetAngle > 0) {
    targetAngle -= 1;
    targetAngle = constrain(targetAngle, 0, 180);
    sendAngleThrottled(targetAngle);
  }
  
  // Space to reset - always send immediately, this is a deliberate one-off action
  if (key == ' ') {
    targetAngle = 90;
    sendAngle(targetAngle);
  }
  
  // Number keys for quick presets - also immediate, not a repeat-prone action
  if (key >= '0' && key <= '9') {
    int preset = key - '0';
    if (preset <= 180) {
      targetAngle = preset * 20;
      targetAngle = constrain(targetAngle, 0, 180);
      sendAngle(targetAngle);
    }
  }
}

// Wraps sendAngle() for the arrow-key handlers specifically. Holding an
// arrow key fires keyPressed() on every OS key-repeat tick (often 30-60Hz),
// which used to mean a serial write every tick. This drops writes that
// arrive faster than keySendInterval, so a held key still ends up at the
// right final angle without spamming the Arduino's UART.
void sendAngleThrottled(int ang) {
  int now = millis();
  if (now - lastKeySend >= keySendInterval) {
    sendAngle(ang);
    lastKeySend = now;
  }
}

void mousePressed() {
  // Check slider
  if (mouseY > sliderY - 20 && mouseY < sliderY + sliderHeight + 20 &&
      mouseX > sliderX && mouseX < sliderX + sliderWidth) {
    dragging = true;
    updateSlider();
  }
  
  // Check preset buttons
  String[] labels = {"0°", "45°", "90°", "135°", "180°"};
  int[] angles = {0, 45, 90, 135, 180};
  int buttonWidth = 100;
  int buttonHeight = 40;
  int spacing = 20;
  int startX = (width - (buttonWidth * 5 + spacing * 4)) / 2;
  int buttonY = 470;
  
  for (int i = 0; i < 5; i++) {
    int x = startX + i * (buttonWidth + spacing);
    if (mouseX > x && mouseX < x + buttonWidth && 
        mouseY > buttonY && mouseY < buttonY + buttonHeight) {
      targetAngle = angles[i];
      sendAngle(targetAngle);
    }
  }
}

void mouseDragged() {
  if (dragging) {
    updateSlider();
  }
}

void mouseReleased() {
  dragging = false;
}

void updateSlider() {
  float newAngle = map(mouseX, sliderX, sliderX + sliderWidth, 0, 180);
  targetAngle = constrain(int(newAngle), 0, 180);
  sendAngle(targetAngle);
}

void sendAngle(int ang) {
  if (connected) {
    myPort.write(ang + "\n");
    println("✓ Sent angle: " + ang + "°");
  } else {
    println("✗ Not connected! Cannot send angle.");
  }
}

void serialEvent(Serial p) {
  try {
    String inString = p.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      println("Arduino says: " + inString);
    }
  } catch (Exception e) {
    println("Error reading serial: " + e.getMessage());
  }
}

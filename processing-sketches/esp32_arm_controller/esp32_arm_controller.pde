import processing.net.*;

// ═══════════════════════════════════════════════════════════
// CONFIGURATION - CHANGE ESP32 IP HERE!
// ═══════════════════════════════════════════════════════════

String espIP = "192.168.0.220";  // <<< CHECK SERIAL MONITOR FOR YOUR IP
int espPort = 12345;

// ═══════════════════════════════════════════════════════════
// GLOBAL VARIABLES
// ═══════════════════════════════════════════════════════════

Client esp32Client;
boolean connected = false;
int lastReconnect = 0;
int reconnectInterval = 3000; // Try reconnect every 3 seconds

String[] servoNames = {"Base", "Shoulder", "Elbow", "Wrist P", "Wrist R"};
int[] servoValues = {90, 90, 90, 90, 90};
int[] sliderX = {50, 50, 50, 50, 50};
int[] sliderY = {100, 160, 220, 280, 340};
int sliderWidth = 400;
int sliderHeight = 30;
int activeSlider = -1;

class Button {
  int x, y, w, h;
  String label;
  color bgColor, hoverColor;
  boolean enabled;
  
  Button(int _x, int _y, int _w, int _h, String _label, color _bg) {
    x = _x; y = _y; w = _w; h = _h;
    label = _label;
    bgColor = _bg;
    hoverColor = color(red(_bg) + 50, green(_bg) + 50, blue(_bg) + 50);
    enabled = true;
  }
  
  void display() {
    if (!enabled) {
      fill(80);
    } else if (isHover()) {
      fill(hoverColor);
    } else {
      fill(bgColor);
    }
    stroke(255);
    strokeWeight(2);
    rect(x, y, w, h, 5);
    
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(label, x + w/2, y + h/2);
  }
  
  boolean isHover() {
    return enabled && mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
  }
  
  boolean isClicked() {
    return isHover() && mousePressed;
  }
}

ArrayList<Button> buttons = new ArrayList<Button>();
boolean isRecording = false;
boolean isPlaying = false;
String status = "CONNECTING...";
String currentPattern = "NONE";

// ═══════════════════════════════════════════════════════════
// SETUP
// ═══════════════════════════════════════════════════════════

void setup() {
  size(800, 620);
  
  println("\n╔════════════════════════════════════╗");
  println("║  ESP32 ARM CONTROLLER v2.0         ║");
  println("╚════════════════════════════════════╝");
  println("\nESP32 IP: " + espIP);
  println("Port: " + espPort);
  
  connectToESP32();
  
  // Control buttons (left column)
  buttons.add(new Button(500, 100, 140, 40, "MANUAL", color(100, 100, 100)));
  buttons.add(new Button(650, 100, 140, 40, "RECORD", color(200, 0, 0)));
  buttons.add(new Button(500, 150, 140, 40, "STOP REC", color(150, 0, 0)));
  buttons.add(new Button(650, 150, 140, 40, "PLAY", color(0, 150, 0)));
  buttons.add(new Button(500, 200, 140, 40, "LOOP", color(0, 200, 0)));
  buttons.add(new Button(650, 200, 140, 40, "STOP", color(100, 50, 0)));
  buttons.add(new Button(500, 250, 140, 40, "SAVE", color(0, 100, 200)));
  buttons.add(new Button(650, 250, 140, 40, "LOAD", color(0, 150, 200)));
  buttons.add(new Button(500, 300, 140, 40, "CLEAR", color(200, 100, 0)));
  buttons.add(new Button(650, 300, 140, 40, "INFO", color(100, 100, 150)));
  buttons.add(new Button(500, 350, 140, 40, "TEST", color(150, 100, 50)));
  
  // Pattern buttons (bottom)
  int patternY = 470;
  buttons.add(new Button(50, patternY, 85, 35, "WIGGLE", color(200, 200, 0)));
  buttons.add(new Button(145, patternY, 85, 35, "WAVE", color(200, 200, 0)));
  buttons.add(new Button(240, patternY, 85, 35, "NOD", color(200, 200, 0)));
  buttons.add(new Button(335, patternY, 85, 35, "DANCE", color(200, 200, 0)));
  
  patternY = 515;
  buttons.add(new Button(50, patternY, 85, 35, "SCAN", color(200, 200, 0)));
  buttons.add(new Button(145, patternY, 85, 35, "SHAKE", color(200, 200, 0)));
  buttons.add(new Button(240, patternY, 85, 35, "CIRCLE", color(200, 200, 0)));
  buttons.add(new Button(335, patternY, 85, 35, "RANDOM", color(200, 200, 0)));
  buttons.add(new Button(430, patternY, 85, 35, "STOP PT", color(150, 0, 0)));
  
  // Preset buttons
  buttons.add(new Button(50, 420, 90, 35, "REST", color(80, 80, 120)));
  buttons.add(new Button(150, 420, 90, 35, "POINT", color(80, 80, 120)));
  buttons.add(new Button(250, 420, 90, 35, "GRAB", color(80, 80, 120)));
  buttons.add(new Button(350, 420, 90, 35, "CENTER", color(80, 80, 120)));
}

// ═══════════════════════════════════════════════════════════
// MAIN DRAW LOOP
// ═══════════════════════════════════════════════════════════

void draw() {
  background(30);
  
  // Auto-reconnect
  if (!connected || (esp32Client != null && !esp32Client.active())) {
    if (millis() - lastReconnect > reconnectInterval) {
      connectToESP32();
      lastReconnect = millis();
    }
  }
  
  // Title
  fill(0, 255, 150);
  textSize(28);
  textAlign(LEFT);
  text("🦾 ESP32 ARM CONTROLLER", 50, 50);
  
  // Connection indicator
  fill(connected ? color(0, 255, 0) : color(255, 0, 0));
  ellipse(750, 40, 20, 20);
  fill(255);
  textSize(14);
  textAlign(RIGHT);
  text(connected ? "CONNECTED" : "DISCONNECTED", 720, 45);
  
  if (!connected) {
    fill(255, 200, 0);
    textSize(20);
    textAlign(CENTER);
    text("⚠️ Connecting to ESP32...", width/2, height/2);
    text("IP: " + espIP, width/2, height/2 + 30);
    return;
  }
  
  textAlign(LEFT);
  
  // Recording indicator
  if (isRecording) {
    fill(255, 0, 0);
    ellipse(720, 40, 15, 15);
  }
  
  // Draw sliders
  for (int i = 0; i < 5; i++) {
    drawSlider(i);
  }
  
  // Draw buttons
  for (Button btn : buttons) {
    btn.display();
  }
  
  // Status bar
  fill(255);
  textSize(18);
  textAlign(LEFT);
  text("Status: " + status, 50, 575);
  
  if (!currentPattern.equals("NONE")) {
    fill(255, 255, 0);
    text("Pattern: " + currentPattern, 300, 575);
  }
  
  // Instructions
  fill(150);
  textSize(12);
  text("Drag sliders • Click buttons • Keys: R=Record S=Stop P=Play L=Loop T=Test", 50, 600);
}

// ═══════════════════════════════════════════════════════════
// SLIDER DRAWING
// ═══════════════════════════════════════════════════════════

void drawSlider(int index) {
  int x = sliderX[index];
  int y = sliderY[index];
  
  // Label
  fill(255);
  textAlign(LEFT);
  textSize(14);
  text(servoNames[index], x, y - 10);
  
  // Background track
  fill(50);
  stroke(100);
  strokeWeight(1);
  rect(x, y, sliderWidth, sliderHeight, 5);
  
  // Filled portion
  float fillWidth = map(servoValues[index], 0, 180, 0, sliderWidth);
  fill(0, 200, 255);
  noStroke();
  rect(x, y, fillWidth, sliderHeight, 5);
  
  // Handle
  float handleX = x + fillWidth;
  fill(0, 255, 200);
  stroke(255);
  strokeWeight(2);
  ellipse(handleX, y + sliderHeight/2, 25, 25);
  
  // Value display
  fill(255);
  textAlign(CENTER, CENTER);
  text(servoValues[index] + "°", x + sliderWidth + 35, y + sliderHeight/2);
}

// ═══════════════════════════════════════════════════════════
// CONNECTION
// ═══════════════════════════════════════════════════════════

void connectToESP32() {
  try {
    println("\n→ Connecting to " + espIP + ":" + espPort + "...");
    
    if (esp32Client != null) {
      esp32Client.stop();
    }
    
    esp32Client = new Client(this, espIP, espPort);
    delay(200);
    
    if (esp32Client.active()) {
      connected = true;
      status = "CONNECTED";
      println("✓✓✓ CONNECTED ✓✓✓");
      sendToESP32();
    } else {
      connected = false;
      status = "FAILED";
      println("✗ Connection failed");
    }
  } catch (Exception e) {
    connected = false;
    status = "ERROR";
    println("✗ Error: " + e.getMessage());
  }
}

// ═══════════════════════════════════════════════════════════
// MOUSE HANDLING
// ═══════════════════════════════════════════════════════════

void mousePressed() {
  if (!connected) return;
  
  // Check sliders
  for (int i = 0; i < 5; i++) {
    if (mouseX > sliderX[i] && mouseX < sliderX[i] + sliderWidth &&
        mouseY > sliderY[i] && mouseY < sliderY[i] + sliderHeight) {
      activeSlider = i;
      updateSlider(i);
      return;
    }
  }
  
  // Check buttons
  for (Button btn : buttons) {
    if (btn.isHover()) {
      handleButton(btn.label);
      return;
    }
  }
}

void mouseDragged() {
  if (activeSlider >= 0 && connected) {
    updateSlider(activeSlider);
  }
}

void mouseReleased() {
  activeSlider = -1;
}

void updateSlider(int index) {
  int x = sliderX[index];
  float value = constrain(mouseX - x, 0, sliderWidth);
  int oldValue = servoValues[index];
  servoValues[index] = (int)map(value, 0, sliderWidth, 0, 180);
  
  if (oldValue != servoValues[index]) {
    sendToESP32();
    println("→ " + servoNames[index] + ": " + servoValues[index] + "°");
  }
}

// ═══════════════════════════════════════════════════════════
// BUTTON HANDLING
// ═══════════════════════════════════════════════════════════

void handleButton(String label) {
  if (!connected) return;
  
  // Control buttons
  if (label.equals("MANUAL")) {
    esp32Client.write("M\n");
    status = "MANUAL";
    isRecording = false;
    isPlaying = false;
    currentPattern = "NONE";
  }
  else if (label.equals("RECORD")) {
    esp32Client.write("R\n");
    status = "RECORDING";
    isRecording = true;
    isPlaying = false;
  }
  else if (label.equals("STOP REC")) {
    esp32Client.write("S\n");
    status = "STOPPED";
    isRecording = false;
  }
  else if (label.equals("PLAY")) {
    esp32Client.write("P\n");
    status = "PLAYING";
    isPlaying = true;
  }
  else if (label.equals("LOOP")) {
    esp32Client.write("A\n");
    status = "LOOP";
    isPlaying = true;
  }
  else if (label.equals("STOP")) {
    esp32Client.write("X\n");
    status = "STOPPED";
    isPlaying = false;
    currentPattern = "NONE";
  }
  else if (label.equals("SAVE")) {
    esp32Client.write("W\n");
    status = "SAVING...";
  }
  else if (label.equals("LOAD")) {
    esp32Client.write("L\n");
    status = "LOADING...";
  }
  else if (label.equals("CLEAR")) {
    esp32Client.write("C\n");
    status = "CLEARED";
  }
  else if (label.equals("INFO")) {
    esp32Client.write("I\n");
    status = "INFO";
  }
  else if (label.equals("TEST")) {
    esp32Client.write("T\n");
    status = "TESTING...";
  }
  
  // Pattern buttons
  else if (label.equals("WIGGLE")) {
    esp32Client.write("Q\n");
    status = "PATTERN: WIGGLE";
    currentPattern = "WIGGLE";
  }
  else if (label.equals("WAVE")) {
    esp32Client.write("E\n");
    status = "PATTERN: WAVE";
    currentPattern = "WAVE";
  }
  else if (label.equals("NOD")) {
    esp32Client.write("N\n");
    status = "PATTERN: NOD";
    currentPattern = "NOD";
  }
  else if (label.equals("DANCE")) {
    esp32Client.write("D\n");
    status = "PATTERN: DANCE";
    currentPattern = "DANCE";
  }
  else if (label.equals("SCAN")) {
    esp32Client.write("G\n");
    status = "PATTERN: SCAN";
    currentPattern = "SCAN";
  }
  else if (label.equals("SHAKE")) {
    esp32Client.write("H\n");
    status = "PATTERN: SHAKE";
    currentPattern = "SHAKE";
  }
  else if (label.equals("CIRCLE")) {
    esp32Client.write("J\n");
    status = "PATTERN: CIRCLE";
    currentPattern = "CIRCLE";
  }
  else if (label.equals("RANDOM")) {
    esp32Client.write("Y\n");
    status = "PATTERN: RANDOM";
    currentPattern = "RANDOM";
  }
  else if (label.equals("STOP PT")) {
    esp32Client.write("Z\n");
    status = "STOPPED";
    currentPattern = "NONE";
  }
  
  // Preset buttons
  else if (label.equals("REST")) {
    setPreset(90, 90, 90, 90, 90);
    status = "PRESET: REST";
  }
  else if (label.equals("POINT")) {
    setPreset(90, 0, 0, 0, 90);
    status = "PRESET: POINT";
  }
  else if (label.equals("GRAB")) {
    setPreset(90, 90, 120, 90, 180);
    status = "PRESET: GRAB";
  }
  else if (label.equals("CENTER")) {
    setPreset(90, 90, 90, 90, 90);
    status = "PRESET: CENTER";
  }
  
  println("→ Button: " + label);
}

void setPreset(int s0, int s1, int s2, int s3, int s4) {
  servoValues[0] = s0;
  servoValues[1] = s1;
  servoValues[2] = s2;
  servoValues[3] = s3;
  servoValues[4] = s4;
  sendToESP32();
  println("→ Preset applied: " + s0 + "," + s1 + "," + s2 + "," + s3 + "," + s4);
}

void sendToESP32() {
  if (!connected || esp32Client == null || !esp32Client.active()) return;
  
  String cmd = servoValues[0] + "," + servoValues[1] + "," + 
               servoValues[2] + "," + servoValues[3] + "," + 
               servoValues[4] + "\n";
  esp32Client.write(cmd);
}

// ═══════════════════════════════════════════════════════════
// KEYBOARD SHORTCUTS
// ═══════════════════════════════════════════════════════════

void keyPressed() {
  if (!connected) return;
  
  // Recording controls
  if (key == 'r' || key == 'R') handleButton("RECORD");
  else if (key == 's' || key == 'S') handleButton("STOP REC");
  else if (key == 'p' || key == 'P') handleButton("PLAY");
  else if (key == 'l' || key == 'L') handleButton("LOOP");
  else if (key == 'x' || key == 'X') handleButton("STOP");
  else if (key == 'i' || key == 'I') handleButton("INFO");
  else if (key == 't' || key == 'T') handleButton("TEST");
  
  // Pattern shortcuts
  else if (key == 'q' || key == 'Q') handleButton("WIGGLE");
  else if (key == 'e' || key == 'E') handleButton("WAVE");
  else if (key == 'n' || key == 'N') handleButton("NOD");
  else if (key == 'd' || key == 'D') handleButton("DANCE");
  else if (key == 'g' || key == 'G') handleButton("SCAN");
  else if (key == 'h' || key == 'H') handleButton("SHAKE");
  else if (key == 'j' || key == 'J') handleButton("CIRCLE");
  else if (key == 'y' || key == 'Y') handleButton("RANDOM");
  else if (key == 'z' || key == 'Z') handleButton("STOP PT");
  
  // Speed/Amplitude controls
  else if (key == '+') {
    esp32Client.write("V1.5\n");
    println("→ Speed: 1.5x");
  }
  else if (key == '-') {
    esp32Client.write("V0.5\n");
    println("→ Speed: 0.5x");
  }
  else if (key == '[') {
    esp32Client.write("B15\n");
    println("→ Amplitude: 15°");
  }
  else if (key == ']') {
    esp32Client.write("B45\n");
    println("→ Amplitude: 45°");
  }
  
  // Help
  else if (key == '?') {
    printHelp();
  }
}

void printHelp() {
  println("\n╔════════════════════════════════════╗");
  println("║         KEYBOARD SHORTCUTS         ║");
  println("╚════════════════════════════════════╝");
  println("Recording:");
  println("  R - Record      S - Stop");
  println("  P - Play        L - Loop");
  println("  X - Stop All    T - Test");
  println("\nPatterns:");
  println("  Q - Wiggle      E - Wave");
  println("  N - Nod         D - Dance");
  println("  G - Scan        H - Shake");
  println("  J - Circle      Y - Random");
  println("  Z - Stop Pattern");
  println("\nControls:");
  println("  + - Speed up    - - Speed down");
  println("  [ - Less amp    ] - More amp");
  println("  ? - This help");
  println("════════════════════════════════════\n");
}

// ═══════════════════════════════════════════════════════════
// SERIAL EVENT (Receive data from ESP32)
// ═══════════════════════════════════════════════════════════

void clientEvent(Client c) {
  if (c.available() > 0) {
    String msg = c.readStringUntil('\n');
    if (msg != null) {
      msg = trim(msg);
      if (msg.startsWith("POS:")) {
        // Update servo positions from ESP32
        String[] parts = split(msg.substring(4), ',');
        if (parts.length == 5) {
          for (int i = 0; i < 5; i++) {
            servoValues[i] = int(parts[i]);
          }
        }
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════
// EXIT HANDLER
// ═══════════════════════════════════════════════════════════

void exit() {
  if (esp32Client != null) {
    esp32Client.stop();
    println("\n✓ Disconnected from ESP32");
  }
  super.exit();
}

#include <EEPROM.h>

// ── Konfiguration ─────────────────────────────────────────────────────────────
#define EEPROM_MAGIC    0x42          // Magic Byte — prüft ob EEPROM initialisiert
#define EEPROM_ADDR_MAGIC  0          // Adresse Magic Byte
#define EEPROM_ADDR_ID     1          // Adresse FAN-ID String (max 5 Zeichen + \0)
#define FAN_PWM_PIN     9
#define FAN_TACH_PIN    2

// ── Globale Zustandsvariablen ─────────────────────────────────────────────────
volatile int pulseCount = 0;
unsigned long lastRPMCheck = 0;
int rpm = 0;
bool fanError = false;
char fanID[8] = "UNKNOWN"; // z.B. "FAN1" .. "FAN7"

// ── PWM-Kurve (stückweise linear, nicht aggressiv) ───────────────────────────
// < 30°C → 20%
// 30–55°C → 20→60%
// 55–70°C → 60→100%
// ≥ 70°C  → 100%
int tempToPercent(int temp) {
  if (temp < 30) return 20;
  if (temp < 55) return map(temp, 30, 55, 20, 60);
  if (temp < 70) return map(temp, 55, 70, 60, 100);
  return 100;
}

// ── RPM-Interrupt ─────────────────────────────────────────────────────────────
void countPulse() {
  pulseCount++;
}

// ── PWM setzen ────────────────────────────────────────────────────────────────
void setPWM(int percent) {
  OCR1A = map(percent, 0, 100, 0, 320);
}

// ── EEPROM: FAN-ID lesen ──────────────────────────────────────────────────────
void loadFanID() {
  if (EEPROM.read(EEPROM_ADDR_MAGIC) != EEPROM_MAGIC) {
    // Noch nicht provisioniert
    strcpy(fanID, "UNKNOWN");
    return;
  }
  for (int i = 0; i < 7; i++) {
    fanID[i] = EEPROM.read(EEPROM_ADDR_ID + i);
    if (fanID[i] == '\0') break;
  }
  fanID[7] = '\0'; // Sicherheits-Null
}

// ── EEPROM: FAN-ID schreiben ──────────────────────────────────────────────────
void saveFanID(const char* id) {
  EEPROM.write(EEPROM_ADDR_MAGIC, EEPROM_MAGIC);
  for (int i = 0; i < 7; i++) {
    EEPROM.write(EEPROM_ADDR_ID + i, id[i]);
    if (id[i] == '\0') break;
  }
  strncpy(fanID, id, 7);
  fanID[7] = '\0';
}

// ── Serial-Kommando verarbeiten ────────────────────────────────────────────────
// Kommandos:
//   WHO?\n         → antwortet: FAN:FAN3
//   ID:FAN3\n      → schreibt FAN3 ins EEPROM, antwortet: OK:FAN3
//   RESET\n        → löscht EEPROM-ID, antwortet: OK:RESET
//   42\n           → Temperaturwert, PWM wird gesetzt
void handleCommand(String cmd) {
  cmd.trim();

  if (cmd == "WHO?") {
    Serial.print("FAN:");
    Serial.println(fanID);
    return;
  }

  if (cmd == "RESET") {
    EEPROM.write(EEPROM_ADDR_MAGIC, 0x00);
    strcpy(fanID, "UNKNOWN");
    Serial.println("OK:RESET");
    return;
  }

  if (cmd.startsWith("ID:")) {
    String newID = cmd.substring(3);
    newID.trim();
    if (newID.length() > 0 && newID.length() <= 7) {
      char buf[8];
      newID.toCharArray(buf, 8);
      saveFanID(buf);
      Serial.print("OK:");
      Serial.println(fanID);
    } else {
      Serial.println("ERR:INVALID_ID");
    }
    return;
  }

  // Temperaturwert (Integer)
  int temp = cmd.toInt();
  if (temp > 0) {
    if (!fanError) {
      int percent = tempToPercent(temp);
      percent = constrain(percent, 20, 100);
      setPWM(percent);
      Serial.print("Temp:");
      Serial.print(temp);
      Serial.print(" PWM%:");
      Serial.print(percent);
      Serial.print(" RPM:");
      Serial.print(rpm);
      Serial.print(" ID:");
      Serial.println(fanID);
    } else {
      Serial.println("ERROR:FAN_FAILURE - PWM gesperrt");
    }
  }
}

// ── Setup ──────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(9600);

  // FAN-ID aus EEPROM laden
  loadFanID();

  // Timer1 auf 25kHz für Pin 9
  pinMode(FAN_PWM_PIN, OUTPUT);
  TCCR1A = 0;
  TCCR1B = 0;
  TCCR1A |= (1 << COM1A1) | (1 << WGM11);
  TCCR1B |= (1 << WGM13) | (1 << CS10);
  ICR1 = 320;
  OCR1A = 64; // 20% Startwert

  // Tachosignal
  pinMode(FAN_TACH_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(FAN_TACH_PIN), countPulse, FALLING);

  Serial.print("Arduino bereit - 25kHz PWM - ID:");
  Serial.println(fanID);
}

// ── Loop ───────────────────────────────────────────────────────────────────────
void loop() {
  // RPM alle 2 Sekunden berechnen (interrupt-basiert, läuft unabhängig)
  if (millis() - lastRPMCheck >= 2000) {
    rpm = (pulseCount * 60) / 2 / 2;
    pulseCount = 0;
    lastRPMCheck = millis();

    if (rpm == 0 && OCR1A > 96) {
      fanError = true;
      setPWM(100);
      Serial.print("ERROR:FAN_FAILURE ID:");
      Serial.println(fanID);
    } else {
      fanError = false;
    }
  }

  // Serial-Kommando lesen (readStringUntil blockiert bis \n oder timeout=1000ms)
  if (Serial.available() > 0) {
    String cmd = Serial.readStringUntil('\n');
    handleCommand(cmd);
  }
}

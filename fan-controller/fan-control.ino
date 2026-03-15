volatile int pulseCount = 0;
unsigned long lastRPMCheck = 0;
int rpm = 0;
bool fanError = false;

void countPulse() {
  pulseCount++;
}

void setup() {
  Serial.begin(9600);
  pinMode(9, OUTPUT);
  pinMode(2, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(2), countPulse, FALLING);

  // Timer1 auf 25kHz für Pin 9
  TCCR1A = 0;
  TCCR1B = 0;
  TCCR1A |= (1 << COM1A1) | (1 << WGM11);
  TCCR1B |= (1 << WGM13) | (1 << CS10);
  ICR1 = 320;
  OCR1A = 64; // 20% Startwert

  Serial.println("Arduino bereit - 25kHz PWM");
}

void setPWM(int percent) {
  OCR1A = map(percent, 0, 100, 0, 320);
}

void loop() {
  if (millis() - lastRPMCheck >= 2000) {
    rpm = (pulseCount * 60) / 2 / 2;
    pulseCount = 0;
    lastRPMCheck = millis();

    if (rpm == 0 && OCR1A > 96) {
      fanError = true;
      setPWM(100);
      Serial.println("ERROR:FAN_FAILURE");
    } else {
      fanError = false;
    }

    Serial.print("RPM:");
    Serial.println(rpm);
  }

  if (Serial.available() > 0) {
    int temp = Serial.parseInt();
    if (temp > 0) {
      if (!fanError) {
        int percent = map(temp, 30, 55, 20, 100);
        percent = constrain(percent, 20, 100);
        setPWM(percent);
        Serial.print("Temp:");
        Serial.print(temp);
        Serial.print(" PWM%:");
        Serial.print(percent);
        Serial.print(" RPM:");
        Serial.println(rpm);
      } else {
        Serial.println("ERROR:FAN_FAILURE - PWM gesperrt");
      }
    }
  }
}
#include <LiquidCrystal.h>

// 距离测控仿真系统
// 学生：王李杰  学号：23009200496  阈值：30 + 6 = 36 cm

const char STUDENT_ID[] = "23009200496";
const float DISTANCE_THRESHOLD_CM = 36.0;

// Proteus 原理图实际引脚：RS=D12, E=D11, D4=D5, D5=D4, D6=D3, D7=D2
const uint8_t LCD_RS = 12;
const uint8_t LCD_EN = 11;
const uint8_t LCD_D4 = 5;
const uint8_t LCD_D5 = 4;
const uint8_t LCD_D6 = 3;
const uint8_t LCD_D7 = 2;
const uint8_t DISTANCE_SENSOR_PIN = A0;  // Proteus 中标记为 IO14
const uint8_t MOTOR_PIN = 7;

LiquidCrystal lcd(LCD_RS, LCD_EN, LCD_D4, LCD_D5, LCD_D6, LCD_D7);

String receivedId = STUDENT_ID;
unsigned long lastSampleMs = 0;
const unsigned long SAMPLE_INTERVAL_MS = 250;

float readDistanceCm() {
  // Sharp GP2D12 的典型反距离电压模型；与 Proteus SHARPGP2 模型匹配。
  // 为减小仿真显示抖动，对 10 次 ADC 采样取平均。
  long adcSum = 0;
  for (uint8_t i = 0; i < 10; ++i) {
    adcSum += analogRead(DISTANCE_SENSOR_PIN);
    delay(2);
  }
  const float adc = adcSum / 10.0;
  const float voltage = adc * (5.0 / 1023.0);

  // GP2D12 数据手册曲线的幂函数拟合，适用范围约 10~80 cm。
  float distance = 80.0;
  if (voltage > 0.10) {
    distance = 27.728 * pow(voltage, -1.2045);
  }
  return constrain(distance, 10.0, 80.0);
}

void readStudentIdFromSerial() {
  if (!Serial.available()) return;

  String line = Serial.readStringUntil('\n');
  line.trim();
  if (line.startsWith("ID:")) {
    line.remove(0, 3);
    line.trim();
  }

  bool allDigits = line.length() > 0 && line.length() <= 11;
  for (unsigned int i = 0; i < line.length(); ++i) {
    if (!isDigit(line[i])) {
      allDigits = false;
      break;
    }
  }

  if (allDigits) {
    receivedId = line;
    Serial.print("ACK:ID=");
    Serial.println(receivedId);
  } else {
    Serial.println("ERROR:INVALID_ID");
  }
}

void updateLcd(float distanceCm) {
  lcd.setCursor(0, 0);
  lcd.print("ID:");
  lcd.print(receivedId);
  for (int i = 3 + receivedId.length(); i < 16; ++i) lcd.print(' ');

  lcd.setCursor(0, 1);
  lcd.print("DIST:");
  lcd.print(distanceCm, 1);
  lcd.print("cm");
  lcd.print("   ");
}

void setup() {
  pinMode(MOTOR_PIN, OUTPUT);
  digitalWrite(MOTOR_PIN, LOW);

  Serial.begin(9600);
  Serial.setTimeout(50);
  lcd.begin(16, 2);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("ID:");
  lcd.print(STUDENT_ID);
  lcd.setCursor(0, 1);
  lcd.print("DIST:--.-cm");
}

void loop() {
  readStudentIdFromSerial();

  const unsigned long now = millis();
  if (now - lastSampleMs < SAMPLE_INTERVAL_MS) return;
  lastSampleMs = now;

  const float distanceCm = readDistanceCm();
  const bool motorRunning = distanceCm > DISTANCE_THRESHOLD_CM;
  digitalWrite(MOTOR_PIN, motorRunning ? HIGH : LOW);

  updateLcd(distanceCm);

  // 机器可读的单行协议，便于上位机稳定解析。
  Serial.print("DIST:");
  Serial.print(distanceCm, 1);
  Serial.print(",MOTOR:");
  Serial.println(motorRunning ? "ON" : "OFF");
}

#include <Arduino.h>
#include <LiquidCrystal.h>

// LCD (4-bit mode): LiquidCrystal(rs, enable, d4, d5, d6, d7)
LiquidCrystal lcd(PB0, PB1, PA4, PA5, PA6, PA7);

const uint8_t analogPin = A0;

const float VREF = 3.3f;
const float ADC_MAX = 1023.0f;  // 10-bit ADC

// Temperature mapping range
const float TEMP_MIN = 0.0f;
const float TEMP_MAX = 180.0f;

float voltageToTemp(float voltage) {
   // linear mapping from [0..VREF] -> [TEMP_MIN..TEMP_MAX]
   float t = (voltage / VREF) * (TEMP_MAX - TEMP_MIN) + TEMP_MIN;
   // clamp
   if (t < TEMP_MIN) t = TEMP_MIN;
   if (t > TEMP_MAX) t = TEMP_MAX;
   return t;
}

void setup() {
   lcd.begin(16, 2);
   lcd.clear();
   lcd.setCursor(0, 0);
   lcd.print("Temp Reader");
   lcd.setCursor(0, 1);
   lcd.print("Initializing...");
   delay(1000);
   lcd.clear();
}

void loop() {
   // Read raw ADC value
   int raw = analogRead(analogPin);

   // Convert to voltage (float)
   float voltage = (raw * VREF) / ADC_MAX;

   // Convert voltage to temperature (0 - 150)
   float temperature = voltageToTemp(voltage);

   // Compute percentage of VREF (rounded)
   int percent = (int)round((voltage / VREF) * 100.0f);

   // Display — first line: temperature
   lcd.setCursor(0, 0);
   lcd.print("Temp: ");
   lcd.print(temperature, 1);  // one decimal place
   lcd.print(" C   ");         // trailing spaces to clear old chars

   // second line: raw ADC and percent
   lcd.setCursor(0, 1);
   lcd.print("Raw:");
   lcd.print(raw);
   // clear some space (so previous longer numbers don't remain)
   lcd.print("    ");
   lcd.setCursor(10, 1);
   lcd.print(percent);
   lcd.print("%   ");

   delay(500);  // update twice per second
}

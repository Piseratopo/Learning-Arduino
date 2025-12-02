#include <Arduino.h>
#include <LiquidCrystal.h>

LiquidCrystal lcd(PB0, PB1, PA4, PA5, PA6, PA7);

const uint8_t analogPin = A1;
const double VREF = 3.3;
const double ADC_MAX = 1023.0;

const double TEMP_MIN = 0.0;
const double TEMP_MAX = 100.0;

// Kalman filter state
double x_est = 0.0;
double P = 1.0;
const double Q = 0.01;
const double R = 1.0;

// ✅ Parameter to enable/disable Kalman
bool useKalman = true;   // set to false to disable Kalman filtering

double voltageToTemp(double voltage) {
   double A = -11.1634f;
   double B = 39.5307f;
   double C = 1.6443f;
   double t = A + B * voltage + C / (voltage * voltage);
   if (t < TEMP_MIN) t = TEMP_MIN;
   if (t > TEMP_MAX) t = TEMP_MAX;
   return t;
}

double kalmanUpdate(double measurement) {
   P = P + Q;
   double K = P / (P + R);
   x_est = x_est + K * (measurement - x_est);
   P = (1 - K) * P;
   return x_est;
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
   const int N = 50;
   double voltages[N];

   for (int i = 0; i < N; i++) {
      int raw = analogRead(analogPin);
      double voltage = (raw * VREF) / ADC_MAX;
      voltages[i] = voltage;
      delay(1000 / N);
   }

   double filteredVoltage;

   if (useKalman) {
      // Apply Kalman filter
      for (int i = 0; i < N; i++) {
         kalmanUpdate(voltages[i]);
      }
      filteredVoltage = x_est;
   } else {
      // Just use average voltage
      double sum = 0.0;
      for (int i = 0; i < N; i++) sum += voltages[i];
      filteredVoltage = sum / N;
   }

   double filteredTemp = voltageToTemp(filteredVoltage);

   lcd.setCursor(0, 0);
   lcd.print("Temp: ");
   lcd.print(filteredTemp, 1);
   lcd.print(" C   ");
   lcd.setCursor(0, 1);
   lcd.print("Volt: ");
   lcd.print(filteredVoltage, 5);
   lcd.print(" V   ");
}

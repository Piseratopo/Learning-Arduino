#include <Arduino.h>
#include <LiquidCrystal.h>

// LCD (4-bit mode): LiquidCrystal(rs, enable, d4, d5, d6, d7)
LiquidCrystal lcd(PB0, PB1, PA4, PA5, PA6, PA7);

const uint8_t analogPin = A1;

const float VREF = 3.3f;
const float ADC_MAX = 1023.0f;  // 10-bit ADC

// Temperature mapping range
const float TEMP_MIN = 0.0f;
const float TEMP_MAX = 100.0f;

// --- Kalman filter variables ---
float x_est = 0.0f;     // estimated value
float P = 1.0f;         // estimation error covariance
const float Q = 0.01f;  // process noise (tune this)
const float R = 1.0f;   // measurement noise (tune this)

// Convert voltage to temperature
float voltageToTemp(float voltage) {
   float t = (voltage / VREF) * (TEMP_MAX - TEMP_MIN) + TEMP_MIN;
   if (t < TEMP_MIN) t = TEMP_MIN;
   if (t > TEMP_MAX) t = TEMP_MAX;
   return t;
}

// Kalman filter update
float kalmanUpdate(float measurement) {
   P = P + Q;
   float K = P / (P + R);
   x_est = x_est + K * (measurement - x_est);
   P = (1 - K) * P;
   return x_est;
}

// Compute mean and standard deviation
void computeStats(float arr[], int n, float& mean, float& stddev) {
   float sum = 0;
   for (int i = 0; i < n; i++) sum += arr[i];
   mean = sum / n;

   float var = 0;
   for (int i = 0; i < n; i++) var += (arr[i] - mean) * (arr[i] - mean);
   stddev = sqrt(var / n);
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
   float temps[N];

   // Collect 50 samples
   for (int i = 0; i < N; i++) {
      int raw = analogRead(analogPin);
      float voltage = (raw * VREF) / ADC_MAX;
      temps[i] = voltageToTemp(voltage);
      delay(1000 / N);
   }

   // Compute stats
   float mean, stddev;
   computeStats(temps, N, mean, stddev);

   // Reject outliers (keep only within ±2σ)
   for (int i = 0; i < N; i++) {
      if (fabs(temps[i] - mean) <= 2 * stddev) {
         kalmanUpdate(temps[i]);
      }
   }

   // After filtering, use Kalman estimate
   float filteredTemp = x_est;

   // Display filtered temperature
   lcd.setCursor(0, 0);
   lcd.print("Temperature: ");
   lcd.setCursor(0, 1);
   lcd.print(filteredTemp, 1);
   lcd.print(" C   ");
}

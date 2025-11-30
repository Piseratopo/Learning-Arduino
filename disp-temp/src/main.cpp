#include <Arduino.h>
#include <LiquidCrystal.h>

// LCD (4-bit mode): LiquidCrystal(rs, enable, d4, d5, d6, d7)
LiquidCrystal lcd(PB0, PB1, PA4, PA5, PA6, PA7);

const uint8_t analogPin = A1;

const double VREF = 3.3;
const double ADC_MAX = 1023.0;  // 10-bit ADC

// Temperature mapping range
const double TEMP_MIN = 0.0;
const double TEMP_MAX = 100.0;

// --- Kalman filter variables ---
double x_est = 0.0;     // estimated value
double P = 1.0;         // estimation error covariance
const double Q = 0.01;  // process noise (tune this)
const double R = 1.0;   // measurement noise (tune this)

// Convert voltage to temperature
double voltageToTemp(double voltage) {
   // double t = (voltage / VREF) * (TEMP_MAX - TEMP_MIN) + TEMP_MIN;
   double t = -2.96 + 33.62 * voltage + 1.19 * voltage * voltage;
   if (t < TEMP_MIN) t = TEMP_MIN;
   if (t > TEMP_MAX) t = TEMP_MAX;
   return t;
}

// Kalman filter update
double kalmanUpdate(double measurement) {
   P = P + Q;
   double K = P / (P + R);
   x_est = x_est + K * (measurement - x_est);
   P = (1 - K) * P;
   return x_est;
}

// Compute mean and standard deviation
void computeStats(double arr[], int n, double& mean, double& stddev) {
   double sum = 0;
   for (int i = 0; i < n; i++) sum += arr[i];
   mean = sum / n;

   double var = 0;
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
   double voltages[N];

   // Collect 50 voltage samples
   for (int i = 0; i < N; i++) {
      int raw = analogRead(analogPin);
      double voltage = (raw * VREF) / ADC_MAX;
      voltages[i] = voltage;
      delay(1000 / N);
   }

   // Compute stats on raw voltages (optional)
   double mean, stddev;
   computeStats(voltages, N, mean, stddev);

   // Apply Kalman filter on voltages
   for (int i = 0; i < N; i++) {
      kalmanUpdate(voltages[i]);
   }

   // After filtering, use Kalman estimate of voltage
   double filteredVoltage = x_est;

   // Convert filtered voltage to temperature
   double filteredTemp = voltageToTemp(filteredVoltage);

   // Display filtered temperature
   lcd.setCursor(0, 0);
   lcd.print("Temp: ");
   lcd.print(filteredTemp, 1);
   lcd.print(" C   ");
   lcd.setCursor(0, 1);

   lcd.print("Volt: ");
   lcd.print(filteredVoltage, 2);
   lcd.print(" V   ");
}

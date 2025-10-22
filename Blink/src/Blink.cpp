#include <Arduino.h>

int LED_PIN = 13;
int delayTime = 500;

void setup() {
   pinMode(LED_PIN, OUTPUT);
}

void loop() {
   digitalWrite(LED_PIN, HIGH);
   delay(delayTime);
   digitalWrite(LED_PIN, LOW);
   delay(delayTime);
}
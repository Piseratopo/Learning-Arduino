#include <Arduino.h>

const int ledPin = PC13;  // Onboard LED is connected to pin PC13

void setup() {
   pinMode(ledPin, OUTPUT);
}

void loop() {
   digitalWrite(ledPin, HIGH);  // Turn LED on
   delay(500);                  // Wait 500 ms
   digitalWrite(ledPin, LOW);   // Turn LED off
   delay(500);                  // Wait 500 ms
}

#include <Arduino.h>
#include <Wire.h>

#include "rgb_lcd.h"

rgb_lcd lcd;

void setup() {
   lcd.begin(16, 2);
   lcd.print("Hello, LCD!");
}

void loop() {
   lcd.setCursor(0, 1);
   lcd.print(millis() / 1000);
   delay(500);
}
#include <Arduino.h>
#include <Wire.h>

#include "rgb_lcd.h"

rgb_lcd lcd;

void setup() {
   lcd.begin(16, 2);
   lcd.setRGB(255, 0, 0);  // Set the color to red
   lcd.print("Hello, LCD!");
}

void loop() {
}
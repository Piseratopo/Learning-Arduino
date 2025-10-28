#include <Arduino.h>
#include <LiquidCrystal.h>

// RS, RW, E, D4, D5, D6, D7
LiquidCrystal lcd(PA0, PA1, PA2, PA3, PA4, PA5, PA6);

void setup() {
   // Set RW pin to OUTPUT and LOW to force write mode
   pinMode(PA6, OUTPUT);
   digitalWrite(PA6, LOW);

   // Initialize the LCD
   lcd.begin(16, 2);
   lcd.print("Hello, World!");
}

void loop() {
   // Do nothing here...
}

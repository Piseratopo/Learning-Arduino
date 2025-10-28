#include <Arduino.h>
// #include "lcd_arduino.h"
#include <LiquidCrystal.h>

// Using 4-bit mode constructor with RW pinned to GND:
// LiquidCrystal(rs, enable, d4, d5, d6, d7)
LiquidCrystal lcd(PB0, PB1, PA4, PA5, PA6, PA7);

// void setup() {
//   lcd_init();
//   lcd_put_cur(0, 0);
//   lcd_send_string("HELLO");
//   lcd_put_cur(1, 0);
//   lcd_send_string("BLUE PILL :)");
// }

void setup() {
   lcd.begin(16, 2);     // change to (20, 4) if you have a 20x4 module
   lcd.setCursor(0, 0);  // col, row
   lcd.print("CON ME MAY!");
   lcd.setCursor(0, 1);
   lcd.print("CUT RA KHOI DAY!");
}

void loop() {
   // nothing; text stays on LCD
}

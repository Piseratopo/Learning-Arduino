#include <Arduino.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);  // I2C address 0x27, 16 column and 2 rows

// Define a custom character (a simple smiley face)
byte smiley[8] = {
    0b00000,
    0b01010,
    0b01010,
    0b00000,
    0b10001,
    0b01110,
    0b00000,
    0b00000};

void setup() {
   lcd.init();
   lcd.backlight();
   lcd.clear();
   lcd.setCursor(0, 0);       // set cursor to column 0, line 0
   lcd.print("Hello, LCD!");  // print message

   lcd.createChar(0, smiley);

   lcd.setCursor(0, 1);
   lcd.print("Custom Char: ");

   lcd.write(byte(0));
}

void loop() {
}

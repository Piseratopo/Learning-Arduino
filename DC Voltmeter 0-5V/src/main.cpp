#include <Arduino.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);  // I2C address 0x27, 16 column and 2 rows

void setup() {
   lcd.init();  // initialize the lcd
   lcd.backlight();
}

void loop() {
   lcd.clear();                                        // clear display
   int digitalValue = analogRead(0);                   // read analog value from pin A0
   int voltage = map(digitalValue, 0, 1023, 0, 5000);  // map to millivolts
   lcd.setCursor(0, 0);                                // set cursor to first line
   lcd.print("A0: ");
   lcd.print(voltage);
   lcd.print(" mV");
   delay(300);  // wait for 300 milliseconds
}

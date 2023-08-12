#include <Arduino.h>

const int ledPin = 13;
int duration[] = {200, 200, 200, 600, 600, 600, 200, 200, 200};

void flash(int delayTime)
{
  digitalWrite(ledPin, HIGH);
  delay(delayTime);
  digitalWrite(ledPin, LOW);
  delay(delayTime);
}

void setup()
{
  pinMode(ledPin, OUTPUT);
}

void loop()
{
  for (int i = 0; i < 9; i++)
  {
    flash(duration[i]);
  }
  delay(1000);
}

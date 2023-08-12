#include <Arduino.h>

const int ledPin = 13;
const int delayPeriod = 250;

void flash(int numberOfFlashes, int delayPeriod)
{
  for (int i = 0; i < numberOfFlashes; i++)
  {
    digitalWrite(ledPin, HIGH);
    delay(delayPeriod);
    digitalWrite(ledPin, LOW);
    delay(delayPeriod);
  }
}

void setup()
{
  pinMode(ledPin, OUTPUT);
}

void loop()
{
  flash(10, delayPeriod);
  delay(3000);
}
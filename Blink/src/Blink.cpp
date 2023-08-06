#include <Arduino.h>

int LED_PIN = 13;

void setup()
{
    Serial.begin(9600);
    pinMode(LED_PIN, OUTPUT);
}

void loop()
{
    digitalWrite(LED_PIN, HIGH);
    delay(250);
    Serial.println("LED on");
    digitalWrite(LED_PIN, LOW);
    delay(250);
    Serial.println("LED off");
}
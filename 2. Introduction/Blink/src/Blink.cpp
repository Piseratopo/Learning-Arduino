#include <Arduino.h>

int LED_PIN = 13;
int delayTime = 1000;

void setup()
{
    Serial.begin(9600);
    pinMode(LED_PIN, OUTPUT);
}

void loop()
{
    Serial.println("LED on");
    digitalWrite(LED_PIN, HIGH);
    delay(delayTime);
    Serial.println("LED off");
    digitalWrite(LED_PIN, LOW);
    delay(delayTime);
}
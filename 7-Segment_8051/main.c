#include <reg51.h>
#include <intrins.h>

sbit DIGIT_A = P2^2;   // A input of 74HC138
sbit DIGIT_B = P2^3;   // B input of 74HC138
sbit DIGIT_C = P2^4;   // C input of 74HC138


void select_digit(unsigned char digit) {
  switch(digit) {
    case 0: DIGIT_A=0; DIGIT_B=0; DIGIT_C=0; break; // Y0
    case 1: DIGIT_A=1; DIGIT_B=0; DIGIT_C=0; break; // Y1
    case 2: DIGIT_A=0; DIGIT_B=1; DIGIT_C=0; break; // Y2
    case 3: DIGIT_A=1; DIGIT_B=1; DIGIT_C=0; break; // Y3
    case 4: DIGIT_A=0; DIGIT_B=0; DIGIT_C=1; break; // Y4 ? COM1
    case 5: DIGIT_A=1; DIGIT_B=0; DIGIT_C=1; break; // Y5 ? COM2
    case 6: DIGIT_A=0; DIGIT_B=1; DIGIT_C=1; break; // Y6 ? COM3
    case 7: DIGIT_A=1; DIGIT_B=1; DIGIT_C=1; break; // Y7 ? COM4
  }
}


unsigned char seg_code[] = {
  0x3F, // 0
  0x06, // 1
  0x5B, // 2
  0x4F, // 3
  0x66, // 4
  0x6D, // 5
  0x7D, // 6
  0x07, // 7
  0x7F, // 8
  0x6F  // 9
};

// DHT22 connections
sbit DHT22_VCC = P2^7;   // Power pin
sbit DHT22_GND = P2^5;   // Ground pin
sbit DHT22_DATA = P2^1;  // Data pin

void delay_us(unsigned int us) {
    while(us--) _nop_();  // Adjust for your clock frequency
}

void delay_ms(unsigned int ms) {
    unsigned int i, j;
    for(i=0; i<ms; i++)
        for(j=0; j<123; j++);   // Adjust for 12MHz clock
}

void display(unsigned char d1, unsigned char d2, unsigned char d3, unsigned char d4) {
  select_digit(2); P0 = seg_code[d1]; delay_ms(2);
  select_digit(1); P0 = seg_code[d2]; delay_ms(2);
	select_digit(5); P0 = seg_code[d4]; delay_ms(2);
  select_digit(6); P0 = seg_code[d3]; delay_ms(2);
  
}

void main() {
    unsigned char hum = 0;
    unsigned char temp = 0;
    unsigned char i, j;
    unsigned char measured_data[5];

    DHT22_VCC = 1;   // Power on
    DHT22_GND = 0;   // Ground
    DHT22_DATA = 1;  // Idle state

    while (1) {
        // MCU initiates communication
        DHT22_DATA = 0;
        delay_ms(18);        // Pull low for at least 18ms
        DHT22_DATA = 1;
        delay_us(30);        // Wait 20–40us

        // Wait for DHT response: LOW for ~80us, then HIGH for ~80us
        while (DHT22_DATA);  // Wait for DHT to pull LOW
        while (!DHT22_DATA); // Wait for DHT to pull HIGH
        while (DHT22_DATA);  // Wait for DHT to pull LOW again (start of data transmission)

        // Read 5 bytes (40 bits)
        for (j = 0; j < 5; j++) {
            measured_data[j] = 0;
            for (i = 0; i < 8; i++) {
                while (!DHT22_DATA); // Wait for LOW-to-HIGH transition
                delay_us(30);        // Sample at ~30us

                measured_data[j] <<= 1;
                if (DHT22_DATA) {
                    measured_data[j] |= 1; // HIGH > 30us means bit '1'
                }

                while (DHT22_DATA); // Wait for end of HIGH pulse
            }
        }

        // Verify checksum
        if (measured_data[4] == (measured_data[0] + measured_data[1] +
                                 measured_data[2] + measured_data[3])) {
            hum  = measured_data[0]; // Integer part of humidity
            temp = measured_data[2]; // Integer part of temperature
        } else {
            hum  = 0;
            temp = 0;
        }

        // Display on 7-segment
        display(temp / 10, temp % 10, hum / 10, hum % 10);
    }
}


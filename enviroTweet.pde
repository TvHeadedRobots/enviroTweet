#include <stdlib.h>
#include <stdio.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDNS.h>
#include <Twitter.h>
#include <Wire.h>
#include "RTClib.h"
#include <LiquidCrystal.h>

// initialize the library with the numbers of the interface pins
LiquidCrystal lcd(3, 5, 6, 7, 8, 9);
// create degree symbol character
byte degChar[8] = {
	B01100,
	B10010,
	B10010,
	B01100,
	B00000,
	B00000,
	B00000,
	B00000
};

// Set RTC chip
RTC_DS1307 RTC;

// Data wire is plugged into pin 2 on the Arduino
#define ONE_WIRE_BUS 2

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

// Ethernet setup
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x59, 0x6E };
byte ip[] = { 192, 168, 11, 15 };
byte gateway[] = { 192, 168, 11, 1 };
byte subnet[] = { 255, 255, 255, 0 };

//DNS server setup
byte dnsServerIp[] = { 192, 168, 11, 51};

// Twitter setup
Twitter twitter("360833566-8eVR5Aom4D6WFs1IFDLmZpzD6QJbAD1FVOwvikwu"); // Twitter API token

void setup(void)
{  
  // start ethernet
  Ethernet.begin(mac, ip, gateway, subnet);
  
  // start serial port
  Serial.begin(57600);
  Wire.begin();
  RTC.begin();
  // Start up the Dallas temp sensor library
  sensors.begin();
  Serial.println("Hello world, I am enviroTweet.");
  if (! RTC.isrunning()) {
    Serial.println("RTC is NOT running!");
    // following line sets the RTC to the date & time this sketch was compiled
    RTC.adjust(DateTime(__DATE__, __TIME__));
  }
}


void loop(void)
{ 
  DateTime now = RTC.now();
  
  lcd.createChar(0, degChar);
  lcd.begin(16, 2);
  
  int tempF = 0; //temp var 
  // call sensors.requestTemperatures() to issue a global temperature 
  // request to all devices on the bus
  Serial.print("Requesting temperatures...");
  sensors.requestTemperatures(); // Send the command to get temperatures
  Serial.println("DONE");
  
  // Get temp from sensor 1. Why "byIndex"? You can have more than one IC on the same bus. 0 refers to the first IC on the wire
  tempF = (sensors.getTempCByIndex(0) + 40) * 9 / 5 - 40; //C to F conversion
  Serial.print("Temperature for Device 1 is: ");
  Serial.println(tempF);

  lcd.print("Temp 1: ");
  lcd.print(tempF);
  lcd.write(0);
  
  char msg[40]; 
  sprintf(msg, "The temp on %d/%d/%d at %d:%02d:%02d is %d", now.year(), now.month(), now.day(), now.hour(), now.minute(), now.second(), tempF);
  //char msg[] = "is nebody home.....";
  
  Serial.println("connecting to Twitter...");
  if (twitter.post(msg)) {
    int status = twitter.wait(&Serial);
    if (status == 200) {
      Serial.println("OK.");
    } else {
      Serial.print("failed : code ");
      Serial.println(status);
    }
  } else {
    Serial.println("connection failed.");
  }
  
  delay(500000); //wait for next post
  
}

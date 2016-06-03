/*
* Author: Moon, SHTPI, Inc.
*/

#include <WaspSensorGas_Pro.h>
#include <WaspSX1272.h>
#include <WaspFrame.h>

//////////////////////////////////////////
void LoRa_Setup();
//////////////////////////////////////////
int8_t e;
char nodeID[] = "SHTPI014";
int nodeadd = 14;
uint8_t meshlium_address = 1;
int lora_error;
//////////////////////////////////////////
Gas O2(SOCKET_A);
Gas CO(SOCKET_B);
Gas NO2(SOCKET_C);


float CO_value;		// Stores the concentration level in ppm
float O2_value;		// Stores the concentration level in ppm
float NO2_value;	// Stores the concentration level in ppm
float Temp_value;
float Humi_value;
float Pres_value;

unsigned long previous;


//////////////////////////////////////////
char* sleepTime = "00:00:00:15";		// RTC_ABSOLUTE, RTC_ALM1_MODE4, every 10 seconds in 1 minute
char* sleep_WarmUp_Time = "00:00:02:00";	// RTC_OFFSET, RTC_ALM1_MODE1, after 2 minutes

void setup()
{
	// init USB port
	USB.ON();
	RTC.ON();
	delay(100);


	CO.ON();
	NO2.ON();
 	O2.ON();

	NO2.autoGain();
	CO.autoGain();
	O2.autoGain();


	USB.println(F("Sensor Wram up, wait for 1minutes, Using deepsleep mode to reduce the battery consumption"));
	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	CO.OFF();
	NO2.OFF();
 	O2.OFF();

	
	USB.println(F("SX1272 module configuration in LoRa, and Comunication test"));

	frame.setID(nodeID);

	LoRa_Setup(); //first configure
}

void loop()
{
	USB.ON();
	RTC.ON();
	delay(800);

	LoRa_Setup();   //configuring in Loop


/*
	// receive packet
	 e = sx1272.receivePacketTimeout(8000);
	
	 // check rx status
	 if( e == 0 )
	 {
	   USB.println(F("\nShow packet received: "));
	
	   // show packet received
	   sx1272.showReceivedPacket();
	 }
	 else
	 {
	   USB.print(F("\nReceiving packet TIMEOUT, state "));
	   USB.println(e, DEC);  
	 }

 */
	
	 ///////////////////////////////
	 // 1. Get SNR
	 ///////////////////////////////  
	 e = sx1272.getSNR();
	
	 // check status
	 if( e == 0 ) 
	 {
	   USB.print(F("Getting SNR \t\t--> OK. "));
	   USB.print(F("SNR current value is: "));
	   USB.println(sx1272._SNR);
	 }
	 else 
	 {
	   USB.println(F("Getting SNR --> ERROR"));
	 } 
	
	 ///////////////////////////////
	 // 2. Get channel RSSI
	 ///////////////////////////////
	 e = sx1272.getRSSI();
	
	 // check status
	 if( e == 0 ) 
	 {
	   USB.print(F("Getting RSSI \t\t--> OK. "));
	   USB.print(F("RSSI current value is: "));
	   USB.println(sx1272._RSSI);
	
	 }
	 else 
	 {
	   USB.println(F("Getting RSSI --> ERROR"));
	 } 
	
	 ///////////////////////////////
	 // 3. Get last packet received RSSI
	 ///////////////////////////////
	 e = sx1272.getRSSIpacket();
	
	 // check status
	 if( e == 0 ) 
	 {
	   USB.print(F("Getting RSSI packet \t--> OK. "));
	   USB.print(F("Last packet RSSI value is: "));    
	   USB.println(sx1272._RSSIpacket);
	 }
	 else 
	 {
	   USB.println(F("Getting RSSI packet --> ERROR"));
	 } 
	 
	 USB.println();

	Sensor_Reading();

	LoRa_Send();   //Packet Send

	USB.println(F("<<<< Going to Sleep...>>>>"));
	PWR.deepSleep(sleepTime, RTC_OFFSET, RTC_ALM1_MODE1, ALL_OFF);    //Sleep mode
	USB.println(F("<<<< Wake Up! >>>>"));

/*
	previous = millis();
		while (millis() - previous < sleepTime)
		{
		USB.print(".");

	  	if (millis() < previous)
			{
			  previous = millis();
			  }
		}

*/

}

void LoRa_Setup()
{
	USB.println(F("----------------------------------------"));
	USB.println(F("Setting configuration:")); 

	// init SX1272 module  
	sx1272.ON();

	// Select channel
	lora_error = sx1272.setChannel(CH_08_900);
	USB.print(F("Setting Channel CH_08_900.\t state ")); 
	USB.println(lora_error);    

	/*
	// Set packet length
	lora_error = sx1272.setPacketLength(83);
	USB.print(F("Setting Payload Length to '83'.\t state "));
	USB.println(lora_error);
	*/

	// Set Header mode: ON
	lora_error = sx1272.setHeaderON();
	USB.print(F("Setting Header ON.\t\t state "));  
	USB.println(lora_error);

	// Set Mode 
	lora_error = sx1272.setMode(1);
	USB.print(F("Setting Mode '1'.\t\t state "));
	USB.println(lora_error);

	// Select output power (Max, High or Low)
	lora_error = sx1272.setPower('M');
	USB.print(F("Setting Power to 'M'.\t\t state "));
	USB.println(lora_error);

	// Set CRC mode: ON
	lora_error = sx1272.setCRC_ON();
	USB.print(F("Setting CRC ON.\t\t\t state "));
	USB.println(lora_error); 

	// Set Node Address: from 2 to 255
	lora_error = sx1272.setNodeAddress(nodeadd);
	USB.print(F("Setting Node Address to '  '.\t state "));
	USB.print(nodeadd);
	USB.println(lora_error);  
	USB.println();

       lora_error = sx1272.setRetries(3);
       USB.print(F("Setting Max retries to '3'.\t state "));
       USB.println(lora_error);
       USB.println();
	delay(1000);

	USB.println(F("Setting DONE!!")); 
	USB.println(F("----------------------------------------"));
}

void LoRa_Send()
{
		
	  // Creat Frame
	  frame.createFrame(BINARY);
	  frame.addSensor(SENSOR_BAT,PWR.getBatteryLevel());
	  frame.addSensor(SENSOR_RSSI, sx1272._RSSI);
          frame.addSensor(SENSOR_TST, RTC.getEpochTime());
	  frame.addSensor(SENSOR_GP_O2, O2_value);
	  frame.addSensor(SENSOR_GP_TC, Temp_value);
	  frame.addSensor(SENSOR_GP_HUM, Humi_value);
	  frame.addSensor(SENSOR_GP_PRES, Pres_value);
	  frame.addSensor(SENSOR_GP_CO, CO_value);
  	  frame.addSensor(SENSOR_GP_NO2, NO2_value);
          //frame.addSensor(SENSOR_RSSI, sx1272._RSSIpacket);
	  frame.showFrame();
	

	// Sending packet before ending a timeout
	lora_error = sx1272.sendPacketTimeoutACKRetries( meshlium_address, frame.buffer, frame.length );

	// if ACK was received check signal strength
	if( lora_error == 0 )
	{	
		USB.println(F("Packet sent OK!!"));
		//Utils.setLED(LED1, LED_ON);delay(1000);Utils.setLED(LED1, LED_OFF);	
		Utils.blinkLEDs(200);
	}
	else 
	{
		USB.println(F("Error sending the packet"));  
		USB.print(F("state: "));
		USB.println(lora_error, DEC);
		Utils.setLED(LED0, LED_ON);delay(1000);Utils.setLED(LED0, LED_OFF);
	}
        USB.println(RTC.getEpochTime());

}


void Sensor_Reading()
{
 	CO.ON();
 	O2.ON();
 	NO2.ON();
	delay(1000);

//	USB.println(F("Sensor Wram up, wait for 2minutes, Using deepsleep mode to reduce the battery consumption"));
//	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	CO.autoGain();
	O2.autoGain();
	NO2.autoGain();

  	CO_value = CO.getConc();
	O2_value = O2.getConc();
	NO2_value = NO2.getConc();  //MCP3421_ULTRA_HIGH_RES 

	Temp_value = CO.getTemp();
	Humi_value = CO.getHumidity();
	Pres_value = CO.getPressure();

	USB.println(F("****************  Gas Sonsor  *********************"));
	USB.print(F("CO concentration: "));
	USB.print(CO_value);
	USB.println(F(" ppm"));
	USB.print(F("NO2 concentration: "));
	USB.print(NO2_value);
	USB.println(F(" ppm"));
	USB.print(F("O2 concentration: "));
	USB.print(O2_value);
	USB.println(F(" ppm"));
	
	USB.print(F("Temperature: "));
	USB.print(Temp_value);
	USB.println(F(" Celsius degrees"));
	USB.print(F("RH: "));
	USB.print(Humi_value);
	USB.println(F(" %"));
	USB.print(F("Pressure: "));
	USB.print(Pres_value);
	USB.println(F(" Pa"));

	CO.OFF();
	NO2.OFF();
	O2.OFF();
}



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
char nodeID[] = "SHTPI002";
uint8_t meshlium_address = 1;
int lora_error;
//////////////////////////////////////////
Gas O2(SOCKET_A);
Gas CO(SOCKET_B);
Gas NO2(SOCKET_C);
Gas HCN(SOCKET_F);

float CO_value;		// Stores the concentration level in ppm
float O2_value;		// Stores the concentration level in ppm
float NO2_value;	// Stores the concentration level in ppm
float HCN_value;	// Stores the concentration level in ppm
float Temp_value;
float Humi_value;
float Pres_value;

//////////////////////////////////////////
char sleepTime[] = "00:00:00:04";		// RTC_ABSOLUTE, RTC_ALM1_MODE4, every 10 seconds in 1 minute
char* sleep_WarmUp_Time = "00:00:02:00";	// RTC_OFFSET, RTC_ALM1_MODE1, after 2 minutes

void setup()
{
	// init USB port
	USB.ON();
	RTC.ON();
	delay(100);


	CO.ON();
	NO2.ON();
 	HCN.ON();
 	O2.ON();
	NO2.autoGain();
	CO.autoGain();
	USB.println(F("Sensor Wram up, wait for 1minutes, Using deepsleep mode to reduce the battery consumption"));
	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	CO.OFF();
	NO2.OFF();
 	HCN.OFF();
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


//	 O2_Reading();
//	 CO_Reading();
//	 HCN_Reading();
//	 NO2_Reading();

	Sensor_Reading();

	LoRa_Send();   //Packet Send

	USB.println(F("<<<< Going to Sleep...>>>>"));
//	PWR.deepSleep(sleepTime, RTC_ABSOLUTE, RTC_ALM1_MODE1, ALL_OFF);    //Sleep mode
	USB.println(F("<<<< Wake Up! >>>>"));
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
	lora_error = sx1272.setPower('H');
	USB.print(F("Setting Power to 'H'.\t\t state "));
	USB.println(lora_error);

	// Set CRC mode: ON
	lora_error = sx1272.setCRC_ON();
	USB.print(F("Setting CRC ON.\t\t\t state "));
	USB.println(lora_error); 

	// Set Node Address: from 2 to 255
	lora_error = sx1272.setNodeAddress(5);
	USB.print(F("Setting Node Address to '5'.\t state "));
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
	  frame.addSensor(SENSOR_GP_HCN, HCN_value);
          //frame.addSensor(SENSOR_RSSI, sx1272._RSSIpacket);
	  frame.showFrame();


	// Sending packet before ending a timeout
	lora_error = sx1272.sendPacketTimeoutACK( meshlium_address, frame.buffer, frame.length );

	// if ACK was received check signal strength
	if( lora_error == 0 )
	{	
		USB.println(F("Packet sent OK!!"));
		Utils.blinkLEDs(200);
	}
	else 
	{
		USB.println(F("Error sending the packet"));  
		USB.print(F("state: "));
		USB.println(lora_error, DEC);
	}
        USB.println(RTC.getEpochTime());

}


void CO_Reading()
{
	CO.ON();
	
	USB.println(F("****************  CO  *********************"));
        //PWR.deepSleep(sleep_WarmUp_Time, RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	CO_value = CO.getConc();

	// Read the O2 sensor and compensate with the temperature internally
	Temp_value = CO.getTemp();
	Humi_value = CO.getHumidity();
	Pres_value = CO.getPressure();
		
	USB.print(F("Gas concentration: "));
	USB.print(CO_value);
	USB.println(F(" ppm"));
	USB.print(F("Temperature: "));
	USB.print(CO.getTemp());
	USB.println(F(" Celsius degrees"));
	USB.print(F("RH: "));
	USB.print(CO.getHumidity());
	USB.println(F(" %"));
	USB.print(F("Pressure: "));
	USB.print(CO.getPressure());
	USB.println(F(" Pa"));

	CO.OFF();

}

void O2_Reading()
{
	O2.ON();

	USB.println(F("****************  O2  *********************"));
	//PWR.deepSleep(sleep_WarmUp_Time, RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	// Read the O2 sensor and compensate with the temperature internally
	O2_value = O2.getConc();
	Temp_value = O2.getTemp();
	Humi_value = O2.getHumidity();
	Pres_value = O2.getPressure();
	
	USB.print(F("Gas concentration: "));
	USB.print(O2_value);
	USB.println(F(" ppm"));
	USB.print(F("Temperature: "));
	USB.print(O2.getTemp());
	USB.println(F(" Celsius degrees"));
	USB.print(F("RH: "));
	USB.print( O2.getHumidity());
	USB.println(F(" %"));
	USB.print(F("Pressure: "));
	USB.print(O2.getPressure());
	USB.println(F(" Pa"));

	O2.OFF();
}

void HCN_Reading()
{
	HCN.ON();

	USB.println(F("****************  HCN  *********************"));
	//PWR.deepSleep(sleep_WarmUp_Time, RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	HCN_value = HCN.getConc();
	Temp_value = HCN.getTemp();
	Humi_value = HCN.getHumidity();
	Pres_value = HCN.getPressure();
	
	USB.print(F("Gas concentration: "));
	USB.print(HCN_value);
	USB.println(F(" ppm"));
	USB.print(F("Temperature: "));
	USB.print(HCN.getTemp());
	USB.println(F(" Celsius degrees"));
	USB.print(F("RH: "));
	USB.print(HCN.getHumidity());
	USB.println(F(" %"));
	USB.print(F("Pressure: "));
	USB.print(HCN.getPressure());
	USB.println(F(" Pa"));

	HCN.OFF();
}

void Sensor_Reading()
{
 	CO.ON();
 	HCN.ON();
 	O2.ON();
 	NO2.ON();

//	USB.println(F("Sensor Wram up, wait for 2minutes, Using deepsleep mode to reduce the battery consumption"));
//	PWR.deepSleep("00:00:02:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);

	CO.autoGain();
	NO2.autoGain();

  	CO_value = CO.getConc();
	O2_value = O2.getConc();
	HCN_value = HCN.getConc();  
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
	USB.print(F("HCN concentration: "));
	USB.print(HCN_value);
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
	HCN.OFF();
	O2.OFF();


//	USB.println(F("<<<< Going to Sleep...>>>>"));
//	PWR.deepSleep(sleepTime, RTC_ABSOLUTE, RTC_ALM1_MODE1, ALL_OFF);    //Sleep mode
//	USB.println(F("<<<< Wake Up! >>>>"));
	
}

void NO2_Reading()
{
	//NO2.ON();
	NO2.ON();  //inscreasing the gain resistor to maxium at 7 (LMP91000_GAIN_7)

	NO2.configureAFE(LMP91000_GAIN_7);
	//NO2.autoGain();
	USB.println(F("Sensor Wram up, wait for 1minutes, Using deepsleep mode to reduce the battery consumption"));
	PWR.deepSleep("00:00:01:00", RTC_OFFSET, RTC_ALM1_MODE1, ALL_ON);
	
	USB.println(F("****************  NO2  *********************"));


	NO2_value = NO2.getConc();
	Temp_value = NO2.getTemp();
	Humi_value = NO2.getHumidity();
	Pres_value = NO2.getPressure();
	
	USB.print(F("Gas concentration: "));
	USB.print(NO2_value);
	USB.println(F(" ppm"));
	USB.print(F("Temperature: "));
	USB.print(NO2.getTemp());
	USB.println(F(" Celsius degrees"));
	USB.print(F("RH: "));
	USB.print(NO2.getHumidity());
	USB.println(F(" %"));
	USB.print(F("Pressure: "));
	USB.print(NO2.getPressure());
	USB.println(F(" Pa"));

	NO2.OFF();

}

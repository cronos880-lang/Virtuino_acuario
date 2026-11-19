
#include <Wire.h>
#include "VirtuinoCM.h" //Libreria de la interface
#include <OneWire.h>
#include <DallasTemperature.h> //Libreria para procesar temperatura
#include <avr/wdt.h> //Libreria Whathdog 

#include "RTClib.h" //Hemos cambiado la libreria del Reloj

#include <EEPROM.h> // Para grabar y leer datos de la eprom



RTC_DS3231 rtc; //definimos el RTC

VirtuinoCM virtuino; //Definimos el Virtuino

//-------------VirtuinoCM  Library and settings --------------           
#define V_memory_count 256          // the size of V memory. You can change it to a number <=255)
float V[V_memory_count];           // This array is synchronized with Virtuino V memory. You can change the type to int, long etc.
boolean debug = true; 

//------------- DEFINIMOS EL SENSOR --------------------------
     OneWire ourWire(8);  //Se establece el pin 8  como bus OneWire para la lectura de temperatura
     DallasTemperature sensors(&ourWire); //Se declara una variable u objeto para nuestro sensor
     
//-----------------------------------------------------------

//============= VARIABLES GLOBALES NO MODIFICABLES ===========

const int v_temp=2; //Variable temperatura
const int v_hora=3; //Variable set hora
const int v_min=4; //Variable set minutos
const int v_lumens=4; //Variable intensidad luces
const int cero=0;

//***********************************************************************
//bool configActiva = false;
//int menuConfig = 0;
//int ultimoMenuConfig = -1;

//unsigned long tiempoUltimaAccionConfig = 0;
//const unsigned long TIMEOUT_CONFIG = 180000;   // 3 minutos
//*************************************************************************


//====================== VARIABLES QUE VAN A VIRTUINO ===========================

float V2; //Almacenamos la hora 
float V3; //Almacenamos los minutos
float V4; //Almacenamos los segundos

/***********************************************************************
/************* LISTAO DE VARIABLES UTILIZADAS EN EL VIRTUINO ***********

 ++       V1  De Reserva !!!!!!!
 ++       V5  Almacenamos la temperatura del agua (igual que la V35)
 ++       V6  Señal de HEATING ON
 ++       V7  Señal de HEATING OFF
 ++       V8  Para visualiza en arduino el estado de la Bomba
 ++       V9  Para entrar en el setup del programa
 ++       V10 Visualizamos lumens
 ++       V11 Si estamos en dentro de setup se lo decimos a virtuino
 ++       V12 Variable que condiciona el cambio de hora
 ++       V13 Variable que condiciona el cambio de minutos
 ++       V15 Pulsador bomba Manual ON/OFF
 ++       V16 Pulsador Luces Manual ON/OFF
 ++       V20 Pulsador entrar en Setup
 ++       V21 Hemos entrado en setup
 ++       V22 opcion cambio de Hora (ventana emergente)
 ++       V23 Almacenamos la hora de la ventana emergente
 ++       V24 Aceptar cambios del setup
 ++       V25 Para salir del menu configuración
 **       V26 Opcion 1 del setup
 **       V27 Temperatura grabada en Eprom
 **       V28 Lumens grabados en Eprom
 **       V29 Man/Auto Bomba
 **       V30 Indica que hemos entrado en el setup
 **       V31
 **       V35 Lectura con decimales de la temperatura
 **       V40 Para saber si hemos entrado en configuracion       
 

/**********************************************************************
/**********************************************************************
*/

//============== VARIABLES GLOBALES MODIFICABLES ===============
int luz=0;  //variable para dar valor al pwm pin 3
int luz1=0; //variable para dar valor al pwm pin 6
int lumen=0; //Variable para dar valor a la intensidad de los leds
int lumen1=10;
//int cuenta=0;
//int incrementa=0;
int configuracion=0;
int Vtemp;
//int luz_max=0; // Variable de luz al maximo /apagado
int bomba_max=0;// Variable de bomba on /off

//Variables para la histeresis de la temperatura
float Hismax=0.2;
float Hismin=0.2;
float Setpoint=0;

//VARIABLES PARA HACER UN RETARDO DE 1 SEGUNDO EN LA LECTURA DE LA TEMPERATURA/
unsigned long tTemp = 0;
const unsigned long PERIODO_TEMP = 1000; // 1 segundo, para mejor filtro 1500


void setup () {
    if (debug) {
    Serial.begin(9600);
    wdt_disable();//Desabilitar el watchdog 
    
    while (!Serial) continue;
  }
   
     Serial1.begin(9600);  
     Serial1.setTimeout(50);

    Wire.begin();
    delay(500);
    virtuino.begin(onReceived,onRequested,256); 
    rtc.begin(); //Iniciamos el Reloj RTC
    sensors.begin(); // Iniciamos el Sensor de temperatura
    sensors.setResolution(12); 


     //************** DEFINIMOS LOS PINES DEL ARDUINO ************//

    pinMode(2, OUTPUT); // Activamos Rele calentador
    pinMode(4, OUTPUT); // Activamos Rele Bomba agua
    pinMode(12, OUTPUT); // Activamos Rele Luz Noche
    pinMode(13, OUTPUT);
    //pin 3 salida analogica pwm
    //pin 6 salida analogica pwm
    
                       ///// LEEMOS DATOS DE LA EPROM  /////()
                     
//// Tipo de dato	Tamaño (bytes)	Rango de direcciones ocupadas
//// float	4 bytes	0 a 3
//// int	2 bytes	0 a 1
//// long	4 bytes	0 a 3
//// byte/uint8_t	1 byte	0  

    // EEPROM.begin(512);  // Solo para ESP8266/ESP32
    EEPROM.get(0, lumen);  // Lee el valor guardado y lo almacena en la variable lumen
    EEPROM.get(2, Setpoint); //Lee el valor guardado del Setpoint Temperatura Agua
    //EEPROM.get(6, Hismax); //Lee el valor guardado de la histeresis
  
   // Hismin==Hismax; //De momento usaremos este dato grabado en la eprom para las dos variables

   //************** AJUSTE DE HORA SI ES NECESARIO *******************//
    // Ajusta la fecha y la hora a la fecha y hora actual (por ejemplo, 30 de agosto de 2024, 15:30:00)
    //rtc.adjust(DateTime(2024, 8, 30, 20, 17, 0)); // configuramos hora manualmente
    //rtc.adjust(DateTime(F(__DATE__), F(__TIME__))); /configuramos hora con la del pc
    V[27]= Setpoint;
    V[28]= lumen;
    vDelay(50);
    wdt_enable(WDTO_8S); //En pruebas
}


void loop () {

    wdt_reset();  //Reseteamos el Watchdog para evitar el reinicio
    virtuinoRun();
    DateTime now = rtc.now(); //Configuracion del RTC
    configuracion=V[9];
    
    //EMPIEZAN LOS SUBPROGRAMAS//

    ////////////////////////////////////////////////////////
    // Acemos una lectura de la temperatura cada 1 segundo
    if (millis() - tTemp >= PERIODO_TEMP) {
        tTemp = millis();
        Temperature(&Vtemp, &Setpoint, &Hismax, &Hismin);
    }
    ////////////////////////////////////////////////////////

    Reloj(now); 
    Bomba(now);  
    Luces(&lumen, &luz, &luz1, now);


    if(configuracion==1){
       Config(&lumen, &Setpoint, now);
       V[9] = 0; // Reset automático para no entrar en bucle infinito //ESTO ESTA EN PRUEBAS//
    }
    
    //EMVIAMOS DATOS AL PWM PARA LAS LUCES
    analogWrite(3,luz); //Damos el valor del PWM atraves del pin 3
    analogWrite(6, luz);//(6,luz1);//Damos el valor del PWM atraves del pin 6
    V[10]=lumen;
    /////////////////////////////

    //vDelay(1000);
}

//============================================================== onCommandReceived
//==============================================================
/* This function is called every time Virtuino app sends a request to server to change a Pin value
 * The 'variableType' can be a character like V, T, O  V=Virtual pin  T=Text Pin    O=PWM Pin 
 * The 'variableIndex' is the pin number index of Virtuino app
 * The 'valueAsText' is the value that has sent from the app   */
 void onReceived(char variableType, uint8_t variableIndex, String valueAsText){     
    if (variableType=='V'){
        float value = valueAsText.toFloat();        // convert the value to float. The valueAsText have to be numerical
        if (variableIndex<V_memory_count) V[variableIndex]=value;              // copy the received value to arduino V memory array
    }
}

//==============================================================
/* This function is called every time Virtuino app requests to read a pin value*/
String onRequested(char variableType, uint8_t variableIndex){     
    if (variableType=='V') {
    if (variableIndex<V_memory_count) return  String(V[variableIndex]);   // return the value of the arduino V memory array
  }
  return "";
}

//============================================================== virtuinoRun
  void virtuinoRun(){
    while (Serial1.available()) {
        char tempChar=Serial1.read();
        if (tempChar==CM_START_CHAR) {               // a new command is starting...
              virtuino.readBuffer=CM_START_CHAR;     // copy the new command to the virtuino readBuffer
              virtuino.readBuffer+=Serial1.readStringUntil(CM_END_CHAR);
              virtuino.readBuffer+=CM_END_CHAR;
              if (debug) Serial.println("\nCommand= "+virtuino.readBuffer);
              String* response= virtuino.getResponse();    // get the text that has to be sent to Virtuino as reply. The library will check the inptuBuffer and it will create the response text
              if (debug) Serial.println("Response : "+*response);
              Serial1.print(*response);
              break; 
         }
    }
 }
 


 //============================================================== vDelay
  void vDelay(int delayInMillis){long t=millis()+delayInMillis;while (millis()<t) virtuinoRun();}


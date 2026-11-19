
//********************************************************************** //
//****** ATRAVES DEL MENU SETUP DE VIRTUINO CAMBIAMOS LOS VALORES ****** //
//****** DE LA HORA, LUMINOSIDAD, HORA ENCENDIDO Y APAGADO ************* //
//********************************************************************** //


void Config(int*lumen, float*Setpoint, DateTime now) {

  int salir=1; 
  int aceptar=0; //aceptamos los cambios antes de salir
  int config=0;  //para el menu de configuracion
  int bucle=0;   //para entrar y salir del bucle
  int menu=0;    //variable para entrar en el menu convertir en un case"

  ////////////////// Estas son para variar la hora en el rtc ////////////////
  int hour;
  int minute;
  int second;
  int year;
  int month;
  int day;

//*** CARGAMOS LOS VALORES DEL RELOJ EN LAS VARIABLES ***

    year=now.year();
    month=now.month();
    day=now.day();
    hour=now.hour();
    minute=now.minute();
    second=now.second();

//*********************************************************

  V[25]=0; //Para salir del menu configuracion
  vDelay(50);

 //*****************************************************************************
 wdt_disable();//Desabilitar el watchdog 
 while(config==0)
     {
      // wdt_reset();  //Reseteamos el Watchdog para evitar el reinicio            
       
       V[30]=1;
       menu=V[26];//"variable de arduino"
       vDelay(50);
       
       // menu //En esta variable almacenamos el valor de la opcion que se elija
       switch (menu) {
       case 1:  //CAMBIAMOS HORA       
            while(bucle==0)
               { 
                  V[40]=1;//para saber que hemos entrado, luego lo borramos
                  aceptar=V[24];
                  vDelay(50);
                  if(aceptar==1){
                    hour=V[23];
                    vDelay(200);
                    rtc.adjust(DateTime(year, month, day, hour, minute,second));
                    V[40]=0;
                    bucle=1;
                  }         
                } 
            break;
      case 2:  //CAMBIAMOS MINUTOS
           while(bucle==0)
              {
                  V[40]=1;//para saber que hemos entrado, luego lo borramos
                  aceptar=V[24];
                  vDelay(50);
                  if(aceptar==1){
                    minute=V[23];
                    vDelay(200);
                    rtc.adjust(DateTime(year, month, day, hour, minute,second));
                    V[40]=0;
                    bucle=1;
                  }           
              } 
          break;
      case 3: // CAMBIAMOS LUMENS
           while(bucle==0)
              {
                  V[40]=1;//para saber que hemos entrado, luego lo borramos
                  aceptar=V[24];
                  vDelay(50);
                  if(aceptar==1){
                    *lumen=V[23];
                    vDelay(200);
                    V[40]=0;
                    //Introducimos el valor de la intensidad  de las  luces en los arranques desde cero
                    // Guardar en EEPROM (usa 2 bytes si es 'int') la siguiente se almacena en la posicion 2
                    EEPROM.put(0, *lumen); // Usamos EEPROM.put para guardar la variable
                   // Opcional: Forzar la escritura en EEPROM (si es crítico)
                   // EEPROM.commit();  // Solo necesario en algunas placas (ESP8266/ESP32)
                    bucle=1;
                  }
            
              }     
          break;
      case 4: //CAMBIAMOS SETPOINT TEMPERATURA AGUA
          while(bucle==0)
          {
                  V[40]=1;//para saber que hemos entrado, luego lo borramos
                  aceptar=V[24];
                  vDelay(50);
                  if(aceptar==1){
                     *Setpoint = V[23]; 
                    vDelay(200);      
                    V[40]=0;
                    EEPROM.put(2, *Setpoint); // Usamos EEPROM.put para guardar la variable
                    bucle=1;
                  }

          }
          break;
      }  
        if(V[25]==1)
          {
            config=1;
          }    
     }
     V[30]=0;
     V[40]=0;
     V[10]=*lumen;

     vDelay(100);
     wdt_enable(WDTO_8S); //En pruebas
 }


///////////////////////////////////////////////////////////////////////////////////////////////

/*
void Config(int *lumen, float *Setpoint, DateTime now) {

    int config = 0;
    int menu = 0;
    int aceptar = 0;
    int salir = 0;
    int bucle = 0;

    // Variables para modificar la hora del RTC
    int hour;
    int minute;
    int second;
    int year;
    int month;
    int day;

    // Temporizador de seguridad para evitar quedarse atrapado
    unsigned long tiempoInicioConfig = millis();
    const unsigned long TIMEOUT_CONFIG = 180000;   // 3 minutos

    // Cargamos los valores actuales del reloj
    year   = now.year();
    month  = now.month();
    day    = now.day();
    hour   = now.hour();
    minute = now.minute();
    second = now.second();

    // Inicialización de banderas Virtuino
    V[24] = 0;   // aceptar
    V[25] = 0;   // salir
    V[30] = 1;   // estamos dentro de configuración
    V[40] = 0;   // no estamos dentro de una opción concreta

    vDelay(50);

    wdt_disable();   // deshabilitamos watchdog dentro del menú

    while (config == 0) {

        // Seguridad: salir automáticamente si pasa demasiado tiempo
        if (millis() - tiempoInicioConfig >= TIMEOUT_CONFIG) {
            config = 1;
            break;
        }

        menu = V[26];
        salir = V[25];
        vDelay(50);

        if (salir == 1) {
            config = 1;
            break;
        }

        switch (menu) {

            case 1:   // CAMBIAR HORA
                bucle = 0;
                V[40] = 1;

                while (bucle == 0) {

                    // Seguridad timeout también dentro del submenú
                    if (millis() - tiempoInicioConfig >= TIMEOUT_CONFIG) {
                        bucle = 1;
                        config = 1;
                        break;
                    }

                    aceptar = V[24];
                    salir = V[25];
                    vDelay(50);

                    if (aceptar == 1) {
                        hour = V[23];
                        rtc.adjust(DateTime(year, month, day, hour, minute, second));
                        V[24] = 0;
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                    }

                    if (salir == 1) {
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                        config = 1;
                    }
                }
                break;


            case 2:   // CAMBIAR MINUTOS
                bucle = 0;
                V[40] = 1;

                while (bucle == 0) {

                    if (millis() - tiempoInicioConfig >= TIMEOUT_CONFIG) {
                        bucle = 1;
                        config = 1;
                        break;
                    }

                    aceptar = V[24];
                    salir = V[25];
                    vDelay(50);

                    if (aceptar == 1) {
                        minute = V[23];
                        rtc.adjust(DateTime(year, month, day, hour, minute, second));
                        V[24] = 0;
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                    }

                    if (salir == 1) {
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                        config = 1;
                    }
                }
                break;


            case 3:   // CAMBIAR LUMENS
                bucle = 0;
                V[40] = 1;

                while (bucle == 0) {

                    if (millis() - tiempoInicioConfig >= TIMEOUT_CONFIG) {
                        bucle = 1;
                        config = 1;
                        break;
                    }

                    aceptar = V[24];
                    salir = V[25];
                    vDelay(50);

                    if (aceptar == 1) {
                        *lumen = V[23];

                        if (*lumen < 0) *lumen = 0;
                        if (*lumen > 255) *lumen = 255;

                        EEPROM.put(0, *lumen);
                        V[28] = *lumen;
                        V[10] = *lumen;
                        V[24] = 0;
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                    }

                    if (salir == 1) {
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                        config = 1;
                    }
                }
                break;


            case 4:   // CAMBIAR SETPOINT TEMPERATURA
                bucle = 0;
                V[40] = 1;

                while (bucle == 0) {

                    if (millis() - tiempoInicioConfig >= TIMEOUT_CONFIG) {
                        bucle = 1;
                        config = 1;
                        break;
                    }

                    aceptar = V[24];
                    salir = V[25];
                    vDelay(50);

                    if (aceptar == 1) {
                        *Setpoint = V[23];

                        if (*Setpoint < 20.0) *Setpoint = 20.0;
                        if (*Setpoint > 35.0) *Setpoint = 35.0;

                        EEPROM.put(2, *Setpoint);
                        V[27] = *Setpoint;
                        V[24] = 0;
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                    }

                    if (salir == 1) {
                        V[40] = 0;
                        V[26] = 0;
                        bucle = 1;
                        config = 1;
                    }
                }
                break;
        }
    }

    // Salida limpia de configuración
    V[24] = 0;
    V[25] = 0;
    V[26] = 0;
    V[30] = 0;
    V[40] = 0;
    V[10] = *lumen;
    V[27] = *Setpoint;
    V[28] = *lumen;

    vDelay(100);
    wdt_enable(WDTO_8S);
}
*/





/////////////////////////////////////////////////////////////////////////////////////
//RESTRUCTURACION TOTAL DE LA SUBRUTINA CONFIG
////////////////////////////////////////////////////////////////////////////////////////

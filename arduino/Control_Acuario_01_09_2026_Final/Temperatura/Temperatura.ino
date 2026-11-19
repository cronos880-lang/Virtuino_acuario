void Temperature(int Vtemp) 
{
   int temp;
   //leemos temperatura de la sonda 
   //temp = sonda
   if(temp<24.5){
      //activamos rele calentador
      V6=1;
     }
   if(temp<25.5){
      //activamos rele calentador
      V6=0;
     }

  *Vtemp=25;

}



void Reloj(DateTime now) 
{

    V2=now.hour(); //Leemos la hora ya la enviamos al virtuino
    V[2] = V2;
    vDelay(50);
    V3=now.minute(); //Leemos los minutos y lo enviamos al virtuino
    V[3] = V3;
    vDelay(50);
    V4=now.second(); //Leemos los segundos y los enviamos al virtuino
    V[4] = V4;
    vDelay(50);
}



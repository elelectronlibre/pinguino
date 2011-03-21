/*
El programa lee los datos grabados en la EEPROM y los
manda al ordenador de 2 en dos (de int en int).
Para que no haya errores en el envío, se pide una señal
de reconocimiento que el ordenador debe mandar a cada 
par de bytes recibido. Esto ralentiza el programa, pero
hace que salga bien.
*/
#include <libI2C.c>

u8 fin=0;
u8 i;
u16 j;
unsigned char continuar=0;
unsigned char datos[64];
unsigned char recibido=0;
unsigned char hival; 
unsigned char lowval;
unsigned int valor;
unsigned int posicion=0x0000;
uchar salida[1];

unsigned char LeerMemoria(u16 posicion){

	u8 hipos;
	u8 lowpos;
	u8 cadena[8];
	fin=0;
	if(posicion<0xFF)
	{
		hipos=0;
		lowpos=posicion;
	}
	else
	{
	lowpos=posicion&0x00FF;
	hipos=posicion>>8;
	}
	/*debug
	lcd.setCursor(10,0);
	lcd.printNumber(posicion,DEC);
	*/
	cadena[0] = hipos;
	cadena[1] = lowpos;
	
	I2C_write(0x50,cadena,2);
	i=I2C_read(0x50,2);
	I2C_STOP();
	
	if(i>0)
	{
		hival=i2c_buffer[0];
		lowval=i2c_buffer[1];
		valor=hival*0b11111111 + lowval;
		if(hival==0xff){
		if(lowval==0xff){
		fin=1;
		}
		}
				
	}
	return i;
}

void setup(){

//Inicializamos el lcd
	lcd(8,9,4,5,6,7,0,0,0,0);
	lcd.begin(2,0);
	lcd.print("Lector EEPROM");
	lcd.setCursor(0,1);
	lcd.print("Elelectronlibre");
//Preparamos el bus I2C
	init_I2C();
	for (i=0;i<8;i++) i2c_buffer[i]=0;
	recibido=CDC.read(datos);
}

void loop(){
	if(continuar==0)
	{
		recibido=CDC.read(datos);
	
		if(recibido==0)
			{
			continuar=0;
			}
		else
			{
			lcd.clear();
			lcd.print("Enviando...");
			continuar=1;
			}
	}
	else
	{
		//CDC.print("Comienzo",9);
		for(j=0;j<8000;j++)
			{
			recibido=0;
			posicion=2*j;
			i=LeerMemoria(posicion);

				if(i==0)
				{
					CDC.print("e",1);
					j=8000;
					
				}
				else
				{
					if(fin==1)
					{
						CDC.print("fin",3);
						j=8000;
					}
					else
					{
					sprintf(salida,"%d", valor);
					//delay(1);
					CDC.print(salida,strlen(salida));
					while(recibido==0)
						{
						recibido=CDC.read(datos);
						}
					}
					
				}
			}
		//CDC.print("f",1);
		lcd.clear();
		lcd.print("Terminado");
		while(1);
	}

}

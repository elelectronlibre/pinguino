/*
TempLogger
Daniel Rodríguez
10/3/2011
Funcionamiento:
Conectar la placa Pingüino según el esquema adjunto a este archivo.
Tras el mensaje de inicio, pulsar el botón. La eeprom se borrará 
y comenzará a grabar. Si se vuelve a pulsar, se detiene la grabación.
El programa realiza una media entre 4 grabaciones en 1 minuto 
para dar el dato final. 

*/

#include <libI2C.c>
#define sensor 14
#define led PORTBbits.RB3

//Declaración de variables
unsigned char empezar=0;
u16 cuenta=1;
u8 grabar=1;
unsigned int lectura[4];
unsigned char decimales;
unsigned char unidades;
unsigned int posicion=0x0000;
u8 i;
u8 a;
u16 j;
u16 posmax;
u16	DatoBorrado;
u8 cuentamedia=0;
u16 lecturamedia=0;
u16 sensado;

void UserInterrupt(){

	if(INTCON3bits.INT2IF==1) //Interrupción externa (pulsador)
	{
		delay(50);
		while(PORTBbits.RB2==1);
		INTCON3bits.INT2IF=0;
		empezar++;
		lcd.clear();
		lcd.print("Grabando...");
		if(empezar>1)
		{
			empezar=0;
			lcd.clear();
			lcd.print("DETENIDO");
		}
	}
	if(PIR1bits.TMR1IF==1) //Interrupción timer 1
	{
		PIR1bits.TMR1IF=0;
		cuenta++;
		TMR1L=220;
		TMR1H=11;
		if(cuenta>60)//4hz*60segundos=240/4lecturas=60
		{
			grabar=1;
			cuenta=1;
		}
	}
}

unsigned char Decimal(float Temp){
	unidades=(uchar) Temp/1;
	Temp=Temp-unidades;
	Temp=Temp*100;
	return Temp;
}

unsigned char GrabarTemperatura1(u16 pos,u16 valor)
{

	u8 hipos;
	u8 lowpos;
	u8 cadena[3];
	u8 hival;
	u8 lowval;
	
	lowpos=pos & 0x00FF;
	hipos=pos >> 8;
	lowval=valor & 0x00FF;
	hival=valor >> 8;
	
	cadena[0]= hipos;
	cadena[1]= lowpos;
	cadena[2]= lowval;
	

	
	i=I2C_write(0x50,cadena,3);
	I2C_STOP();
		
	return i;

}

unsigned char BorrarMemoria8(u16 pos)
{

	u8 hipos;
	u8 lowpos;
	u8 cadena[10];

	
	lowpos=pos & 0x00FF;
	hipos=pos >> 8;
	
	cadena[0]= hipos;
	cadena[1]= lowpos;
	
	for(i=2;i<9;i++)
	{
		cadena[i]=0xFF;
	}
	

	
	i=I2C_write(0x50,cadena,10);
	I2C_STOP();
		
	return i;

}
void setup(){

//Preparamos la interrupción externa 2 (pulsación del botón B2)
	TRISB=0b00000100;
	INTCON2bits.INTEDG2=1;//Flanco de subida
	INTCON3bits.INT2IP=1;//Prioridad alta
	INTCON3bits.INT2IE=1;
	INTCON3bits.INT2IF=0;
	//INTCONbits.GIE=1; //Todavía no iniciamos la interrupción
//Inicializamos el lcd
	lcd(8,9,4,5,6,7,0,0,0,0);
	lcd.begin(2,0);
	lcd.print("TempLogger");
	lcd.setCursor(0,1);
	lcd.print("10/3/2011");
	delay(3000);
	lcd.clear();
	lcd.print("Pulse el boton");
	lcd.setCursor(0,1);
	lcd.print("para empezar");
	INTCONbits.GIE=1; //Ahora iniciamos la interrupción
	while(empezar==0);
	lcd.clear();
	lcd.print("Comienzo");
	delay(1000);
//Preparamos el bus I2C
	init_I2C();
	for (i=0;i<8;i++) i2c_buffer[i]=0;

//Borramos la memoria
	lcd.clear();
	lcd.print("Borrando...");
	delay(500);
	for(j=0;j<200;j++)//Cambiar el valor de j para borrar más datos
//Los datos borrados son j*8 (Cuanto mayor sea j más tardará en borrar,
//por eso no he puesto j=2000 que es para borrar todos)
	{
		delay(3);
		a=BorrarMemoria8(posicion);
		posicion=posicion+8;
		lcd.setCursor(0,1);
		lcd.printNumber(posicion,DEC);
		
		if(a==0)
		{
			lcd.clear();
			lcd.print("Error borrando");
			lcd.setCursor(0,1);
			lcd.printNumber(posicion,DEC);
			while(1);
		}
	}
	
	lcd.clear();
	lcd.print("Grabando...");
	posicion=0;
	a=0;
	j=0;
	i=0;
	//Preparamos el timer1
	T1CONbits.T1CKPS1=1;
	T1CONbits.T1CKPS0=1;
	TMR1L=220;//4hz
	TMR1H=11;
	INTCONbits.GIE=1;
	INTCONbits.PEIE=1;
	T1CONbits.TMR1ON=1;
	PIE1bits.TMR1IE=1;
	PIR1bits.TMR1IF=0;
}


void loop()
{

	if(empezar==0)
	{

	}
	else
	{
		if(grabar==1)
		{
			sensado=analogRead(sensor);
			lectura[cuentamedia]=sensado;
			cuentamedia++;
			//Descomentar para ver cuentamedia:			
			//lcd.setCursor(11,0);
			//lcd.print("C:");
			//lcd.printNumber(cuentamedia,DEC);
			if(cuentamedia>3)
			{
				led^=1;
				cuentamedia=0;
				lecturamedia=0;
				for(j=0;j<4;j++)
				{
					lecturamedia=lecturamedia+lectura[j];
				}
				lecturamedia=lecturamedia/4;
				a=GrabarTemperatura1(posicion,lecturamedia);
				posicion++;
				posmax=posicion;
				if (a==1)
				{
					lcd.setCursor(0,1);
					lcd.print("Dato # ");
					lcd.printNumber(posicion,DEC);
					lcd.print(" V:");
					lcd.printNumber(lecturamedia,DEC);
					grabar=0;
				}
				else
				{
					lcd.clear();
					lcd.print("Error");
					grabar=0;
					delay(1000);
				}
			}
			else
			{
			grabar=0;
			}
		}
	}
}

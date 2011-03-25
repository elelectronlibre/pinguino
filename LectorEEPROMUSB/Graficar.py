#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Created on Sun Feb 27 10:38:51 2011

@author: daniel

El programa sirve para, dado un array con los valores leidos por el lm35,
convertirlos en temperatura, interpolarlos por un spline cubico y representarlos
graficamente.
"""
import numpy
import pylab
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
from scipy import interpolate
import os

directorio=os.getcwd()
print directorio
direccion=os.path.join(directorio,'Datos.txt')
datos = numpy.loadtxt(direccion)
temperatura=datos*500/1024
x = numpy.linspace(0, datos.size/60,temperatura.size)
interpolado = interpolate.splrep(x,temperatura,s=23)
print interpolado
ynew = interpolate.splev(x,interpolado,der=0)
t=datos.size/60
Tmax=numpy.amax(temperatura)

print datos

print temperatura
#pylab.plot(datos)
pylab.plot(x,temperatura)
pylab.plot(x,ynew)
plt.xlabel("horas")
plt.ylabel("Temperatura")
plt.title('Datos temperatura')
plt.axis([0,t,0,Tmax*1.1])
pylab.show()

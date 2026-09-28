package com.mycompany.concesionario;
import java.util.concurrent.Semaphore;

// Clase que representa a un cliente que quiere usar un coche
// Implementa Runnable para poder ejecutarse en un hilo
public class Cliente implements Runnable {

    String nombre;  // Nombre del cliente (Cliente1...Cliente9)
    Coche[] coches;  // Array de coches disponibles
    Semaphore semaforo;  // Semaforo para controlar cuantos coches se usan a la vez
    
    //Constructor
    public Cliente(String nombre, Coche[] coches, Semaphore semaforo){
    
        this.nombre=nombre;
        this.coches=coches;
        this.semaforo=semaforo;
    }
    
    @Override
    public void run() {      
        try {
            //Cada cliente probará los 4 coches
            for (int i = 0; i < coches.length; i++) {
            //Se solicita permiso al semaforo 
            //Si ya hay 4 coches ocupados, el cliente espera aquí
            semaforo.acquire();            
            Coche cocheAsignado = null;       
            //Buscamos un coche libre
            synchronized (coches) {
                for (Coche c : coches) {
                    if (!c.ocupado){ //Si el coche esta libre
                        c.ocupado = true; //Lo marcamos como ocupado
                        cocheAsignado = c; //Lo asignamos a este cliente
                        break;
                    }  } }
            //Mensaje que indica que cliente esta usando un coche concreto
            System.out.println(nombre + " probando " + cocheAsignado.nombre);
            
            //Simulamos el tiempo que el cliente esta usando el coche
            Thread.sleep(2000);
            
            //Mensaje que indica que el cliente ha terminado de probar el coche
            System.out.println(nombre + " termino de probar el " + cocheAsignado.nombre);
            
            //Hay que devolver el coche
            synchronized (coches) {
                cocheAsignado.ocupado = false; //Marcamos el coche como libre 
            }
            //Liberamos el permiso en el semaforo
            semaforo.release();      
            
            //Pequeño descanso antes de probar el siguiente coche
            Thread.sleep(500);
            }
            //Aqui la excepcion por si falla
        } catch (InterruptedException e){
                e.printStackTrace();
        }
    }    
}

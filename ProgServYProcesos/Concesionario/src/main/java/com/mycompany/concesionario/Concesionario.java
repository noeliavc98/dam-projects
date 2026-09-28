package com.mycompany.concesionario;
import java.util.concurrent.Semaphore;

public class Concesionario {

    public static void main(String[] args) {
    
        //Creamos 4 coches con su nombre (Coche1...Coche4)
       Coche[] coches = {
           new Coche("Coche1"),
           new Coche("Coche2"),
           new Coche("Coche3"),
           new Coche("Coche4"),};
       
       //Creamos un semaforo con 4 permisos (porque solo hay 4 coches)
       Semaphore semaforo = new Semaphore(4);
       
       //Creamos 9 clientes y lanzamos un hilo para cada uno
       for (int i = 1; i <= 9; i++) {
           Cliente cliente = new Cliente("Cliente" + i, coches, semaforo);
           //Creamos el hilo pasando el Runnable y lo iniciamos
           new Thread(cliente).start();
       
       }
       
       }
    }


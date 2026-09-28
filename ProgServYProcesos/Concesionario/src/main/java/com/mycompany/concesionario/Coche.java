package com.mycompany.concesionario;
 //Creamos la clase Coche       
public class Coche{

    //Le damos atributos
    String nombre;    //Nombre del coche (Coche1, Coche2...)
    boolean ocupado=false;   //Indica si el coche esta ocupado
    
    
    //Constructor
    public Coche(String nombre) {
        this.nombre=nombre;
    }
    
}

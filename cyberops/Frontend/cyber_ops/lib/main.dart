// Importamos el paquete principal de Flutter para poder crear interfaces visuales
import 'package:flutter/material.dart';

// Importamos el paquete de Firebase Core
// Es obligatorio importarlo antes de usar cualquier servicio de Firebase
import 'package:firebase_core/firebase_core.dart';

// Importamos el archivo generado automáticamente por FlutterFire
// Contiene la configuración de Firebase para cada plataforma (Android, iOS, Web, etc.)
// IMPORTANTE: no modificar este archivo manualmente
import 'firebase_options.dart';
import 'screens/menu_screen.dart';
import 'config/app_routes.dart';

// Importamos la pantalla principal del juego

import 'screens/splash_screen.dart';
import 'services/music_service.dart';
// Importamos la login screen del juego

// main() es el punto de entrada de toda aplicación Flutter
// Es lo primero que se ejecuta cuando se abre la app
// async significa que puede esperar operaciones que tardan tiempo (como iniciar Firebase)
void main() async {
  // Garantiza que Flutter esté completamente inicializado antes de hacer nada más
  // Es obligatorio llamarlo antes de await en main()
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos Firebase antes de arrancar la app
  // await significa que esperamos a que Firebase esté listo antes de continuar
  // Si no esperamos, la app intentaría usar Firebase antes de que esté preparado y daría error
  await Firebase.initializeApp(
    // DefaultFirebaseOptions.currentPlatform detecta automáticamente en qué plataforma
    // está corriendo la app (Android, iOS, Web, etc.) y usa la configuración correcta
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await MusicService().loadSettings();

  // runApp() arranca la aplicación Flutter y muestra el widget raíz
  // const significa que MyApp no cambia nunca, lo que mejora el rendimiento
  runApp(const MyApp());
}

// MyApp es el widget raíz de toda la aplicación
// StatelessWidget significa que no tiene estado propio (no cambia con el tiempo)
class MyApp extends StatelessWidget {
  // Constructor de la clase
  const MyApp({super.key});

  // build() define la estructura visual de la app
  @override
  Widget build(BuildContext context) {
    // MaterialApp es el widget base de cualquier app Flutter
    // Configura el tema, las rutas de navegación, el título, etc.
    return MaterialApp(
      // Título de la app (aparece en el gestor de tareas del móvil)
      title: 'Cyber Ops',

      // debugShowCheckedModeBanner: false oculta el banner rojo de "DEBUG"
      // que aparece en la esquina superior derecha durante el desarrollo
      debugShowCheckedModeBanner: false,
      navigatorObservers: [appRouteObserver],

      // theme define el aspecto visual global de la app
      // Aquí podemos configurar colores, fuentes y estilos por defecto
      theme: ThemeData(
        // colorScheme genera una paleta de colores basada en un color semilla
        // seedColor es el color base a partir del cual Flutter genera los demás colores
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // useMaterial3: true activa el diseño Material 3 (la versión más moderna de Google)
        useMaterial3: true,
      ),

      // la pantalla de carga es la primera pantalla que ve el usuario al abrir la app
      // Le decimos que muestre HomeScreen (nuestra pantalla principal)
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.menu) {
          return AppRoutes.fade(const MenuScreen(), settings: settings);
        }
        return null;
      },
    );
  }
}

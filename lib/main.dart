import 'dart:math';
import 'package:flutter/material.dart';
import 'screens/join_screen.dart';
import 'services/signalling.service.dart';
void main() {

  // Commence un appel vidéo
  runApp(VideoCallApp());
}
class VideoCallApp extends StatelessWidget {
  VideoCallApp({super.key});
  
  // Précise l'url de notre serveur pour le web socker
  final String websocketUrl = "http://localhost:3000";
  
  // Génère un ID unique pour l'user locale
  final String selfCallerID =
      Random().nextInt(999999).toString().padLeft(6, '0');
  @override
  Widget build(BuildContext context) {
    
    // Initialise l'instance d'appel aved l'ID de l'appellant et de l'appelé 
    SignallingService.instance.init(
      websocketUrl: websocketUrl,
      selfCallerID: selfCallerID,
    );

    // Retourne le rendu de l'appli (graphique) 
    return MaterialApp(
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      ),
      themeMode: ThemeMode.dark,
      home: JoinScreen(selfCallerId: selfCallerID),
    );
  }
}
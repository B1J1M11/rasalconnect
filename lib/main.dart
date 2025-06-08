import 'dart:math';
import 'package:flutter/material.dart';
import 'screens/join_screen.dart';
import 'services/signalling.service.dart';

void main() {
  // start l'appli
  runApp(MessagingApp());
}

class MessagingApp extends StatelessWidget {
  MessagingApp({super.key});

  // web socket
  final String websocketUrl = "http://localhost:3000"; 

  // Génère un ID unique pour l'user locale
  final String selfCallerID =
      Random().nextInt(999999).toString().padLeft(6, '0');

  @override
  Widget build(BuildContext context) {
    // Initialise l'instance de signalisation
    SignallingService.instance.init(
      websocketUrl: websocketUrl,
      selfCallerID: selfCallerID,
    );

    // Retourne le rendu de l'appli 
    return MaterialApp(
      title: 'RasalConnect',
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      ),
      themeMode: ThemeMode.dark,
      home: JoinScreen(selfCallerId: selfCallerID),
    );
  }
}
// Permet de log
import 'dart:developer';

// Permet de créer le socket pour se connecter au serveur 
import 'package:socket_io_client/socket_io_client.dart';

// Créer une classe pour créer les sockets
class SignallingService {
  
  // Déclare un nouveau socket
  Socket? socket;
  
  // Empèche de créer de nouveau socket ailleurs que dans cette classe
  SignallingService._();
  
  // Créer une instance
  static final instance = SignallingService._();
  
  // Initialise le serveur websocket avec l'url et l'ID de l'appelant
  init({required String websocketUrl, required String selfCallerID}) {
    
    
    // Créer la connexion
    socket = io(websocketUrl, {
      
      // Définit le WebSocket à utiliser
      "transports": ['websocket'],

      // Renseigne call user essaie de se connecter
      "query": {"callerId": selfCallerID}
    });


    // Connexion
    socket!.onConnect((data) {
      log("Connexion établie !");
    });


    // Gestion des erreurs
    socket!.onConnectError((data) {
      log("Connection non établie... $data");
    });
    // connect socket
    socket!.connect();
  }
}
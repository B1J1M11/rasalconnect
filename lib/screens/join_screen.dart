
import 'package:flutter/material.dart';
import 'call_screen.dart';  
import '../services/signalling.service.dart';

// Rejoindre un appel
class JoinScreen extends StatefulWidget {
  
  // Créer un ID pour l'utilisateur qui appelle
  final String selfCallerId;

  // Créer un constructeur du JoinScreen avec en paramêtre l'ID de l'appelant
  const JoinScreen({super.key, required this.selfCallerId});
  @override

  // Créer l'état du widget pour rejoindre l'appel (graphiquement)
  State<JoinScreen> createState() => _JoinScreenState();
}

// Gestion de l'interface utilisateur
class _JoinScreenState extends State<JoinScreen> {
  
  // Stock le SDP de l'appel entrant
  dynamic incomingSDPOffer;
  
  // Affiche le nom de l'utilisateur qui appel via son ID
  final remoteCallerIdTextEditingController = TextEditingController();
  @override

  // Initialise le widget
  void initState() {
    super.initState();
    
    // Attend les appel entrant 
    SignallingService.instance.socket!.on("Appel entrant !", (data) {
      
      // Si l'écran est toujours monté
      if (mounted) {

        // On stock l'appel via le SDP
        setState(() => incomingSDPOffer = data);
      }
    });
  }


  // Rejoindre un appel
  _joinCall({

    // L'ID de l'appelant et de l'appelé est requis
    required String callerId,
    required String calleeId,

    // Utilise SDP pour la connexion
    dynamic offer,
  }) {
    
    // Navigue vers un autre écran
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callerId: callerId,
          calleeId: calleeId,
          offer: offer,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fond d'écran
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,

        // Titre de l'appli
        title: const Text("RASALCONNECT"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(

                // Taille d'écran responsive
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(

                  // Cenre les éléments
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: TextEditingController(

                        // Affiche l'ID de l'appelant
                        text: widget.selfCallerId,
                      ),
                      readOnly: true,
                      textAlign: TextAlign.center,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(

                        // L'ID d'utilisateur
                        labelText: "ID APPELANT",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remoteCallerIdTextEditingController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: "IP DESTINATAIRE",
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                      ),
                      child: const Text(
                        "Invite",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        _joinCall(
                          callerId: widget.selfCallerId,
                          calleeId: remoteCallerIdTextEditingController.text,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Si il y a un appel entrant
            if (incomingSDPOffer != null)
              Positioned(
                child: ListTile(
                  title: Text(
                    "Appel de ${incomingSDPOffer["callerId"]}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call_end),
                        color: Colors.redAccent,
                        onPressed: () {
                          setState(() => incomingSDPOffer = null);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.call),
                        color: Colors.greenAccent,
                        onPressed: () {
                          _joinCall(
                            callerId: incomingSDPOffer["callerId"]!,
                            calleeId: widget.selfCallerId,
                            offer: incomingSDPOffer["sdpOffer"],
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'chat_screen.dart';    
import '../services/signalling.service.dart';

// Ceci est un saut de ligne

// Rejoindre une conversation
class JoinScreen extends StatefulWidget {
  final String selfCallerId;
  const JoinScreen({super.key, required this.selfCallerId});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  dynamic incomingSDPOffer;
  final remoteCallerIdTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Écoute pour les demandes de chat entrantes
    // L'événement "Appel entrant !" est conservé du côté serveur,
    SignallingService.instance.socket!.on("Appel entrant !", (data) {
      if (mounted) {
        // data contient { sdpOffer: ..., callerId: ... }
        setState(() => incomingSDPOffer = data);
      }
    });
  }

  _startOrAcceptChat({
    required String callerId, // Celui qui initie ou à qui on répond
    required String calleeId, // Celui à qui on envoie l'offre ou notre ID si on accepte
    dynamic offer,           // L'offre SDP si on accepte un chat
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen( // Lancement de ChatScreen
          callerId: callerId,    // Si on initie: notre ID. Si on accepte: ID de l'autre.
          calleeId: calleeId,    // Si on initie: ID de l'autre. Si on accepte: notre ID.
          offer: offer,          // L'offre si on accepte, null si on initie.
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("RASALCONNECT"),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: TextEditingController(
                        text: widget.selfCallerId,
                      ),
                      readOnly: true,
                      textAlign: TextAlign.center,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: "MON ID", // Texte mis à jour
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
                        hintText: "ID DU DESTINATAIRE", // Texte mis à jour
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
                        "Démarrer le Chat", // Texte mis à jour
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        if (remoteCallerIdTextEditingController.text.isNotEmpty) {
                           _startOrAcceptChat(
                            callerId: widget.selfCallerId, // Moi, l'initiateur
                            calleeId: remoteCallerIdTextEditingController.text, // Le destinataire
                            // pas d'offre ici, car on initie
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Veuillez entrer l'ID du destinataire."))
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Demande de chat entrante
            if (incomingSDPOffer != null)
              Positioned(
                bottom: 50, // Ajusté pour une meilleure visibilité
                left: 20,
                right: 20,
                child: Card( // Utilisation d'une Card pour une meilleure présentation
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: ListTile(
                    title: Text(
                      "Demande de chat de : ${incomingSDPOffer!["callerId"] ?? "inconnu"}",
                    ),
                    subtitle: const Text("Accepter le chat ?"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close), // Changé pour "close"
                          color: Colors.redAccent,
                          tooltip: "Refuser",
                          onPressed: () {
                            // On pourrait envoyer un message "refusé" au serveur ici
                            setState(() => incomingSDPOffer = null);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble), // Changé pour "chat"
                          color: Colors.greenAccent,
                          tooltip: "Accepter",
                          onPressed: () {
                            final String incomingCallerId = incomingSDPOffer!["callerId"];
                            final dynamic sdpOffer = incomingSDPOffer!["sdpOffer"];
                            
                            // Accepter le chat
                            _startOrAcceptChat(
                              callerId: incomingCallerId, // L'ID de celui qui a envoyé l'offre
                              calleeId: widget.selfCallerId, // Mon ID, je suis le destinataire
                              offer: sdpOffer, // L'offre SDP reçue
                            );
                            // Masquer la notification après avoir traité
                            setState(() => incomingSDPOffer = null);
                          },
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
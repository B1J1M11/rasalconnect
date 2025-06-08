import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signalling.service.dart'; 

class ChatScreen extends StatefulWidget {
  final String callerId; // ID de celui qui initie l'offre OU celui qui a initié l'offre (si on est l'appelé)
  final String calleeId; // ID de celui qui reçoit l'offre OU notre propre ID (si on est l'appelé)
  final dynamic offer;   // L'offre SDP si on est l'appelé

  const ChatScreen({
    super.key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final socket = SignallingService.instance.socket;
  RTCPeerConnection? _rtcPeerConnection;
  RTCDataChannel? _dataChannel;
  final List<String> _messages = [];
  final _messageController = TextEditingController();

  // Liste les candidats ICE à envoyer (principalement pour l'appelant)
  final List<RTCIceCandidate> _rtcIceCandidates = [];

  late String _otherUserId; // ID de l'interlocuteur

  @override
  void initState() {
    super.initState();

    _otherUserId = (widget.offer == null) ? widget.calleeId : widget.callerId;

    _setupPeerConnection();
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
 // prépare la connexion server du P2P
  Future<void> _setupPeerConnection() async {
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });

    // Gestion des événements ICE
    _rtcPeerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (widget.offer == null) { 
        
        // Stocker les candidats pour les envoyer après avoir reçu la réponse
        _rtcIceCandidates.add(candidate);
      } else {

        // Envoie les candidats ICE à l'initiateur de l'offre (widget.callerId)
        socket!.emit("IceCandidate", {
          "calleeId": widget.callerId, // L'initiateur de l'offre originale
          "iceCandidate": {
            "id": candidate.sdpMid,
            "label": candidate.sdpMLineIndex,
            "candidate": candidate.candidate,
          }
        });
      }
    };

    // Écoute pour les data channels distants (pertinent pour l'appelé)
    _rtcPeerConnection!.onDataChannel = (RTCDataChannel channel) {
      _dataChannel = channel;
      _setupDataChannelEvents();
    };

    // Si on reçoit une offre 
    if (widget.offer != null) {
      // Écoute pour les candidats ICE envoyés par l'appelant (initiateur de l'offre)
      socket!.on("IceCandidate", (data) {
        if (data["iceCandidate"] != null) {
          String candidate = data["iceCandidate"]["candidate"];
          String sdpMid = data["iceCandidate"]["id"];
          int sdpMLineIndex = data["iceCandidate"]["label"];
          _rtcPeerConnection!.addCandidate(RTCIceCandidate(
            candidate,
            sdpMid,
            sdpMLineIndex,
          ));
        }
      });

      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(widget.offer!["sdp"], widget.offer!["type"]),
      );

      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();
      await _rtcPeerConnection!.setLocalDescription(answer);

      socket!.emit("answerCall", {
        "callerId": widget.callerId, // ID de celui qui a initié l'offre
        "sdpAnswer": answer.toMap(),
      });
    }
    // Cas: Appel sortant (on initie l'offre)
    else {
      // Créer le DataChannel AVANT de créer l'offre
      _dataChannel = await _rtcPeerConnection!.createDataChannel(
        "chatmessaging", // Label du DataChannel
        RTCDataChannelInit()
          ..ordered = true
          ..maxRetransmits = 30,
      );
      _setupDataChannelEvents(); 

      // Écoute de la réponse à notre offre
      socket!.on("callAnswered", (data) async {
        if (data["sdpAnswer"] != null) {
          await _rtcPeerConnection!.setRemoteDescription(
            RTCSessionDescription(
              data["sdpAnswer"]["sdp"],
              data["sdpAnswer"]["type"],
            ),
          );

          // Envoie les candidats ICE stockés au destinataire de l'offre (widget.calleeId)
          for (RTCIceCandidate candidate in _rtcIceCandidates) {
            socket!.emit("IceCandidate", {
              "calleeId": widget.calleeId,
              "iceCandidate": {
                "id": candidate.sdpMid,
                "label": candidate.sdpMLineIndex,
                "candidate": candidate.candidate,
              }
            });
          }
          _rtcIceCandidates.clear();
        }
      });

      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();
      await _rtcPeerConnection!.setLocalDescription(offer);

      socket!.emit('offer', {
        "calleeId": widget.calleeId,
        "sdpOffer": offer.toMap(),
        "callerId": widget.callerId,
      });
    }
  }

  void _setupDataChannelEvents() {
    _dataChannel?.onDataChannelState = (RTCDataChannelState state) {
      print("DataChannel state avec $_otherUserId: $state");
      if (mounted) {
        switch (state) {
          case RTCDataChannelState.RTCDataChannelOpen:
            setState(() {
              _messages.add("Connecté à $_otherUserId");
            });
            break;
          case RTCDataChannelState.RTCDataChannelClosed:
            setState(() {
              _messages.add("Déconnexion de $_otherUserId.");
            });
            break;
          case RTCDataChannelState.RTCDataChannelConnecting:
            print("DataChannel avec $_otherUserId en connexion...");
            break;
          case RTCDataChannelState.RTCDataChannelClosing:
            print("DataChannel avec $_otherUserId en fermeture...");
            break;
        }
      }
    };

    _dataChannel?.onMessage = (RTCDataChannelMessage message) {
      if (mounted) {
        setState(() {
          _messages.add("$_otherUserId: ${message.text}");
        });
      }
    };
  }

  void _sendMessage() {
    String text = _messageController.text.trim();
    if (text.isNotEmpty && _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(RTCDataChannelMessage(text));
      setState(() {
        _messages.add("Moi: $text");
      });
      _messageController.clear();
    }
  }

  void _leaveChat() {
    // je le ferai quand l'échange de message sera validé
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat avec $_otherUserId"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _leaveChat,
            tooltip: "Quitter le chat",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                reverse: false, // Pour que les nouveaux messages soient en bas, si préféré
                               // true si on veut afficher les messages du bas vers le haut
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isMyMessage = message.startsWith("Moi:");
                  return Align(
                    alignment: isMyMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      decoration: BoxDecoration(
                        color: isMyMessage
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                            : Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(message),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Écrire un message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _dataChannel?.close();
    _rtcPeerConnection?.close();
    _rtcPeerConnection = null; 
    _dataChannel = null;       

    // Retirer les listeners spécifiques à cette instance de chat
    socket?.off("IceCandidate");
    socket?.off("callAnswered");
    super.dispose();
  }
}
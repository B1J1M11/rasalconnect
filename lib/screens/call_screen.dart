import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signalling.service.dart';
class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;
  const CallScreen({
    super.key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  });
  @override
  State<CallScreen> createState() => _CallScreenState();
}

// Widget de l'écran d'appel 
class _CallScreenState extends State<CallScreen> {
  //  Récupère le socket à partir de SIgnallingService 
  final socket = SignallingService.instance.socket;

  // Rendu vidéo pour l'user appelant
  final _localRTCVideoRenderer = RTCVideoRenderer();
  
  // Rendu vidéo pour l'user distant
  final _remoteRTCVideoRenderer = RTCVideoRenderer();
  
  // Flux média
  MediaStream? _localStream;
  
  // COnnexion WebRTC entre les deux hôtes
  RTCPeerConnection? _rtcPeerConnection;

  // Liste les candidats ICE à envoyer
  List<RTCIceCandidate> rtcIceCadidates = [];

  // Bouléen pour vérifier l'activation du micro et des caméras
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;
  
  @override
  void initState() {
    // Initialisation des rendus vidéo
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    // Mise en place de la connexion WebRTC
    _setupPeerConnection();
    super.initState();
  }

  // Vérifie si le widget est bien monté (grrr)
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  // Configure la connexion P2P
  _setupPeerConnection() async {
    
    // Créer la connexion
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


    // Réception du flux média distant
    _rtcPeerConnection!.onTrack = (event) {
      _remoteRTCVideoRenderer.srcObject = event.streams[0];
      setState(() {});
    };
    
    // Récupère le flux du média local (hôte)
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });


    // Ajout des pistes audio et vidéo locale à la connexion
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // Ajoute le flux au rendu local
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // Pour les appels entrants
    if (widget.offer != null) {

      // On écoute les ICE envoyé par le pair distant
      socket!.on("IceCandidate", (data) {
        String candidate = data["iceCandidate"]["candidate"];
        String sdpMid = data["iceCandidate"]["id"];
        int sdpMLineIndex = data["iceCandidate"]["label"];
        
        // Ajoute les ICE
        _rtcPeerConnection!.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      });
      
      // Utilisation de l'offre SDP comme description
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
      );

      // Créer la réponse SDP 
      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();
      
      // Enregistrement de la réponse comme description locale
      _rtcPeerConnection!.setLocalDescription(answer);

      // Envoi la réponse SDP à l'appelant via le serveur
      socket!.emit("answerCall", {
        "callerId": widget.callerId,
        "sdpAnswer": answer.toMap(),
      });
    }
    // Sinon, pour un appel sortant
    else {
      // Récupère les candidats ICE générés localement
      _rtcPeerConnection!.onIceCandidate =
          (RTCIceCandidate candidate) => rtcIceCadidates.add(candidate);
        
      // Quand l'appel est accepté pour le pair distant 
      socket!.on("callAnswered", (data) async {
        
        // Ajout de la description avec la réponse SDP
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            data["sdpAnswer"]["sdp"],
            data["sdpAnswer"]["type"],
          ),
        );
        // Envoi des candidats ICE locaux au pair distant
        for (RTCIceCandidate candidate in rtcIceCadidates) {
          socket!.emit("IceCandidate", {
            "calleeId": widget.calleeId,
            "iceCandidate": {
              "id": candidate.sdpMid,
              "label": candidate.sdpMLineIndex,
              "candidate": candidate.candidate
            }
          });
        }
      });

      // Création d'une offre SDP pour initier l'appel
      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();

      // Enregistrement de l'offre comme desciption 
      await _rtcPeerConnection!.setLocalDescription(offer);

      // Envoie de l'offre SDP au pair distant 
      socket!.emit('makeCall', {
        "calleeId": widget.calleeId,
        "sdpOffer": offer.toMap(),
      });
    }
  }

  // Fonction pour quitter l'appel
  _leaveCall() {
    Navigator.pop(context);
  }

  // Fonction pour désactiver ou activer le micro
  _toggleMic() {
    
    // Change le statut du micro
    isAudioOn = !isAudioOn;

    // Active / Désactive le micro
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  // Fonction pour désactiver ou activer la caméra
  _toggleCamera() {

    // Change le statut de la caméra
    isVideoOn = !isVideoOn;

    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  // Fonction pour basculer de caméra
  _switchCamera() {

    // Change le statu de la caméra
    isFrontCameraSelected = !isFrontCameraSelected;

    // Switch de caméra (avant / arière)
    _localStream?.getVideoTracks().forEach((track) {
      
      // ignore: deprecated_member_use
      track.switchCamera();
    });
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text("RASALCONNECT"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(children: [
                RTCVideoView(
                  _remoteRTCVideoRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                
                // Vidéo locale (notre petite vignette)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: SizedBox(
                    height: 150,
                    width: 120,
                    child: RTCVideoView(
                      _localRTCVideoRenderer,
                      mirror: isFrontCameraSelected,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                )
              ]),
            ),
            
            // Contrôle d'appel (micro, raccorcher, caméra, etc)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_end),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.cameraswitch),
                    onPressed: _switchCamera,
                  ),
                  IconButton(
                    icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Libération des ressources lors de la desctruction du widget (BOUM)
  @override
  void dispose() {
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }
}
// server.js en local
const io = require("socket.io")(3000, {
  cors: {
    origin: "*",
  },
});

// Connexion
io.on("connection", (socket) => {
  const callerId = socket.handshake.query.callerId;
  console.log("Connexion de :", callerId);
  socket.join(callerId); // Associe l'ID au socket

  // Gestion de l'offre (Appel sortant)
  socket.on("offer", (data) => {
    // Envoie ciblé à l'utilisateur à qui l'appel est destiné
    io.to(data.calleeId).emit("Appel entrant !", data);
    console.log("Offre reçue et envoyée à", data.calleeId);
  });

  // Gestion de la réponse (Réponse à l'appel)
  socket.on("answerCall", (data) => {
    // Envoie la réponse au destinataire de l'appel
    io.to(data.calleeId).emit("answer", {
      callerId: data.callerId,
      sdpAnswer: data.sdpAnswer,
    });
    console.log("Réponse envoyée pour l'appel de", data.callerId);
  });

  // Gestion des candidats ICE
  socket.on("IceCandidate", (data) => {
    // Envoie le candidat ICE à l'autre pair (calleeId ou callerId)
    io.to(data.calleeId).emit("IceCandidate", {
      iceCandidate: data.iceCandidate,
    });
    console.log("Candidat ICE envoyé à", data.calleeId);
  });

  // Déconnexion de l'utilisateur
  socket.on("disconnect", () => {
    console.log("Un client s'est déconnecté :", socket.id);
  });
});

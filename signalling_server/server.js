// server.js en locale
const io = require("socket.io")(3000, {
  cors: {
    origin: "*",
  }
});

// Connexion
io.on("connection", (socket) => {
  console.log("Un client est connecté :", socket.id);

// Offre
  socket.on("offer", (data) => {
    socket.broadcast.emit("offer", data);
    console.log("Offer reçue :", data);
    socket.broadcast.emit("offer", data);
  });

 // Réponse
  socket.on("answer", (data) => {
    socket.broadcast.emit("answer", data);
  });

  // Candidat
  socket.on("candidate", (data) => {
    socket.broadcast.emit("candidate", data);
  });

  // Déconnexion
  socket.on("disconnect", () => {
    console.log("Un client s'est déconnecté :", socket.id);
  });
});
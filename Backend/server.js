import express from "express";
import cors from "cors";
import path from "path";                
import { fileURLToPath } from "url";    
import { MEDIA_ROOT } from "./config/media.config.js";
import libraryRoutes from "./routes/library.routes.js";
import { startMDNS } from "./services/mdn.js";
import { startAutoRescan } from "./services/scanner.service.js";

const PORT=8080
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

app.use(cors());
app.use(express.json());

app.get("/ping", (req, res) => {
  res.json({ status: "ok", name: "LANPlay Server" });
});

app.use("/library", libraryRoutes);



// Serve thumbnails
app.use(
  "/thumbnails",
  express.static(path.join(MEDIA_ROOT, "thumbnails"), {
    index: false,
    fallthrough: false
  })
);

app.use(
  "/series",
  express.static(path.join(MEDIA_ROOT, "series"))
);

// (optional but recommended)
app.use(
  "/movies",
  express.static(path.join(MEDIA_ROOT, "movies"))
);

app.use(
  "/musics",
  express.static(path.join(MEDIA_ROOT, "music"))
);
app.use(
  "/static",
  express.static(path.join(__dirname, "static"))
);

app.listen(PORT, "0.0.0.0", () => {
  console.log(`📺 Media server running on port ${PORT}`);
  startMDNS(PORT)
});

startAutoRescan(600_000)


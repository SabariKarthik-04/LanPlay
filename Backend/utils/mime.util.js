import path from "path";

export function getMime(filePath) {
  const ext = path.extname(filePath).toLowerCase();

  switch (ext) {
    case ".mp4":
      return "video/mp4";
    case ".mkv":
      return "video/x-matroska";
    case ".mp3":
      return "audio/mpeg";
    default:
      return "application/octet-stream";
  }
}

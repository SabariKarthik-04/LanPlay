import "dotenv/config";

export const MEDIA_ROOT = process.env.MEDIA_ROOT;
export const PORT = process.env.PORT || 8080;

export const SUPPORTED_EXT = [
  ".mp4",
  ".mkv",
  ".avi",
  ".mp3"
];

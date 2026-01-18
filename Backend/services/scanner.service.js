import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { exec } from "child_process";
import { promisify } from "util";
import { MEDIA_ROOT, SUPPORTED_EXT } from "../config/media.config.js";

const execAsync = promisify(exec);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let isScanning = false;

/* -------------------------------
   Files
-------------------------------- */
const CACHE_FILE = path.join(__dirname, "../cache/library.json");
const DATA_FILE  = path.join(__dirname, "../data/data.json");
const THUMBNAILS_DIR = path.join(MEDIA_ROOT, "thumbnails");

/* -------------------------------
   Extensions
-------------------------------- */
const VIDEO_EXT = [".mp4", ".mkv", ".avi", ".mov", ".webm", ".flv"];

/* -------------------------------
   Ensure directories
-------------------------------- */
fs.mkdirSync(THUMBNAILS_DIR, { recursive: true });
fs.mkdirSync(path.dirname(DATA_FILE), { recursive: true });

/* ===============================
   Thumbnail helpers
================================ */
function getThumbnailName(fileName) {
  return `${path.parse(fileName).name}.jpg`;
}

function getThumbnailPath(fileName) {
  return path.join(THUMBNAILS_DIR, getThumbnailName(fileName));
}

async function generateThumbnail(videoPath, fileName) {
  const thumbnailPath = getThumbnailPath(fileName);

  if (fs.existsSync(thumbnailPath)) return thumbnailPath;

  try {
    await execAsync(
      `ffmpeg -y -ss 00:01:00 -i "${videoPath}" -vf "scale=854:-1" -frames:v 1 "${thumbnailPath}"`
    );
    return thumbnailPath;
  } catch (err) {
    console.error("❌ Thumbnail failed:", fileName);
    return null;
  }
}

/* ===============================
   Cleanup orphan thumbnails
================================ */
function cleanupThumbnails(validFiles) {
  const existing = fs.readdirSync(THUMBNAILS_DIR);

  for (const thumb of existing) {
    const base = path.parse(thumb).name;
    if (!validFiles.has(base)) {
      fs.unlinkSync(path.join(THUMBNAILS_DIR, thumb));
      console.log("🗑️ Removed orphan thumbnail:", thumb);
    }
  }
}

/* ===============================
   Scan directory
================================ */
async function scanDir(dirPath, allowThumbnails = false) {
  const entries = fs.readdirSync(dirPath);

  const cacheList = [];
  const dataList = [];
  const validThumbs = new Set();

  for (const file of entries) {
    const ext = path.extname(file).toLowerCase();
    if (!SUPPORTED_EXT.includes(ext)) continue;

    const filePath = path.join(dirPath, file);
    const isVideo = VIDEO_EXT.includes(ext);

    let thumbnailUrl = null;
    let thumbnailPath = null;

    if (allowThumbnails && isVideo) {
      thumbnailPath = await generateThumbnail(filePath, file);
      if (thumbnailPath) {
        thumbnailUrl = `/thumbnails/${path.basename(thumbnailPath)}`;
        validThumbs.add(path.parse(file).name);
      }
    }

    cacheList.push({
      name: file,
      ext,
      thumbnail: thumbnailUrl
    });

    dataList.push({
      name: file,
      ext,
      filePath,
      thumbnail: thumbnailUrl,
      thumbnailPath
    });
  }

  return { cacheList, dataList, validThumbs };
}

/* ===============================
   Full library scan
================================ */
async function scanLibrary() {
  console.log("🔍 Scanning media library...");

  const cache = { movies: [], music: [], series: {} };
  const data  = { movies: [], music: [], series: {} };

  const globalValidThumbs = new Set();

  /* 🎬 Movies */
  const moviesPath = path.join(MEDIA_ROOT, "Movies");
  if (fs.existsSync(moviesPath)) {
    const result = await scanDir(moviesPath, true);
    cache.movies = result.cacheList;
    data.movies  = result.dataList;
    result.validThumbs.forEach(v => globalValidThumbs.add(v));
  }

  /* 🎵 Music (NO thumbnails) */
  const musicPath = path.join(MEDIA_ROOT, "Music");
  if (fs.existsSync(musicPath)) {
    const result = await scanDir(musicPath, false);
    cache.music = result.cacheList;
    data.music  = result.dataList;
  }

  /* 📺 Series */
  const seriesPath = path.join(MEDIA_ROOT, "Series");
  if (fs.existsSync(seriesPath)) {
    const shows = fs.readdirSync(seriesPath, { withFileTypes: true });

    for (const show of shows) {
      if (!show.isDirectory()) continue;

      const showPath = path.join(seriesPath, show.name);
      const result = await scanDir(showPath, true);

      cache.series[show.name] = result.cacheList;
      data.series[show.name]  = result.dataList;

      result.validThumbs.forEach(v => globalValidThumbs.add(v));
    }
  }

  cleanupThumbnails(globalValidThumbs);

  fs.writeFileSync(CACHE_FILE, JSON.stringify(cache, null, 2));
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));

  console.log("✅ Library scan complete");
  return cache;
}

/* ===============================
   Public API
================================ */
function getLibrary() {
  if (fs.existsSync(CACHE_FILE)) {
    return JSON.parse(fs.readFileSync(CACHE_FILE, "utf-8"));
  }
  return scanLibrary();
}

async function rescanLibrary() {
  return scanLibrary();
}

function getInternalData() {
  if (!fs.existsSync(DATA_FILE)) return null;
  return JSON.parse(fs.readFileSync(DATA_FILE, "utf-8"));
}

function startAutoRescan(intervalMs = 600_000) {
  const runScan = async () => {
    if (isScanning) return;
    try {
      isScanning = true;
      console.log("🔁 Auto rescan started");
      await rescanLibrary();
    } catch (err) {
      console.error("❌ Auto rescan failed:", err.message);
    } finally {
      isScanning = false;
    }
  };
  runScan();
  setInterval(runScan, intervalMs);
}

export {
  getLibrary,
  rescanLibrary,
  getInternalData,
  startAutoRescan
};

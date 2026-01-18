import express from "express";
import {
  getLibrary,
  rescanLibrary
} from "../services/scanner.service.js";

const router = express.Router();

router.get("/", (req, res) => {
  const library = getLibrary();
  res.json(library);
});

router.get("/rescan", (req, res) => {
  const library = rescanLibrary();
  res.json(library);
});

export default router;

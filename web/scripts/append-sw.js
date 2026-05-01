// Postbuild script: append custom SW code to the generated sw.js
const fs = require("fs");
const path = require("path");

const swPath = path.join(__dirname, "..", "public", "sw.js");
const customSwPath = path.join(__dirname, "..", "public", "sw-custom.js");

if (!fs.existsSync(swPath)) {
  console.error("sw.js not found at", swPath);
  process.exit(1);
}

if (!fs.existsSync(customSwPath)) {
  console.log("No sw-custom.js found, skipping append.");
  process.exit(0);
}

const customCode = fs.readFileSync(customSwPath, "utf8");
const swContent = fs.readFileSync(swPath, "utf8");

// Only append if not already appended
if (!swContent.includes("// Custom service worker additions for WoofTalk")) {
  fs.appendFileSync(swPath, "\n\n" + customCode);
  console.log("Custom SW code appended to sw.js");
} else {
  console.log("Custom SW code already present in sw.js");
}

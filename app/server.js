// CloudCart API - tiny HTTP service used in every lab
const http = require("http");
const os = require("os");
const fs = require("fs");

const PORT = process.env.PORT || 8080;
const VERSION = process.env.APP_VERSION || "1.0";
const TITLE = process.env.TITLE || "CloudCart API";
const SECRETS_DIR = process.env.SECRETS_DIR || "/mnt/secrets";
const DATA_DIR = process.env.DATA_DIR || "/data";
let ready = false;

function send(res, code, body) {
  res.writeHead(code, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body, null, 2) + "\n");
}

function listSecrets() {
  try {
    return fs.readdirSync(SECRETS_DIR);
  } catch {
    return [];
  }
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, "http://localhost");
  switch (url.pathname) {
    case "/healthz":
      return send(res, 200, { status: "ok" });
    case "/readyz":
      return send(res, ready ? 200 : 503, { ready });
    case "/visit": {
      // appends a line to a file on the mounted volume (LAB11)
      const line = `${new Date().toISOString()} ${os.hostname()}\n`;
      try {
        fs.appendFileSync(`${DATA_DIR}/visits.log`, line);
        const visits = fs.readFileSync(`${DATA_DIR}/visits.log`, "utf8").trim().split("\n");
        return send(res, 200, { visits: visits.length, last: visits.slice(-3) });
      } catch (err) {
        return send(res, 500, { error: err.message });
      }
    }
    case "/burn": {
      // CPU load for autoscaling demos (LAB12)
      const end = Date.now() + Number(url.searchParams.get("ms") || 200);
      while (Date.now() < end) { Math.sqrt(Math.random()); }
      return send(res, 200, { burned: true, pod: os.hostname() });
    }
    default:
      return send(res, 200, {
        app: TITLE,
        version: VERSION,
        pod: os.hostname(),
        path: url.pathname,
        secrets: listSecrets(),
        time: new Date().toISOString(),
      });
  }
});

server.listen(PORT, () => {
  console.log(`${TITLE} ${VERSION} listening on ${PORT}`);
  setTimeout(() => { ready = true; }, 2000);
});

process.on("SIGTERM", () => {
  console.log("SIGTERM received - shutting down");
  ready = false;
  server.close(() => process.exit(0));
});

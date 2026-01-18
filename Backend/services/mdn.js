import Bonjour from "bonjour";

const bonjour = new Bonjour();

export function startMDNS(port = 8080) {
  bonjour.publish({
    name: "LANPlay Server",
    type: "lanplay",   // service name → _lanplay._tcp
    protocol: "tcp",
    port,
    txt: {
      app: "LANPlay",
      version: "1.0.0"
    }
  });

  console.log("📡 mDNS published: lanplay.local");
}

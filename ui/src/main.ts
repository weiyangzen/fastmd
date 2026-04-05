import "./styles.css";

import { mountPreviewShell } from "./app";
import { demoBootstrapPayload } from "./fixtures";

const container = document.getElementById("app");

if (!container) {
  throw new Error("FastMD shared frontend could not find the #app mount node.");
}

const app = mountPreviewShell(container, demoBootstrapPayload);
void app.connect();

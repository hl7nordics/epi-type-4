const SOURCE_URL = "data/source-bundle.xml";
// Compiled from xslt/*.xsl with `npm run build`
const GENERATE_SEF = "xslt/generate.sef.json";
const RENDER_SEF = "xslt/render.sef.json";

const $ = (id) => document.getElementById(id);
const mkEditor = (id) =>
  CodeMirror.fromTextArea($(id), { mode: "application/xml", lineNumbers: true, lineWrapping: false });
const left = mkEditor("left-xml");
const right = mkEditor("right-xml");

function showError(msg) {
  const el = $("error");
  el.textContent = msg || "";
  el.classList.toggle("d-none", !msg);
}

async function fetchText(url) {
  const res = await fetch(url, { cache: "no-store" });
  if (!res.ok) throw new Error(`Failed to load ${url}: HTTP ${res.status}`);
  return res.text();
}

function parseXml(text, label) {
  const doc = new DOMParser().parseFromString(text, "application/xml");
  const err = doc.getElementsByTagName("parsererror")[0];
  if (err) throw new Error(`${label} is not well-formed XML: ${err.textContent}`);
  return doc;
}

async function transform(sef, xmlText, label, params = {}) {
  parseXml(xmlText, label);
  const result = await SaxonJS.transform(
    { stylesheetLocation: sef, sourceText: xmlText, destination: "serialized", stylesheetParams: params },
    "async"
  );
  return result.principalResult;
}

async function generate() {
  const out = await transform(GENERATE_SEF, left.getValue(), "Left XML", { bundleId: crypto.randomUUID() });
  right.setValue(out);
}

// Defensive cleanup: the rendered output comes from editable XML.
function sanitize(root) {
  root.querySelectorAll("script, iframe, object, embed, style, link").forEach((n) => n.remove());
  root.querySelectorAll("*").forEach((n) => {
    for (const a of [...n.attributes]) {
      if (/^on/i.test(a.name) || /^\s*javascript:/i.test(a.value)) n.removeAttribute(a.name);
    }
  });
}

async function render() {
  const html = await transform(RENDER_SEF, right.getValue(), "Right XML");
  const box = $("rendered");
  box.innerHTML = html;
  sanitize(box);
}

function guard(fn) {
  return async () => {
    showError("");
    try { await fn(); } catch (e) { showError(e.message); }
  };
}

$("generate").addEventListener("click", guard(generate));
$("render").addEventListener("click", guard(render));

guard(async () => left.setValue(await fetchText(SOURCE_URL)))().then(() => {
  if (location.protocol === "file:") {
    showError("Loading files via file:// is blocked by the browser. Serve the folder over HTTP (see README).");
  }
});

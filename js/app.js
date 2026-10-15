const SOURCE_LIST_URL = "data/source-bundles.json";
// Compiled from xslt/*.xsl with `npm run build`
const GENERATE_SEF = "xslt/generate.sef.json";
const RENDER_SEF = "xslt/render.sef.json";

const $ = (id) => document.getElementById(id);
const mkEditor = (id) =>
  CodeMirror.fromTextArea($(id), { mode: "application/xml", lineNumbers: true, lineWrapping: false });
const left = mkEditor("left-xml");
const right = mkEditor("right-xml");
const sourceSelect = $("source-select");
let activeSource = "";

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

async function loadSource(filename) {
  const xml = await fetchText(`data/${encodeURIComponent(filename)}`);
  left.setValue(xml);
  activeSource = filename;
}

async function loadSources() {
  const sourceListText = await fetchText(SOURCE_LIST_URL);
  let sources;
  try {
    sources = JSON.parse(sourceListText);
  } catch (e) {
    throw new Error(`Failed to parse ${SOURCE_LIST_URL}: ${e.message}`);
  }
  if (!sources || typeof sources !== "object" || Array.isArray(sources)) {
    throw new Error(`${SOURCE_LIST_URL} must contain an object mapping XML filenames to titles`);
  }

  const entries = Object.entries(sources);
  if (!entries.length || entries.some(([filename, title]) =>
    !/^[^/\\]+\.xml$/i.test(filename) || typeof title !== "string" || !title.trim()
  )) {
    throw new Error(`${SOURCE_LIST_URL} must map XML filenames to non-empty titles`);
  }

  sourceSelect.replaceChildren(...entries.map(([filename, title]) => {
    const option = document.createElement("option");
    option.value = filename;
    option.textContent = title;
    return option;
  }));
  await loadSource(entries[0][0]);
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
sourceSelect.addEventListener("change", guard(async () => {
  const previousSource = activeSource;
  try {
    await loadSource(sourceSelect.value);
  } catch (e) {
    sourceSelect.value = previousSource;
    throw e;
  }
}));

guard(loadSources)().catch(() => {
  if (location.protocol === "file:") {
    showError("Loading files via file:// is blocked by the browser. Serve the folder over HTTP (see README).");
  }
});

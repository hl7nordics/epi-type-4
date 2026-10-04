# ePI type 4 demo

Static demo page: edit a FHIR document Bundle (left), **Generate** the target Bundle (right) via XSLT, and **Render** it to HTML below.

- `data/source-bundle.xml` – left-side bundle; edit this file to change the starting content
- `xslt/generate.xsl` – left → right bundle transformation (XSLT 3.0 / 2.0 features)
- `xslt/render.xsl` – right bundle → HTML
- `xslt/*.sef.json` – compiled stylesheets (generated, committed so the page works without a build)
- `js/app.js`, `index.html` – UI (Bootstrap, CodeMirror 5 from jsDelivr CDN; the Saxon-JS runtime is vendored in `vendor/` because the npm package ships only the Node build — see `vendor/SAXON-JS-LICENSE.txt`)

## XSLT 2.0/3.0

Browsers only support XSLT 1.0 natively, so the transformations run in [Saxon-JS](https://www.saxonica.com/saxon-js/) instead. Saxon-JS executes stylesheets compiled to its SEF format. After editing an `.xsl` file, recompile (Node.js required):

```sh
npm install
npm run build
```

The GitHub Pages workflow also rebuilds them on every deploy.

## Run locally

The source XML is loaded with `fetch()`, which browsers block on `file://` URLs. Serve the folder over HTTP. Any of:

```sh
docker compose up        # http://localhost:8080 (files are mounted, edits show on reload)
python3 -m http.server 8080
npx serve .
```

An internet connection is needed for the CDN assets.

## GitHub Pages

1. Push to a GitHub repository with default branch `main`.
2. In **Settings → Pages**, set **Source** to **GitHub Actions**. The workflow in `.github/workflows/pages.yml` deploys on each push to `main`.
   (Alternative: Source = "Deploy from a branch", `main` / root; `.nojekyll` is included.)
3. The site is at `https://<user>.github.io/<repo>/`. All paths are relative, so the sub-path works.

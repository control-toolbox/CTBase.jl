# Migration from Documenter to DocumenterVitepress

## Migration Steps

### 1. Update dependencies

File **docs/Project.toml**

- Add `DocumenterVitepress` (UUID: `4710194d-e776-4893-9690-8d956a29c365`)
- Add `LiveServer` for local preview
- Keep `Documenter` as a dependency

```toml
[deps]
Documenter = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
DocumenterVitepress = "4710194d-e776-4893-9690-8d956a29c365"
LiveServer = "16fef848-5104-11e9-1b77-fb7a48bbb589"

[compat]
Documenter = "1"
DocumenterVitepress = "0.3"
LiveServer = "1"
```

### 2. Modify make.jl

File **docs/make.jl**

- Add `using DocumenterVitepress`
- Replace `format=Documenter.HTML(...)` with `format=DocumenterVitepress.MarkdownVitepress(...)`
- Replace `deploydocs` with `DocumenterVitepress.deploydocs`

```julia
using Documenter
using DocumenterVitepress

makedocs(;
    # ... other arguments ...
    format=DocumenterVitepress.MarkdownVitepress(;
        repo="https://github.com/control-toolbox/CTBase.jl",
        devbranch="main",
        devurl="dev",
        sidebar_drawer=true,
    ),
    # ...
)

DocumenterVitepress.deploydocs(;
    repo="github.com/control-toolbox/CTBase.jl.git",
    devbranch="main",
    push_preview=true,
)
```

### 3. Install Julia dependencies

After editing `docs/Project.toml`, resolve and instantiate (the Manifest must be regenerated to include the new packages):

```bash
julia --project=docs -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
```

### 4. Generate Vitepress configuration files

`generate_template` requires `DocumenterVitepress` to be installed (step 3 must be done first).

```bash
julia --project=docs -e 'using DocumenterVitepress; DocumenterVitepress.generate_template("docs", "CTBase")'
```

This creates the following files (do not create them manually):

In `docs/src/`:

- `.vitepress/config.mts` - Main Vitepress configuration
- `.vitepress/theme/index.ts` - Theme customization
- `.vitepress/theme/style.css` - Custom CSS styles
- `.vitepress/theme/docstrings.css` - Docstring block styles
- `.vitepress/mathjax-plugin.ts` - MathJax plugin
- `.vitepress/julia-repl-transformer.ts` - Julia REPL transformer
- `components/VersionPicker.vue` - Version picker navbar component
- `components/SidebarDrawerToggle.vue` - Sidebar collapse toggle
- `components/AuthorBadge.vue` - Author badge component
- `components/Authors.vue` - Authors list component

At the root of `docs/`:

- `package.json` - npm dependencies
- `.gitignore` - ignores `build/`, `node_modules/`, `package-lock.json`, `Manifest.toml`

### 5. Patch config.mts for remote assets

The generated `docs/src/.vitepress/config.mts` does not include the control-toolbox CSS/JS assets. Edit the `head` section to add them.

Replace the generated `head` block:

```typescript
head: [
  ['link', { rel: 'icon', href: 'REPLACE_ME_DOCUMENTER_VITEPRESS_FAVICON' }],
  ['script', {src: `${getBaseRepository(baseTemp.base)}versions.js`}],
  ['script', {src: `${baseTemp.base}siteinfo.js`}]
],
```

With the remote assets version (Option B):

```typescript
head: [
  ['link', { rel: 'icon', href: 'REPLACE_ME_DOCUMENTER_VITEPRESS_FAVICON' }],
  ['link', { rel: 'stylesheet', href: 'https://control-toolbox.org/assets/css/vitepress-documentation.css' }],
  ['script', {src: `${getBaseRepository(baseTemp.base)}versions.js`}],
  ['script', {src: 'https://control-toolbox.org/assets/js/vitepress-documentation.js'}],
  ['script', {src: `${baseTemp.base}siteinfo.js`}]
],
```

#### Option A: Local assets (for development only)

If assets are not yet published remotely, use local files placed in `docs/src/assets/`. Add a Vite plugin in the `vite.plugins` section of `config.mts` to copy them at build time:

```typescript
import { copyFileSync, mkdirSync } from 'fs'

let ctOutDir = ''

// inside vite.plugins:
{
  name: 'ct-static-assets',
  apply: 'build' as const,
  configResolved(config: any) {
    if (!config.build.ssr) ctOutDir = config.build.outDir
  },
  closeBundle() {
    if (!ctOutDir) return
    const assetsDir = path.join(ctOutDir, 'assets')
    mkdirSync(assetsDir, { recursive: true })
    for (const file of [
      'vitepress-documentation.css',
      'vitepress-documentation.js',
    ]) {
      try { copyFileSync(path.resolve(__dirname, '../assets', file), path.join(assetsDir, file)) } catch (_) {}
    }
  }
},
```

And reference them in `head` using `${baseTemp.base}assets/...` instead of the remote URLs.

### 6. Install npm dependencies

```bash
cd docs && npm install
```

### 7. Local build and preview

```bash
# Generate documentation
julia --project=docs docs/make.jl

# Local preview (output is in docs/build/1/, not docs/build/)
julia --project=docs -e 'using LiveServer; LiveServer.serve(dir="docs/build/1")'
```

## Important notes

- **ANSI color codes in @repl blocks**: DocumenterVitepress does not automatically convert ANSI escape codes to HTML in `@repl` blocks (unlike `@example` blocks which are converted to `ansi` code blocks). To avoid raw ANSI codes appearing in the generated markdown, wrap `showerror` calls with `IOContext(stdout, :color => false)`:

  ```julia
  try
      throw(CTBase.Exceptions.IncorrectArgument("n must be positive"; got="-1"))
  catch e
      showerror(IOContext(stdout, :color => false), e)
  end
  ```

  This is a known limitation tracked in [LuxDL/DocumenterVitepress.jl#321](https://github.com/LuxDL/DocumenterVitepress.jl/issues/321).

- **Color-aware display functions**: If your package has custom display functions that use ANSI codes (e.g., error display helpers), make them color-aware by checking `get(io, :color, false)`. For example, in CTBase we implemented a helper function and updated all ANSI styling primitives:

  ```julia
  # src/Exceptions/display.jl
  _apply_ansi(s, code, io::IO) = get(io, :color, false) ? "\033[$(code)m$(s)\033[0m" : s

  _dim(s, io::IO)    = _apply_ansi(s, "2",    io)
  _bold(s, io::IO)   = _apply_ansi(s, "1",    io)
  _red(s, io::IO)    = _apply_ansi(s, "1;31", io)
  _yellow(s, io::IO) = _apply_ansi(s, "33",   io)
  _green(s, io::IO)  = _apply_ansi(s, "32",   io)
  ```

  Then propagate the `io` parameter to all call sites in display functions:

  ```julia
  function _format_user_friendly_error(io::IO, e::CTException)
      # ...
      print(io, _red(type_name, io))  # Pass io to the helper
      # ...
  end
  ```

  This ensures:
  - REPL / GitHub Actions → colors enabled (`:color => true` by default)
  - Documenter / VitePress → plain text when wrapped with `IOContext(stdout, :color => false)`)

- **Git repository required**: DocumenterVitepress requires a git repository to function
- **Build output**: Documentation is generated in `docs/build/1/` (not `docs/build/`)
- **Do not create Vitepress files manually**: always use `generate_template` (step 4) — it generates all config, theme, components, and npm files
- **Symlinks**: Before deployment, remove symlinks on the `gh-pages` branch (stable, v1, etc.)

  Documenter.jl uses symlinks on the `gh-pages` branch to manage documentation versions:

  - `stable` → points to the current stable version (e.g., `v0.5.0`)
  - `v1` → points to the latest major version
  - `v0.1`, `v0.2`, etc. → point to specific versions

  DocumenterVitepress cannot write to symlinks. If you are migrating from an existing Documenter documentation, your `gh-pages` branch likely contains these symlinks. They must be manually removed before the first deployment with DocumenterVitepress.

  **How to remove symlinks:**

  1. Go to GitHub: `https://github.com/control-toolbox/CTBase.jl/tree/gh-pages`
  2. Symlinks are identifiable by a small arrow ↗
  3. Click on each symlink (stable, v1, etc.)
  4. Delete them via the context menu

  DocumenterVitepress handles versions differently, without using symlinks.
- **Vitepress configuration**: The `REPLACE_ME_DOCUMENTER_VITEPRESS` strings are automatically replaced during the build
- **TypeScript errors**: TypeScript errors in the IDE regarding `sidebar` and missing `node_modules` are normal before `npm install` — DocumenterVitepress replaces these values during the build

## Deployment

Deployment is done automatically via CI with `DocumenterVitepress.deploydocs`. Ensure that:

- The GitHub repository exists
- The `gh-pages` branch does not contain symlinks
- CI workflows are configured for DocumenterVitepress

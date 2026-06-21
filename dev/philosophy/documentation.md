# Documentation site

How docstrings become a published site via Documenter.jl and
`CTBase.automatic_reference_documentation()`. Generic examples. Complements
[`docstrings.md`](docstrings.md) (what to write *inside* docstrings).

## Principles

1. **Auto-generated API reference** — never hand-write API pages; generate one per
   submodule (and one unified internals page for all private symbols).
2. **Public + private documented, separately** — one flat page per submodule for
   exported symbols (`public=true, private=false`); one unified "Internals" page for all
   private symbols across all submodules and extensions (`public=false, private=true`).
   Users reach internals via qualified paths, so internals are part of the documented
   surface — but kept out of the main navigation.
3. **Guides separate from API** — narrative guides are hand-written under
   `docs/src/<topic>/`; the API reference is generated and cleaned up after the build.
4. **Index is the entry point** — `docs/src/index.md`: scope, module table, guide links,
   a short Quick Start.
5. **Cross-refs resolve at build time** — every `@extref` is backed by an `InterLinks`
   entry in `make.jl`.

## Layout

```text
docs/
├── make.jl              # entry point; uses with_api_reference()
├── api_reference.jl     # generate_api_reference() + with_api_reference() + cleanup
├── inventories/         # InterLinks fallback inventories (one per dependency)
└── src/
    ├── index.md         # landing page
    ├── <topic>/         # hand-written guides
    └── api/             # auto-generated (removed after build)
```

## API generation pattern

The standard pattern uses a shared `modules_config` list to avoid repeating file lists,
then generates public pages in a loop and one unified Internals page.

```julia
# ── Shared config: one entry per submodule ────────────────────────────────────
modules_config = [
    (mod=MyPackage.SubA, title="SubA", filename="suba", files=src(
        "SubA/SubA.jl", "SubA/types.jl", "SubA/helpers.jl",
    )),
    (mod=MyPackage.SubB, title="SubB", filename="subb", files=src(
        "SubB/SubB.jl", "SubB/core.jl",
    )),
]

EXCLUDE = Symbol[:include, :eval]

# ── Public pages: one flat page per submodule ─────────────────────────────────
pages = [
    MyPackage.automatic_reference_documentation(;
        subdirectory = "api",
        primary_modules = [cfg.mod => cfg.files],
        exclude  = EXCLUDE,
        public   = true,
        private  = false,
        title    = cfg.title,
        filename = cfg.filename,
    )
    for cfg in modules_config
]

# ── Internals: all private symbols in one page, sections by module ────────────
internals_modules = Any[cfg.mod => cfg.files for cfg in modules_config]

# Extensions are detected and added conditionally
for (sym, files) in [
    (:MyExt, ext("MyExt/MyExt.jl", "MyExt/helpers.jl")),
]
    extmod = Base.get_extension(MyPackage, sym)
    isnothing(extmod) || push!(internals_modules, extmod => files)
end

push!(pages, MyPackage.automatic_reference_documentation(;
    subdirectory                 = "api",
    primary_modules              = internals_modules,
    external_modules_to_document = [MyPackage],
    exclude                      = EXCLUDE,
    public                       = false,
    private                      = true,
    title                        = "Internals",
    filename                     = "internals",
))
```

The resulting navigation is:

```text
API Reference
    SubA        ← exported symbols only
    SubB        ← exported symbols only
    Internals   ← all private symbols, sections by module (including extensions)
```

Keep the per-submodule file lists in sync with `src/` — a missing file silently drops
docstrings and breaks `@ref` links.

## Cross-reference infrastructure

```julia
using DocumenterInterLinks
links = InterLinks(
    "OtherPkg" => ("https://.../OtherPkg.jl/stable/",
                   "https://.../OtherPkg.jl/stable/objects.inv",
                   joinpath(@__DIR__, "inventories", "OtherPkg.toml")),
)
makedocs(; plugins=[links], ...)   # makes [`OtherPkg.Sub.Sym`](@extref) resolve
```

## The draft switch (development workflow)

`make.jl` exposes `draft`. In draft mode, `@example`/`@setup` Julia cells are **not
executed** — fast structural/link validation. Per-file override:

````markdown
```@meta
Draft = false
```
````

Workflow: build with `draft = true` first (fix all links fast), then flip one file at a
time to `Draft = false` to debug its examples, then `draft = false` globally for the
final full build. (Operational details in [`../RULES.md`](../RULES.md).)

## Index page

Mandatory pieces of `docs/src/index.md`: a `@meta CurrentModule` block, a one-paragraph
scope statement, info/note/warning admonitions (notably the qualified-access policy), a
module table, guide links via `[@ref]`, and a short Quick Start with qualified calls.

## Checklist

- [ ] `make.jl` uses `with_api_reference()`; `api_reference.jl` has generate/with/cleanup.
- [ ] One `automatic_reference_documentation` per submodule (`public=true, private=false`) + one unified Internals page (`public=false, private=true`).
- [ ] Extensions detected via `Base.get_extension` and documented when present.
- [ ] `InterLinks` set up and passed via `plugins=[links]` if `@extref` is used.
- [ ] Guides under `docs/src/<topic>/`; no hand-written API pages.
- [ ] `index.md` has meta, scope, admonitions, module table, guide links, Quick Start.
- [ ] Built clean: draft (links) → per file → full.

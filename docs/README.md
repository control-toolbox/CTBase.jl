# Documentation Guide for CTBase

This directory contains the source files and build scripts for the `CTBase.jl` documentation.

## Overview

The documentation is built using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl). It features an automated API reference generation system provided by the `DocumenterReference` extension in `CTBase.jl`.

## Building the Documentation

From the root of the repository:

```bash
julia --project=. docs/make.jl
```

`make.jl` prepends both `docs/` and the package root to `LOAD_PATH`, so the package
project is picked up automatically — no `Pkg.develop` step needed.

### Draft mode (fast link validation)

Set `draft = true` at the top of `docs/make.jl` to skip `@repl`/`@example` block
execution. This is much faster when iterating on cross-references and page structure:

```bash
# edit docs/make.jl: draft = true  (line 16)
julia --project=. docs/make.jl
```

!!! note "warnonly"
    `make.jl` uses `warnonly=[:cross_references]`, so cross-reference warnings do not
    abort the build. Other errors (missing pages, broken `@repl` blocks) still fail.

## Viewing the Documentation

After a successful build, the generated HTML files are located in `docs/build/`. You can open `index.html` in your browser:

```bash
# macOS
open docs/build/index.html

# Linux
xdg-open docs/build/index.html
```

## Directory Structure

- `src/`: Contains the manual markdown files (Introduction, Getting Started, Guides, etc.).
- `make.jl`: The main build script for Documenter.
- `api_reference.jl`: Contains the logic for automatic API reference generation. It extracts docstrings from the source code and creates temporary markdown files.
- `build/`: The directory where the static website is generated (ignored by git).

## Automated API Reference

The `api_reference.jl` script uses `CTBase.automatic_reference_documentation()` to scan the modules.
- It generates public and private API pages for each sub-module.
- These files are created temporarily in `docs/src/` during the build process.
- The `with_api_reference()` wrapper in `make.jl` ensures these temporary files are deleted after the build.

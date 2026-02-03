# Documentation Guide for CTBase

This directory contains the source files and build scripts for the `CTBase.jl` documentation.

## Overview

The documentation is built using [Documenter.jl](https://github.com/JuliaDocs/Documenter.jl). It features an automated API reference generation system provided by the `DocumenterReference` extension in `CTBase.jl`.

## Building the Documentation

There are several ways to build the documentation locally.

### 1. Terminal One-Liner (Recommended)

From the root of the `CTBase.jl` repository, run:

```bash
julia --project=docs/ -e 'using Pkg; Pkg.develop(path=pwd()); include("docs/make.jl"); Pkg.rm("CTBase")'
```

This command:
- Activates the `docs` project environment.
- Temporarily "develops" the current package so changes are reflected in the build.
- Executes `make.jl` to build the site.
- Cleans up the `docs` environment by removing the temporary link to `CTBase`.

### 2. Manual REPL Build

If you prefer working inside the Julia REPL:

```julia
# 1. Activate the docs project
using Pkg
Pkg.activate("docs/")

# 2. Add CTBase in development mode (if not already done)
Pkg.develop(path=pwd())

# 3. Build the documentation
include("docs/make.jl")
```

## Viewing the Documentation

After a successful build, the generated HTML files are located in `docs/build/`. You can open `index.html` in your browser:

```bash
# macOS
open docs/build/index.html

# Linux
xdg-open docs/build/index.html
```

## Directory Structure

- `src/`: Contains the manual markdown files (Introduction, Tutorials, etc.).
- `make.jl`: The main build script for Documenter.
- `api_reference.jl`: Contains the logic for automatic API reference generation. It extracts docstrings from the source code and creates temporary markdown files.
- `build/`: The directory where the static website is generated (ignored by git).

## Automated API Reference

The `api_reference.jl` script uses `CTBase.automatic_reference_documentation()` to scan the modules.
- It generates public and private API pages for each sub-module.
- These files are created temporarily in `docs/src/` during the build process.
- The `with_api_reference()` wrapper in `make.jl` ensures these temporary files are deleted after the build.

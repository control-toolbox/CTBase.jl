# CTBase.jl — Agent Navigation Guide

Quick-reference for any agent working on this repository.

---

## Project Overview

**CTBase.jl** is the foundational Julia package in the [control-toolbox](https://github.com/control-toolbox) ecosystem.
It provides the **base layer**: shared types, exceptions, extensions infrastructure, and development tools.

---

## Source Architecture

Submodule layout (all public symbols accessed via qualified paths — no top-level exports):

```text
src/
├── CTBase.jl           # Top-level manifest — exports nothing
├── Core/               # Core types and utilities
├── Descriptions/       # Type descriptions and metadata
├── Exceptions/         # Structured exception types
├── Extensions/         # Extension infrastructure
└── Unicode/            # Unicode utilities

ext/
├── CoveragePostprocessing.jl  # Coverage report postprocessing
├── DocumenterReference.jl     # Documenter.jl reference generation
└── TestRunner.jl             # Test runner with progress bar

test/suite/             # Tests organised by functionality (not by src layout)
docs/                   # Documenter.jl site (auto-generated API)
dev/                    # Code philosophy, operational rules, plan template (versioned)
```

---

## Developer resources

| File | Purpose |
|---|---|
| [`dev/philosophy/PHILOSOPHY.md`](dev/philosophy/PHILOSOPHY.md) | Code philosophy — modules, types/traits, exceptions, docstrings, testing, docs |
| [`dev/RULES.md`](dev/RULES.md) | Operational rules — running tests (MCP), building docs, git, output capture |
| [`dev/planning.md`](dev/planning.md) | Plan template — phases, steps, human checkpoints |

---

## Devin Workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `architecture.md` | — | Introducing new types, restructuring modules, reviewing SOLID/patterns |
| `docstrings.md` | — | Writing or reviewing Julia docstrings |
| `documentation.md` | `glob: docs/**/*` | Documenter.jl layout, `make.jl` template, `api_reference.jl`, `InterLinks` setup |
| `exceptions.md` | — | Adding error paths, contract stubs, argument validation |
| `modules.md` | `glob: src/**/*.jl, ext/**/*.jl` | Submodule conventions: qualified imports, manifest pattern, export policy, DAG ordering |
| `performance.md` | — | Hot paths, inner loops, profiling, benchmarking |
| `plan.md` | — | Writing an implementation plan before coding |
| `testing-creation.md` | — | Writing or reviewing test files under `test/suite/` |
| `testing-execution.md` | `model_decision` | How to run tests (commands, `tee` capture) |
| `type-stability.md` | — | New structs, parametric types, `@inferred` test design |

Workflows live in `.devin/workflows/`.

---

## Key Conventions

- **No top-level exports** — use `CTBase.Submodule.symbol` everywhere.
- **Qualified imports** — `using PackageName: PackageName`, never bare `using`.
- **Fake types at module top-level** — never inside test functions.
- **Plans before code** — write a plan and confirm with the user before touching files. Template: [`dev/planning.md`](dev/planning.md).
- **Docstrings last** — written only after all implementation steps are stable.
- **Never commit or push without explicit user approval.**

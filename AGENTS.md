# CTBase.jl — Agent Navigation Guide

Quick-reference for any agent working on this repository.

---

## Repository Layout

Standard control-toolbox package structure. Each directory may contain a `README.md`
with package-specific details — read it before working in that directory.

```text
src/        # Source code: one submodule per responsibility, no top-level exports
ext/        # Weak-dependency extensions (loaded on demand by Julia)
test/suite/ # Test suite: organised by functionality, not by src/ layout
docs/       # Documentation site (DocumenterVitepress)
```

---

## Developer Resources

Design philosophy, operational rules, and plan templates live in the
[control-toolbox Handbook](https://github.com/control-toolbox/Handbook):

| Topic | Link |
| --- | --- |
| Code philosophy (modules, types/traits, exceptions, docstrings, testing, docs) | [`PHILOSOPHY.md`](https://raw.githubusercontent.com/control-toolbox/Handbook/refs/heads/main/PHILOSOPHY.md) |
| Operational rules (tests, coverage, docs, git) | [`RULES.md`](https://raw.githubusercontent.com/control-toolbox/Handbook/refs/heads/main/RULES.md) |
| Plan template | [`PLAN.md`](https://raw.githubusercontent.com/control-toolbox/Handbook/refs/heads/main/PLAN.md) |

---

## Key Conventions

- **No top-level exports** — use `Package.Submodule.symbol` everywhere.
- **Qualified imports** — `import Pkg: Pkg`, never bare `using`.
- **Fake types at module top-level** — never inside test functions.
- **Plans before code** — write a plan and confirm with the user before touching files.
- **Docstrings last** — written only after all implementation steps are stable.
- **Never commit or push without explicit user approval.**

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
.handbook/  # control-toolbox Handbook (git submodule, pinned to a tag)
```

---

## Developer Resources

Design philosophy, operational rules, plan templates, and CI/CD conventions live in the
[control-toolbox Handbook](https://github.com/control-toolbox/Handbook), vendored as a git
submodule in `.handbook/` and pinned to a SemVer release tag (`vX.Y.Z`). Read the local files;
if `.handbook/` is empty, run `git submodule update --init`.

| Topic | Link |
| --- | --- |
| Code philosophy (modules, types/traits, exceptions, docstrings, testing, docs) | [`PHILOSOPHY.md`](.handbook/PHILOSOPHY.md) |
| Operational rules (tests, coverage, docs, git) | [`RULES.md`](.handbook/RULES.md) |
| Plan template | [`PLAN.md`](.handbook/PLAN.md) |
| CI/CD workflows (centralized reusable workflows, label-gated triggers) | [`WORKFLOWS.md`](.handbook/WORKFLOWS.md) |

---

## Key Conventions

- **No top-level exports** — use `Package.Submodule.symbol` everywhere.
- **Qualified imports** — `using Pkg: Pkg`, never bare `using Pkg`; `import` is never used.
- **Fake types at module top-level** — never inside test functions.
- **Structured errors** — seven typed exceptions under `CTException`; pick by the IncorrectArgument / PreconditionError / NotImplemented rule.
- **Type stability enforced** — hot paths must be `@inferred`-clean, verified with JET; setup-path dispatch is fine.
- **1-D is a scalar** — a one-dimensional state/control/variable is a `Number`, never a length-1 vector.
- **Plans before code** — write a plan and confirm with the user before touching files.
- **Docstrings last** — written only after all implementation steps are stable.
- **Never commit or push without explicit user approval.**

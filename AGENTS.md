# CTBase.jl — Agent Navigation Guide

Quick-reference for any agent working on this repository.

---

## Repository Layout

Standard control-toolbox package structure. Each directory may contain a `README.md`
with package-specific details — read it before working in that directory.

```text
src/           # Source code: one submodule per responsibility, no top-level exports
ext/           # Weak-dependency extensions (loaded on demand by Julia)
test/suite/    # Test suite: organised by functionality, not by src/ layout
docs/          # Documentation site (DocumenterVitepress)
.conventions/  # ct-conventions, cloned at the pinned tag (git-ignored)
```

---

## Conventions

The coding conventions live in
[ct-conventions](https://github.com/control-toolbox/ct-conventions), pinned below to a
SemVer release tag (`vX.Y.Z`). Read them from a local clone in `.conventions/`
(git-ignored, not a submodule). If it is missing, or `git -C .conventions describe --tags`
is not the pinned tag, (re)create it:

```bash
rm -rf .conventions
git -c advice.detachedHead=false clone --quiet --depth 1 --branch v0.4.0 https://github.com/control-toolbox/ct-conventions.git .conventions
```

**Pinned version: ct-conventions v0.4.0.** Cite rules by identifier (`MOD3`, `TST1`), and
state the version you applied in plans and reports.

Read in this order:

| File | Content |
| --- | --- |
| [`rules/general.md`](.conventions/rules/general.md) | Rules that hold everywhere — **always read** |
| [`README.md`](.conventions/README.md) | Index of the rule files, one per area (`MOD`, `TYP`, `DIM`, `EXC`, `PERF`, `DOC`, `TST`, `SITE`, `CHG`) |
| [`method.md`](.conventions/method.md) | How to work: tests, coverage, docs build, output capture |
| [`plan-template.md`](.conventions/plan-template.md) | Template for a substantial piece of work |

How agents behave on these repositories is described in
[ct-agents](https://github.com/control-toolbox/ct-agents).

---

## Key Conventions

- **English everywhere** — code, docs, commits, issues, PRs (`GEN1`).
- **No top-level exports** — use `Package.Submodule.symbol` everywhere (`MOD8`).
- **Qualified imports** — `using Pkg: Pkg`, never bare `using Pkg`; `import` is never used (`MOD3`, `MOD4`).
- **Fake types at module top-level** — never inside test functions (`TST3`).
- **Structured errors** — seven typed exceptions; pick by the choice rule (`EXC1`).
- **Type stability enforced** — hot paths `@inferred`-clean, verified with JET (`TYP8`, `PERF1`–`PERF5`).
- **1-D is a scalar** — a one-dimensional state/control/variable is a `Number` (`DIM1`).
- **Plan before code** — a local agent proposes a plan ([`plan-template.md`](.conventions/plan-template.md)) and waits for confirmation before working on code. The process for remote agents is still to be defined.
- **Docstrings last** — written once the implementation is stable (`DOC1`–`DOC8`).
- **The human merges** — an agent never merges a pull request.

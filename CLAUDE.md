# CTBase.jl — Claude project context

## Essential rules

1. **Never commit or push without explicit approval.** Ask first, every time.
2. **Run tests via the `ct-dev-mcp` MCP** — `get_test_command` → run with `tee` →
   `generate_report`. Never invent the test command.
3. **Build docs draft-first** — `draft = true` globally to validate links, then per file
   with `Draft = false`, then full build. See `dev/RULES.md`.
4. **Qualify everything** — `Module.symbol` at every call site; `import Pkg: Pkg` not
   `using Pkg`; no top-level package exports.
5. **Write a plan before coding** — any task touching more than one file or a public
   interface needs a plan confirmed by the user first. Template in `dev/PLAN.md`.
6. **Docstrings last** — written only after the API is stable.
7. **Fake types at module top-level** — never inside test functions (world-age issues).

## Where to find more

| Topic | File |
| --- | --- |
| Code philosophy (modules, types/traits, exceptions, docstrings, testing, docs) | [`dev/philosophy/`](dev/philosophy/PHILOSOPHY.md) |
| Operational rules (MCP, doc build, git, output capture) | [`dev/RULES.md`](dev/RULES.md) |
| Plan template | [`dev/PLAN.md`](dev/PLAN.md) |

## Project structure (quick reference)

```text
src/CTBase.jl           # top-level manifest — exports nothing
src/<Module>/<Module>.jl  # submodule manifests
ext/                    # weak-dependency extensions (CoveragePostprocessing, DocumenterReference, TestRunner)
test/suite/             # tests by functionality, not by src layout
docs/                   # Documenter.jl site
dev/                    # philosophy, rules, planning template (versioned)
```

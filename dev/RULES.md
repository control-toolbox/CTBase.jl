# RULES — tools and procedures for a development agent

**Generic** rules (valid for any Julia package in the control-toolbox ecosystem, with
no reference to a specific package's code). They describe *how to work*: run tests,
build docs, handle git, capture output. For *how to design*, see
[`philosophy/`](philosophy/PHILOSOPHY.md).

---

## 1. Running tests — via the `ct-dev-mcp` MCP server

Do not invent the test command. Use the MCP server that provides it and can parse the
result.

1. **Get the command**: call the `get_test_command` tool with:
   - `cwd` = package root (where `Project.toml` lives) — **required**;
   - `test_args` = scope (empty = everything; `["test/suite/<group>"]`; a single file;
     a glob `["test/suite/*/*_flow*"]` passed **quoted** — TestRunner expands it, not
     the shell).
2. **Run** the returned command verbatim. It already includes
   `… 2>&1 | tee /tmp/ct-dev-mcp/<pkg>_<scope>_<id>.log`.
3. **Analyze**: call `generate_report(<log_file>)` on the returned log for a structured
   Markdown report (summary, first failures, compilation errors).

Rules:
- **Always `tee` the full log**; never truncate with `tail -N` live — the first error
  (often a compilation error) is usually *above* and would be lost, forcing a rerun.
- Inspect the saved log afterwards with `grep`/`rg`/`tail`/`less`, without rerunning.
- Logs go under `/tmp/…`; **never** commit them.
- Run the **targeted** suite first (fast iteration), then the **full** suite before
  considering a phase done (regression check).

### Fallback when `ct-dev-mcp` is unavailable

If the MCP server cannot be reached, fall back to the standard Julia interface — always
capture with `tee`:

```bash
# All tests
julia --project -e 'using Pkg; Pkg.test("MyPackage")' 2>&1 | tee /tmp/<pkg>_all.log

# Targeted scope
julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["suite/<group>/*"])' 2>&1 | tee /tmp/<pkg>_<scope>.log

# All tests including optional ones
julia --project -e 'using Pkg; Pkg.test("MyPackage"; test_args=["-a"])' 2>&1 | tee /tmp/<pkg>_all.log
```

Use `generate_report` on the captured log once MCP is available again.

---

## 2. Coverage

Coverage measures which source lines are exercised by the test suite.

### Prerequisites

`Coverage.jl` must be installed in the **base Julia environment** (not the project
environment):

```bash
julia --project=@v1.xx -e 'using Pkg; Pkg.add("Coverage")'
```

This is required because coverage post-processing runs outside the package project.

### Running coverage

```bash
julia --project=@. -e 'using Pkg; Pkg.test("MyPackage"; coverage=true); include("test/coverage.jl")' 2>&1 | tee /tmp/<pkg>_coverage.log
```

**Outputs** (under `.coverage/`):

- `lcov.info` — LCOV format, consumed by Codecov/CI.
- `cov_report.md` — human-readable summary of coverage gaps.
- `cov/` — per-file `.cov` detail files.

### Rules

- Do **not** commit `.coverage/`; add it to `.gitignore`.
- Run coverage on the **full** suite (not a subset), or results are misleading.
- Read `cov_report.md` to identify uncovered lines; do not chase 100% — cover logic,
  not trivial accessors.

---

## 3. Building documentation — "draft first" workflow

### Build command

From the package root:

```bash
julia --project=. docs/make.jl 2>&1 | tee /tmp/<pkg>_docs.log
```

`make.jl` prepends both `docs/` and the package root to `LOAD_PATH`; no `Pkg.develop`
step is needed.

### Local preview

Depends on the backend (see [`philosophy/documentation.md`](philosophy/documentation.md)):

- **DocumenterVitepress** (current ecosystem standard): `npx serve docs/build/1 --listen 5173`
  or with LiveServer: `julia --project=docs -e 'using LiveServer; LiveServer.serve(dir="docs/build/1", single_page=true)'`
- **Documenter.jl** (plain HTML): `open docs/build/index.html` (macOS) /
  `xdg-open docs/build/index.html` (Linux).

### Draft-first workflow

`docs/make.jl` exposes a `draft` switch. In **draft mode**, the Julia code in
`@example`/`@setup` blocks is **not executed**: the build is fast and validates the
structure, the `@ref`/`@extref` links and the paths. In non-draft mode everything runs
(slow but actually checks the examples).

```julia
# docs/make.jl
draft = true   # does not execute Julia cells
```

A **single file** can also be forced to non-draft via a meta block, keeping the rest in
draft — to debug one file quickly:

````markdown
```@meta
Draft = false
```
````

**Recommended procedure**:

1. **`draft = true`** (global) → build once. Fix all broken **links** (`@ref`/`@extref`)
   and paths. Fast.
2. **File by file**: set one file to `Draft = false` (meta block), rebuild, debug its
   `@example` blocks, fix. Repeat per page. Faster than running everything each time.
3. **`draft = false`** (global) → final full build, zero execution warnings.

On every build, **`tee`** the output to `/tmp/…` and filter (`grep -E
"Error|Warning.*failed|MethodError|UndefVar"`).

---

## 4. Git & commits

- **Never commit or push without explicit user approval.** Even after validated work,
  ask before `git commit`/`git push`.
- Do not commit on the default branch: branch off the correct base.
- Interactive flags (`-i`) are not supported in this environment.
- Prefer the `gh` CLI for GitHub operations (PRs, issues).
- End commit messages with the required `Co-Authored-By` trailer; end PR bodies with
  the required generation note.
- Do not commit transient files (`/tmp/*.log`, doc-build artifacts).

---

## 5. Editing files

- Prefer the **dedicated tools** (read/edit/write) over `cat`/`sed`/`awk`/`echo` in the
  shell for reading or modifying files.
- **Read before editing**; do not overwrite a file you have not read.
- An edit should match the surrounding code (style, naming, comment density).

---

## 6. Capturing long output

- Any verbose command (tests, doc build): `… 2>&1 | tee /tmp/<pkg>_<scope>.log`.
- Name the log by package + scope to avoid collisions between sessions.
- Filter the log *afterwards*; do not rerun just to get more context.

---

## 7. Ask vs proceed

- **Ask** before any hard-to-reverse or outward-facing action (commit, push, sending to
  an external service, deleting/overwriting files you did not create).
- **Proceed** on choices with an obvious default (style, conventional location),
  stating it, rather than blocking on a question.
- Report outcomes faithfully: if tests fail, say so with the output; if a step was
  skipped, say that.

---

## Quick checklist

- [ ] Tests run via `ct-dev-mcp` (`get_test_command` → run+`tee` → `generate_report`).
- [ ] Targeted suite green, then full suite green.
- [ ] Coverage run on the full suite; `cov_report.md` reviewed.
- [ ] Docs built in draft (links OK), then per file, then full; previewed locally.
- [ ] No git action without explicit approval.
- [ ] Dedicated file tools used; files read before editing.
- [ ] Long output captured via `tee` under `/tmp`.

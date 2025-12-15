---
description: Generation of unit & integration tests in Julia
---

# Julia Unit + Integration Test Authoring Workflow (Local)

**Goal**: Analyse a Julia package, identify missing/weak tests, then generate or improve tests.
Default mapping principle: **1 production file = 1 test file** (when it makes sense).

**🚨 ALWAYS START WITH A DIAGNOSTIC 🚨**

## Hard Rules (must follow)

1. **Top-level `struct` definitions only**
   Any helper types used by tests (including “fake”/“dummy” structs) must be defined at **module top-level** (file scope), not inside a function.
   Rationale: type identity, precompilation, and world-age stability.

2. **Explicit separation: unit vs integration tests**
   In each test file, separate unit and integration tests with clear section comments, e.g.

   - `# ============================================================================`
   - `# UNIT TESTS`
   - `# INTEGRATION TESTS`

3. **Prefer logic/API contract tests over implementation details**
   When possible, validate behaviour through public API contracts using fake structs and minimal dependencies.

## Steps

### 1) Analyse repository structure

```bash
find src/ test/ ext/ -name "*.jl" | sort
grep "^name" Project.toml
```

Store:

- `MODULE_NAME`
- `SRC_FILES[]`
- `EXT_FILES[]`
- `TEST_FILES[]`

### 2) Understand how tests are executed

```bash
head -80 test/runtests.jl
grep -n "test_args\\|ARGS" test/runtests.jl
```

Decide:

- `HAS_TARGETED_TESTS` (can you run a specific group?)
- The canonical naming convention: `test/test_<name>.jl` and `test_<name>()`

### 3) Map source ↔ tests
Classify each source file:

- ✅ **Mapped** (has a corresponding test file)
- ⚠️ **Partial** (exists but missing key behaviour/edge cases)
- ❌ **Missing** (no meaningful test coverage)

### 4) Analyse the production code

```bash
grep -n "^export" -n src/*.jl
grep -n "^function\\|^struct\\|^abstract type" "$source_file"
```

Notes to capture:

- Public API surface (exports)
- Error branches and invariants
- I/O or environment dependencies (files, network, git, time, randomness)
- Stubs (e.g. `ExtensionError`) that should not be tested as behaviour

### 5) Analyse existing tests (if any)

```bash
grep -n "@testset\\|@test" "$test_file"
```

Rate quality:

- 🟢 Strong: deterministic, covers edge cases, clear assertions
- 🟡 OK: covers main path, missing edges
- 🟠 Weak: brittle, unclear intent
- 🔴 Missing: no test or irrelevant assertions

### 6) Produce a short audit report
Create `reports/test-audit-[timestamp].md` including:

- Coverage gaps per source file (P1/P2/P3 priorities)
- Recommendation: unit-only vs integration-needed

**🛑 STOP**: Ask what to do next:

1. Work on the highest priority gap
2. Work on a specific file
3. Cover all missing tests
4. Improve existing tests only
5. Review proposed structure before writing tests

### 7) Optional: baseline coverage

```bash
julia --project=@. -e 'using Pkg; Pkg.test("PKG"; coverage=true); include("test/coverage.jl")'
```

### 8) Design the test strategy (unit vs integration)

**Unit tests**:

- Pure logic, deterministic
- Prefer pure functions and stable error types/messages
- Use fake structs to isolate behaviour

**Integration tests**:

- Exercise multiple components together
- May use temporary directories (`mktempdir`), filesystem interactions, or extension loading

### 9) Fake structs & API contract tests (recommended)

When testing “solve APIs” or similar contracts, prefer fake minimal implementations:

- Define small top-level fake types
- Implement the minimal methods required by the API
- Assert the API routes, default handling, and error paths

Reference example:

[CTSolvers fake-struct API test example](https://raw.githubusercontent.com/control-toolbox/CTSolvers.jl/main/test/ctsolvers/test_ctsolvers_common_solve_api.jl)

### 10) Implement tests (file template)

For each `test/test_<name>.jl`, follow this structure:

- Top-level helper types (`struct`, `abstract type`) and helper functions
- A `function test_<name>()` entrypoint that runs:

  - UNIT TESTS section
  - INTEGRATION TESTS section

### 11) Validate locally
Run only the relevant group when possible:

```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["<group>"])'
```

Then run full suite:

```bash
julia --project=@. -e 'using Pkg; Pkg.test()'
```

### 12) Preview before applying edits
**🛑 STOP - WAIT**:

1. Apply
2. Modify
3. Regenerate
4. Cancel

### 13) Apply edits safely

- Backup edited files
- Ensure tests still compile and run

### 14) Final report
Summarise:

- Files changed
- What behaviours are now covered
- Any remaining gaps (explicit)

## Stop Points

1. After the audit
2. If >20 files would be touched
3. Before applying edits
4. On any failing tests

## Philosophy
Audit first • Contracts over internals • Deterministic tests • Unit/integration separation • Always preview
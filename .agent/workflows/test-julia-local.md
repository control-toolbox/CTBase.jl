---
description: Generation of unit & integration tests in Julia
---

# Julia Unit Test Generation Workflow

**Goal**: Analyse project, identify missing tests, generate/improve tests (1 source = 1 test file).

**🚨 ALWAYS START WITH DIAGNOSTIC 🚨**

## Steps

### 1. Analyse structure
```bash
find src/ test/ -name "*.jl" | sort
grep "^name" Project.toml
```
Store: `MODULE_NAME`, `SRC_FILES[]`, `TEST_FILES[]`

### 2. Understand tests
```bash
head -50 test/runtests.jl
grep -n "test_args\|ARGS" test/runtests.jl
```
Check if targeted tests supported (`HAS_TARGETED_TESTS`)

### 3. Map source ↔ tests
Classify: ✅ Mapped | ⚠️ Partial | ❌ Missing

### 4. Analyse sources
```bash
grep -n "^function\|^struct" "$source_file"
```
Exclude stubs (`ExtensionError`), note exports

### 5. Analyse tests
```bash
grep -n "@testset\|@test" "$test_file"
```
Quality: 🟢|🟡|🟠|🔴. Identify gaps.

### 6. Audit report
Create `reports/test-audit-[timestamp].md`: summary, file analysis, priorities (P1/P2/P3)

**🛑 STOP**: Ask (1) highest priority, (2) specific file, (3) all untested, (4) improve, (5) review

### 6.1 Coverage baseline (optional)
```bash
julia --project=@. -e 'using Pkg; Pkg.test("PKG"; coverage=true); include("test/coverage.jl")'
```

### 7-8. Select target & prepare context
Read source/test files, identify mockable deps (I/O, DB, API)

### 9. Generate tests
Prompt: unit tests (mocks), integration, edge cases. Structure with testsets. UK English.

### 10-11. Validate
Syntax check, quality review

**If issues**: 🛑 STOP

### 12. Preview
**🛑 STOP - WAIT**: (1) Apply, (2) Modify, (3) Regenerate, (4) Cancel

### 13. Apply
Backup, write, syntax check. Restore if error.

### 14. Execute
```bash
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["$GROUP"])'
```

**If failures**: 🛑 STOP - investigate/fix

### 15. Final report
Summary, results, coverage delta if used

## Stop Points
1. After audit 2. >20 files 3. Preview 4. Failures

## Philosophy
Audit first • Prioritise gaps • Quality > Quantity • Always preview • Backups
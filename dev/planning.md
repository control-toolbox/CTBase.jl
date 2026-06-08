# Implementation plan template

A generic template for structuring a development task. Keep plans simple — the goal is
to align with the human before touching code, not to produce a 50-step document.

## When to write a plan

Before any task that:

- touches more than one file,
- changes a public interface, or
- involves a non-obvious design decision.

Write the plan, share it, wait for confirmation before starting.

---

## Template

````markdown
# Plan: <short title>

## What and why
<2-3 sentences: what changes, why now, what it unblocks.>

## Scope
- Files added: …
- Files modified: …
- Files deleted: …
- Public API changes: yes / no (describe if yes)

## Phases

### Phase A — <name>
Steps:
1. …
2. …
Checkpoint:

```bash
# MCP (preferred)
get_test_command test_args=["suite/<group>"]
then generate_report

# Fallback
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/<group>"])' 2>&1 | tee /tmp/<branch>_phaseA.log
grep -E "Error|Fail|Test Summary" /tmp/<branch>_phaseA.log
```

All green before moving on.

### Phase B — <name>

Steps:
1. …
Checkpoint:

```bash
# MCP (preferred)
get_test_command test_args=["suite/<group1>", "suite/<group2>"]
then generate_report

# Final phase only: full suite
julia --project=@. -e 'using Pkg; Pkg.test()' 2>&1 | tee /tmp/<branch>_final.log
grep -E "Error|Fail|Test Summary" /tmp/<branch>_final.log
```

…

## Human checkpoints

- ⛔ Ask before first commit.
- ⛔ Ask before pushing to a shared branch.
- ⛔ Ask before deleting files that were not created in this task.
- ⛔ Ask if a design decision arises that was not in the plan.

## Out of scope

<List things explicitly not done in this task.>
````

---

## Rules for filling in the template

**Phases** — one phase = one coherent unit that can be tested independently. A phase
ends with a test checkpoint. Never skip the checkpoint.

**Test checkpoints** — always use the MCP `get_test_command` tool with `test_args` to
run only the affected test groups, then `generate_report` to parse the result. If MCP
is unavailable, fall back to:

```bash
# Phase-specific (preferred during intermediate phases)
julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/<group>"])' \
  2>&1 | tee /tmp/<branch>_<phase>.log
grep -E "Error|Fail|Test Summary" /tmp/<branch>_<phase>.log

# Full suite (mandatory for the last phase only)
julia --project=@. -e 'using Pkg; Pkg.test()' \
  2>&1 | tee /tmp/<branch>_final.log
grep -E "Error|Fail|Test Summary" /tmp/<branch>_final.log
```

Never run the full suite for intermediate phases — it is too slow and hides errors.

**Steps** — file-level granularity. "Edit `src/X/y.jl` to add method `f`" not "implement
the feature". Concrete enough that a step is either done or not.

**Human checkpoints** — mandatory stops. The human decides whether to commit, push, or
proceed after a design change. The ⛔ symbol marks these explicitly so they are not
missed.

**Docstrings** — always the last step of the last phase, once the API is stable.

**Code snippets** — include short code snippets directly in the plan to guide the
implementer. This applies to:

- *Source changes*: show the before/after signature or struct definition.
- *Call-site updates*: show the exact old and new lines when renaming symbols.
- *Test patterns*: show the test structure (fake type + testset skeleton) when the
  test pattern is non-obvious.
Snippets should be *concise shapes*, not full implementations.

**Out of scope** — explicit. Prevents scope creep and clarifies what the human should
not expect after the plan is executed.

---

## Concrete example structure (abbreviated)

````markdown
# Plan: rename content → dynamics trait

## What and why
Rename AbstractContentTrait and its values to AbstractDynamicsTrait / StateDynamics /
HamiltonianDynamics / AugmentedHamiltonianDynamics. "content" is too neutral; "dynamics"
names the axis. Purely mechanical, no behavior change.

## Scope
- Files modified: src/Traits/content.jl (rename to dynamics.jl), src/Traits/Traits.jl,
  src/Configs/*, src/Solutions/building.jl, docs/api_reference.jl
- Files renamed: test/suite/traits/test_content.jl → test_dynamics.jl
- Public API changes: yes — AbstractContentTrait → AbstractDynamicsTrait (+ values)

## Phases

### Phase A — Rename Traits module
Steps:
1. Rename src/Traits/content.jl → dynamics.jl; update all names inside.
2. Update include path in src/Traits/Traits.jl; update exports.
Checkpoint:

```bash
get_test_command test_args=["suite/traits"]   # MCP
# fallback: julia --project=@. -e 'using Pkg; Pkg.test(; test_args=["suite/traits"])' 2>&1 | tee /tmp/rename_traits.log
```

### Phase B — Adapt consumers (Configs, Solutions)

Steps:

1. Update src/Configs/* (content_trait → dynamics_trait, value names).
2. Update src/Solutions/building.jl.
Checkpoint:

```bash
get_test_command test_args=["suite/configs", "suite/solutions"]   # MCP
```

### Phase C — Tests + docs

Steps:

1. Rename and update test/suite/traits/test_content.jl → test_dynamics.jl.
2. Update docs/api_reference.jl file list.
Checkpoint (full suite — last phase):

```bash
get_test_command   # MCP, no test_args = full suite
# fallback: julia --project=@. -e 'using Pkg; Pkg.test()' 2>&1 | tee /tmp/rename_final.log
```

## Human checkpoints

- ⛔ Ask before commit after Phase C.

## Out of scope

Parametrizing AbstractSystem/AbstractFlow by the dynamics trait (see action_plan.md Phase C/D).
````

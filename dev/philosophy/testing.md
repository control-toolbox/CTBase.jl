# Testing

How tests are structured and written. Generic examples. For *running* tests, see
[`../RULES.md`](../RULES.md).

## Principles

1. **Contract-first** — define and test contracts (interfaces) with fakes/stubs to
   verify routing and behavior. Test public APIs and internal logic that matters.
2. **Orthogonality** — test organization follows *functionality*, not the `src/` layout.
3. **Isolation** — unit tests use fakes; integration tests exercise real boundaries.
4. **Determinism** — reproducible, no external state, no execution-order dependence.
5. **Clarity** — intent obvious from names and structure.

## The file template (module + callable entry + qualified imports)

This is mandatory. Each test file is a **module**; it imports everything **qualified**;
it defines a single entry function `test_<name>()`; and it **redefines that function in
the outer scope** so the test runner can call it.

```julia
# File: test/suite/<group>/test_<name>.jl
module TestName

# Qualified imports — bring module names into scope, call Sub.sym everywhere
import Test
import CTBase.Exceptions: Exceptions
import MyPackage.SubA: SubA
import MyPackage.SubB: SubB

# Test options (verbose / timing), overridable by the runner
const VERBOSE    = isdefined(Main, :TestOptions) ? Main.TestOptions.VERBOSE    : true
const SHOWTIMING = isdefined(Main, :TestOptions) ? Main.TestOptions.SHOWTIMING : true

# TOP-LEVEL fakes (never inside a function — world-age issues otherwise)
struct FakeThing <: SubA.AbstractThing end
SubA.required_method(::FakeThing) = 42

# Single entry function, named exactly like the file
function test_name()
    Test.@testset "Name" verbose=VERBOSE showtiming=SHOWTIMING begin
        Test.@test SubA.required_method(FakeThing()) == 42
    end
end

end # module TestName

# CRITICAL: redefine in the outer scope so the runner can call it
test_name() = TestName.test_name()
```

Why each part:
- **Module wrapper** — isolates names per file; avoids clashes across the suite.
- **Qualified imports** (`import X: X`) — the module name is in scope, call sites read
  `SubA.sym`; same policy as the source (see [`modules.md`](modules.md)).
- **Top-level fakes** — defining a `struct` inside a function triggers world-age errors.
- **Outer redefinition** — the runner discovers and calls `test_name()` at top level.

## Test categories

- **Fake** — minimal struct implementing the required contract methods, to isolate the
  unit under test.
- **Stub** — a default method on an abstract type that throws `NotImplemented` /
  `ExtensionError`; tested by calling it on a fake type.
- **Mock** (interaction-recording) — not used; fakes suffice.

### Unit

Single component in isolation; pure, deterministic, fast (<1ms). Use fakes for
dependencies.

### Integration

Several real module boundaries together; fakes only for leaf dependencies. Slower
(up to ~1s) acceptable.

### Contract

Verify the interface using fakes that implement only the required methods. Check
routing, defaults, and Liskov substitution (generic code works for every subtype).

### Error

Verify stubs and error paths throw the right exception.

- **Interface stub** (`NotImplemented`): a fake that omits a required method triggers
  the abstract type's stub. Safe regardless of loaded extensions.
- **Extension stub** (`ExtensionError` / fallback): **always use a fake type** no
  extension knows about — using a real type makes the test depend on whether another
  test file loaded the extension.

Separate categories with section comments inside one `@testset`.

## Critical rules

1. **Structs at module top-level** — never inside test functions.
2. **Qualified calls, omit the root for submodules** — `Test.@test SubA.f(x) isa
   SubB.T` (not the fully-root-qualified, over-verbose form; not unqualified).
3. **Export verification** — assert submodule exports exist and that the package
   top-level re-exports nothing it shouldn't.
4. **Test internal `_` functions** when logic is complex/branchy; otherwise cover them
   indirectly.
5. **Independence** — fresh instances per testset; no shared mutable/global state; no
   order dependence.

## Quality

- Specific assertions (`≈ … atol=…`, `isa T`, `== n`), not `> 0` or `!= nothing`.
- Names describe *what* is tested, not *how*.
- Type-stability tests with `@inferred` on **function calls** (not field access);
  allocation tests with `@allocated` for hot paths.

```julia
Test.@test_nowarn Test.@inferred SubA.accessor(obj)   # ✅ a call
# Test.@inferred obj.field                              # ❌ field access
Test.@test (Test.@allocated SubA.accessor(obj)) == 0
```

## Checklist

- [ ] File is a module; entry `test_<name>()`; redefined in the outer scope.
- [ ] All imports qualified; all calls qualified (root omitted for submodules).
- [ ] Fakes/stubs defined at module top-level.
- [ ] Categories present and separated (unit / integration / contract / error).
- [ ] Error paths use `@test_throws`; extension stubs use fake types.
- [ ] Each test independent and deterministic; specific assertions; descriptive names.

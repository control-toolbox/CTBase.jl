# Types, traits, interfaces

How we model variation: abstract types for *nouns*, trait-parameters for *adjectives*,
dispatch via trait extraction. Generic examples.

## The guiding rule

> **One abstract type per real *noun*. One trait-parameter per orthogonal *axis*.**
> Concrete types are reserved for genuinely different data layouts.

- **Abstract type** — good for a *noun* ("what is it"), `is-a` relations, shared
  methods. But: single inheritance only → combinatorial explosion across several
  orthogonal axes.
- **Trait (as a type parameter)** — good for an *adjective / capability*. Composes
  freely, dispatched via an extractor.

## Traits as type parameters

A trait is a singleton type under a shared abstract trait. It is carried as a type
parameter and read back with an extractor.

```julia
abstract type AbstractMode <: AbstractTrait end
struct Eager <: AbstractMode end
struct Lazy  <: AbstractMode end

# The trait is a parameter of the noun's abstract type
abstract type AbstractThing{M<:AbstractMode} end

# Extractor: returns a type known at compile time
mode(::AbstractThing{M}) where {M} = M

# Aliases give back the readable per-variant names for dispatch
const AbstractEagerThing = AbstractThing{Eager}
const AbstractLazyThing  = AbstractThing{Lazy}
```

Adding an axis is adding a parameter, not multiplying the type tree.

## When an axis becomes a type parameter (vs. stays an extracted trait)

The criterion is not "is this axis important?" but:

> **Does the axis change the contract visible to consumers of the abstract type?**
> If yes → type parameter. If no → extracted trait only.

- An axis that changes the **method signatures** the abstract type promises (e.g. number
  or role of arguments) is structural: it propagates up through the hierarchy and belongs
  as a type parameter.
- An axis that only affects **how** a computation is performed *inside* a concrete type,
  while both variants honour the same abstract contract, stays as an extracted trait on
  the concrete type.

A practical signal: **if an axis never propagates beyond one level of the hierarchy** —
present on concrete types but absent from abstract types and their consumers — it is most
likely an implementation detail, not a structural axis.

## Dispatch via the trait (Holy trait pattern)

Extract the trait, then re-dispatch on it:

```julia
function process(x::AbstractThing)
    return _process(mode(x), x)        # extract, then re-dispatch
end

_process(::Type{Eager}, x) = ...       # eager branch
_process(::Type{Lazy},  x) = ...       # lazy branch
```

This is **type-stable** when the trait is a type parameter: `mode(x)` is known at
compile time, so the re-dispatch resolves statically; the extra call is inlined.

⚠️ Pitfall: extracting a trait from a *runtime value* (not encoded in the type) makes
the re-dispatch dynamic and breaks inference. Keep traits as type parameters.

## Interfaces and contracts

Define methods on abstract types; mark required ones with a `NotImplemented` stub so a
subtype that forgets them fails loudly.

```julia
abstract type AbstractModel end

"""Contract: every model implements `evaluate`."""
function evaluate(m::AbstractModel, x)
    throw(Exceptions.NotImplemented(
        "evaluate not implemented";
        required_method = "evaluate(::$(typeof(m)), x)",
        suggestion      = "Define evaluate for your concrete model type",
        context         = "AbstractModel contract",
    ))
end

# Generic code works with any subtype (LSP)
function optimize(m::AbstractModel, x0)
    v = evaluate(m, x0)   # safe for any model honoring the contract
    # ...
end
```

Rules:
- **Accept abstractions** in signatures (`build(::AbstractInput)`), not concrete types,
  so users can extend without editing core code (OCP/DIP).
- **Subtypes honor the contract** (LSP): same return shape across the hierarchy; test
  generic code against all subtypes.
- **Do not add an abstract type for a capability.** A capability (e.g. "supports AD")
  is a *trait*, not a node in the hierarchy — adding `AbstractThingWithAD` collides with
  the other axes under single inheritance.

## When concrete types are justified

Use a concrete type when the *data layout* genuinely differs (different fields), not to
encode an adjective. Two concrete types with identical fields that differ only by a flag
should be one parametric type with a trait parameter + aliases.

## SOLID / DRY / KISS / YAGNI (condensed)

- **SRP** — one responsibility per module/function/type. Red flags: names with "and",
  functions > ~50 lines, branches handling unrelated concerns.
- **OCP** — extend via new subtypes + dispatch, not by editing `isa`/`typeof` chains.
- **LSP** — subtypes substitutable; consistent return types.
- **ISP** — small focused interfaces; don't force unused methods on a type.
- **DIP** — depend on abstract types; inject dependencies.
- **DRY** — one representation per piece of knowledge; extract shared validation.
- **KISS** — the simplest thing that works.
- **YAGNI** — no speculative fields/features.

Anti-patterns to avoid: God object, primitive obsession (use domain types), feature
envy (put the method where the data is).

## Type stability {#type-stability}

Type-stable = return type inferable from input types at compile time. Typically
10–100× faster than unstable code.

- **Parametric, concrete fields** — `struct C{T}; data::Vector{T}; end`, never
  `Vector{Any}` or an abstract field type.
- **`NamedTuple` over `Dict`** for fixed-key, mixed-type records.
- **No `Any` in hot paths**; avoid conditional return types
  (`Union{Int,Nothing}` from one function).
- **Function barriers** — isolate an unavoidable instability behind a typed inner
  function.
- **`const Ref(...)`** instead of mutable globals.

Verify:

```julia
@testset "type stability" begin
    @test_nowarn @inferred f(x)      # @inferred only on function calls, not field access
    @test (@allocated hot_path(x)) == 0
end
```

Type stability matters on critical paths (inner loops, numerics); it is secondary on
one-time setup, user-facing API, and error paths.

## Checklist

- [ ] One abstract type per noun; one trait-parameter per orthogonal axis.
- [ ] Trait extractor + alias per variant; dispatch via extracted trait.
- [ ] Contracts are `NotImplemented` stubs on abstract types.
- [ ] Signatures accept abstractions; subtypes honor the contract.
- [ ] No abstract type encoding a capability (use a trait).
- [ ] Concrete types only for genuinely different data layouts.
- [ ] Parametric concrete fields; no `Any` in hot paths; `@inferred` on critical calls.

# Docstrings

Every exported symbol *and* every internal component carries a docstring. Generic
templates below; use `DocStringExtensions` macros for signatures.

## Principles

1. **Completeness** — document every function, struct, abstract type, macro, module.
2. **Accuracy** — describe actual behavior, never aspirational.
3. **Clarity** — for readers fluent in Julia but new to the domain.
4. **Consistency** — follow the templates.

Placement: **immediately above** the declaration, no blank line in between.

## Required structure

1. Signature via `$(TYPEDSIGNATURES)` (functions) or `$(TYPEDEF)` (types).
2. One-sentence summary.
3. Optional detail: behavior, constraints, invariants, edge cases.
4. Sections as applicable: `# Arguments`, `# Fields`, `# Returns`, `# Throws`,
   `# Example(s)`, `# Notes`, `# References`, and a `See also:` line.

## Templates (generic)

### Function

```julia
"""
$(TYPEDSIGNATURES)

One sentence describing what the function does.

# Arguments
- `a::TypeA`: description.
- `b::TypeB`: description.

# Returns
- `RetType`: description.

# Throws
- `ExceptionType`: when and why.

# Example
\`\`\`julia-repl
julia> using MyPackage.SubA

julia> do_thing(a, b)
expected_output
\`\`\`

See also: [`MyPackage.SubA.related`](@ref), [`MyPackage.SubB.Other`](@ref)
"""
function do_thing(a::TypeA, b::TypeB)::RetType
    # ...
end
```

### Struct

```julia
"""
$(TYPEDEF)

One sentence describing what this type represents.

# Fields
- `field1::Type1`: description and constraints.
- `field2::Type2`: description and constraints.

See also: [`MyPackage.SubA.related_type`](@ref)
"""
struct Thing{T}
    field1::Type1
    field2::T
end
```

### Abstract type

```julia
"""
$(TYPEDEF)

One sentence describing the abstraction.

# Interface Requirements

Subtypes must implement:
- `required_method(::SubType)`: description.

See also: [`MyPackage.SubA.ConcreteA`](@ref), [`MyPackage.SubA.ConcreteB`](@ref)
"""
abstract type AbstractThing end
```

## Cross-references

- **Internal** (`@ref`): full module path including the root package.
  `[`MyPackage.SubA.do_thing`](@ref)` — not `[`do_thing`](@ref)`.
- **External** (`@extref`): symbols from a dependency with its own docs, full path.
  `[`OtherPkg.Sub.Sym`](@extref)`. Each must be backed by an `InterLinks` entry in
  `make.jl`.

Use `@ref` for symbols documented in the current package, `@extref` for dependencies.

## Module-prefix convention in examples

- Exported symbol after `using MyPackage.SubA`: call it bare (`do_thing(...)`).
- Internal symbol: prefix with the submodule (`SubA.helper(...)`).
- Public path shown in docs is always `RootPackage.SubModule.symbol`.

## Example safety

Examples must be safe and reproducible.

- ✅ pure deterministic computations, constructors with simple inputs, queries on
  created objects; start with `using RootPackage.SubModule`.
- ❌ file/network/DB/git operations, randomness without a seed, timing-dependent or
  long-running (>1s) code, reliance on external/global state.
- If no safe runnable example exists: use a plain ```julia block (not ```julia-repl)
  showing a conceptual usage pattern without claiming output.

## Macros

- `$(TYPEDEF)` — type signature for structs/abstract types.
- `$(TYPEDSIGNATURES)` — function signature with types.

Use these instead of writing signatures by hand.

## Checklist

- [ ] Directly above the declaration; uses `$(TYPEDEF)`/`$(TYPEDSIGNATURES)`.
- [ ] One-sentence summary; all args/fields documented; returns and throws when relevant.
- [ ] Example is safe, runnable, and typical.
- [ ] `@ref` for internal, `@extref` for external; full module paths.
- [ ] No invented behavior; consistent terminology.

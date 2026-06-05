# Modules and qualification

Submodule organization and import rules. Generic examples.

## Principles

1. **One submodule per responsibility**, in its own directory `src/<Name>/<Name>.jl`.
2. **Package manifest exports nothing**: the top-level file only `include`s the
   submodules and `using .Submodule`; it **exports nothing**.
3. **Each submodule exports its public API**; internal helpers stay unexported and are
   reached via full qualification.
4. **Qualified external imports**: `using Pkg: Pkg` or `import Pkg.Sub`, never a bare
   `using Pkg`.
5. **Qualification everywhere**: call `Sub.function` / `Sub.Type`, never rely on
   implicit scope.
6. **One-way dependency flow (DAG)**: a low module never depends on a high one; no
   cycles.

## The submodule manifest

Canonical structure of `src/<Name>/<Name>.jl`:

```julia
"""
Module docstring — role, responsibilities, dependencies.
"""
module Name

# 1. External-package imports (qualified)
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES   # macros: symbol import tolerated
import CTBase.Exceptions                                # qualifies Exceptions.*
using SomePackage: SomePackage                          # call SomePackage.*

# 2. Sibling-submodule imports
using ..Lower
import ..Other as OtherAlias
using ..Core: AbstractTag                               # pervasive symbol only

# 3. Includes (internal dependency order)
include(joinpath(@__DIR__, "abstract_types.jl"))
include(joinpath(@__DIR__, "concrete.jl"))

# 4. Exports — public API only
export AbstractThing, Thing
export build_thing

end # module Name
```

Order: docstring → `module` → external imports → sibling imports → `include`s →
`export`s → `end`.

## Import styles (by preference)

```julia
using SomePackage: SomePackage   # ✅ preferred: only the name enters scope
import CTBase.Exceptions         # ✅ qualifies the submodule
import DocStringExtensions: TYPEDEF, TYPEDSIGNATURES  # ✅ reserved for macros / pervasive symbols
```

Forbidden:

```julia
using SomePackage                       # ❌ pollutes scope
using CTBase: AbstractModel, validate   # ❌ opaque origin at call sites
```

## Sibling imports

```julia
using ..Lower                # call Lower.f(...)
import ..Core as CTCore      # alias on conflict or for readability
using ..Core: AbstractTag    # single pervasive symbol (often an abstract type)
```

## Qualification at call sites

```julia
# ✅ explicit origin at every call
function Strategies.metadata(::Type{<:Modelers.ADNLP})
    return Strategies.StrategyMetadata(
        Strategies.OptionDefinition(name=:backend, type=Symbol, default=:auto),
    )
end

# ❌ where do StrategyMetadata, OptionDefinition come from?
function metadata(::Type{<:ADNLP})
    return StrategyMetadata(OptionDefinition(name=:backend, type=Symbol))
end
```

Why: visible origin, safe refactors (only the `using ..X` line changes), no accidental
shadowing, same rule for external and sibling symbols.

## Two-level exports

- **Submodule**: `export` for its public API; internals (`_helper`) unexported.
- **Package (top-level)**: **no** `export`. Load submodules with `using .Submodule`;
  users reach them via `Package.Submodule.sym`.

```julia
module MyPackage
include(joinpath(@__DIR__, "Core", "Core.jl"));       using .Core
include(joinpath(@__DIR__, "Systems", "Systems.jl")); using .Systems
# NO exports here.
end
```

User access:

```julia
using MyPackage                  # brings no symbols into scope
MyPackage.Systems.AbstractThing  # qualified (recommended)

using MyPackage.Systems          # opt-in: brings Systems exports into scope
AbstractThing                    # unqualified, the user's choice
```

## Dependency DAG

The loading order in the top-level manifest follows a topological sort. A module may
`using ..Lower` only if `Lower` is already loaded. **No cycles**: if two modules need
each other, extract the shared concept into a lower module (`Core`).

## Checklist

- [ ] One submodule = one directory + one same-named manifest.
- [ ] Manifest = docstring, `module`, imports, `include`s, `export`s, `end` — nothing else.
- [ ] External imports: `using Pkg: Pkg` / `import Pkg.Sub` / (macros) `import Pkg: m`.
- [ ] Sibling imports: `using ..Sib` / `import ..Sib as A` / `using ..Sib: Sym`.
- [ ] Every external/sibling symbol is qualified at the call site.
- [ ] Acyclic DAG respected by the loading order.
- [ ] Each submodule exports its API; the package top-level exports nothing.

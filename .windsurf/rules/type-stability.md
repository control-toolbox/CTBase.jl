---
trigger: performance_critical
---

# Julia Type Stability Standards

## 🤖 **Agent Directive**

**When applying this rule, explicitly state**: "🔧 **Applying Type Stability Rule**: [specific type stability principle being applied]"

This ensures transparency about which type stability standard is being used and why.

---

This document defines type stability standards for the Control Toolbox project. Type stability is crucial for Julia performance and must be carefully considered in performance-critical code paths.only when it can infer types at compile time.

## Core Principles

1. **Type Inference**: The compiler must be able to determine return types from input types
2. **Performance**: Type-stable code is typically 10-100x faster than type-unstable code
3. **Testability**: Type stability must be verified with `@inferred` tests
4. **Clarity**: Type-stable code is often clearer and more maintainable

## What is Type Stability?

A function is **type-stable** if the type of its return value can be inferred from the types of its inputs at compile time.

### Type-Stable Example

```julia
# ✅ Type-stable: return type is always Int
function get_dimension(ocp::OptimalControlProblem)::Int
    return ocp.state_dimension
end

# Compiler knows: Int → Int
```

### Type-Unstable Example

```julia
# ❌ Type-unstable: return type depends on runtime value
function get_value(dict::Dict{Symbol, Any}, key::Symbol)
    return dict[key]  # Could be Int, Float64, String, anything!
end

# Compiler doesn't know: Dict{Symbol, Any} → ???
```

## Testing Type Stability

### Using `@inferred`

The `@inferred` macro from `Test.jl` verifies that a function call is type-stable:

```julia
using Test

@testset "Type Stability" begin
    ocp = create_test_ocp()
    
    # ✅ Test function calls
    @test_nowarn @inferred get_dimension(ocp)
    @test_nowarn @inferred state_dimension(ocp)
    
    # Test with different input types
    @test_nowarn @inferred process_constraint(ocp, :initial)
    @test_nowarn @inferred process_constraint(ocp, :final)
end
```

### Common Mistake: Testing Non-Functions

```julia
# ❌ WRONG: @inferred on field access
@testset "Type Stability" begin
    ocp = create_test_ocp()
    @inferred ocp.state_dimension  # ERROR: Not a function call!
end

# ✅ CORRECT: Wrap in a function
function get_state_dim(ocp)
    return ocp.state_dimension
end

@testset "Type Stability" begin
    ocp = create_test_ocp()
    @inferred get_state_dim(ocp)  # ✅ Function call
end
```

### Using `@code_warntype`

For debugging type instabilities, use `@code_warntype`:

```julia
julia> @code_warntype get_value(dict, :key)
Variables
  #self#::Core.Const(get_value)
  dict::Dict{Symbol, Any}
  key::Symbol

Body::Any  # ⚠️ RED FLAG: Return type is Any!
1 ─ %1 = Base.getindex(dict, key)::Any
└──      return %1
```

**What to look for:**
- Red `Any` or `Union{...}` in return type
- Yellow warnings about type instabilities
- Multiple possible return types

## Type-Stable Structures

### Use Parametric Types

**❌ Type-Unstable:**

```julia
struct OptionDefinition
    name::Symbol
    type::Type
    default::Any  # ⚠️ Type-unstable!
end

# Problem: default could be anything
function get_default(opt::OptionDefinition)
    return opt.default  # Return type: Any
end
```

**✅ Type-Stable:**

```julia
struct OptionDefinition{T}
    name::Symbol
    type::Type{T}
    default::T  # ✅ Type-stable!
end

# Compiler knows the type
function get_default(opt::OptionDefinition{T}) where T
    return opt.default  # Return type: T
end
```

### Use NamedTuple Instead of Dict

**❌ Type-Unstable:**

```julia
struct StrategyMetadata
    specs::Dict{Symbol, OptionDefinition}  # ⚠️ Values have unknown types
end

function get_max_iter(meta::StrategyMetadata)
    return meta.specs[:max_iter].default  # Return type: Any
end
```

**✅ Type-Stable:**

```julia
struct StrategyMetadata{NT <: NamedTuple}
    specs::NT  # ✅ Type-stable with known keys
end

function get_max_iter(meta::StrategyMetadata)
    return meta.specs.max_iter  # Return type: inferred from NT
end
```

### Avoid Abstract Types in Structs

**❌ Type-Unstable:**

```julia
struct Container
    items::Vector{Number}  # ⚠️ Abstract type!
end

function sum_items(c::Container)
    return sum(c.items)  # Type-unstable iteration
end
```

**✅ Type-Stable:**

```julia
struct Container{T <: Number}
    items::Vector{T}  # ✅ Concrete type parameter
end

function sum_items(c::Container{T}) where T
    return sum(c.items)  # Type-stable iteration
end
```

## Common Type Instabilities

### 1. Untyped Containers

```julia
# ❌ Type-unstable
function process_data()
    results = []  # Vector{Any}
    for i in 1:10
        push!(results, i^2)
    end
    return results
end

# ✅ Type-stable
function process_data()
    results = Int[]  # Vector{Int}
    for i in 1:10
        push!(results, i^2)
    end
    return results
end
```

### 2. Conditional Return Types

```julia
# ❌ Type-unstable
function get_value(x::Int)
    if x > 0
        return x  # Int
    else
        return nothing  # Nothing
    end
    # Return type: Union{Int, Nothing}
end

# ✅ Type-stable (if Union is intended)
function get_value(x::Int)::Union{Int, Nothing}
    if x > 0
        return x
    else
        return nothing
    end
end

# ✅ Type-stable (avoid Union)
function get_value(x::Int)::Int
    if x > 0
        return x
    else
        return 0  # Use sentinel value
    end
end
```

### 3. Global Variables

```julia
# ❌ Type-unstable
global_counter = 0

function increment()
    global global_counter
    global_counter += 1  # Type of global_counter can change!
    return global_counter
end

# ✅ Type-stable
const GLOBAL_COUNTER = Ref(0)

function increment()
    GLOBAL_COUNTER[] += 1
    return GLOBAL_COUNTER[]
end
```

### 4. Type-Unstable Fields

```julia
# ❌ Type-unstable
mutable struct Cache
    data::Any  # Could be anything!
end

# ✅ Type-stable
mutable struct Cache{T}
    data::T  # Type is known
end
```

## Performance Testing

### Allocation Tests

Type-stable code typically allocates less memory:

```julia
@testset "Allocations" begin
    ocp = create_test_ocp()
    
    # Test allocation-free operations
    allocs = @allocated state_dimension(ocp)
    @test allocs == 0
    
    # Test bounded allocations
    allocs = @allocated build_model(ocp)
    @test allocs < 1000  # bytes
end
```

### Benchmarking

Use `BenchmarkTools.jl` for precise performance measurements:

```julia
using BenchmarkTools

@testset "Performance" begin
    ocp = create_test_ocp()
    
    # Benchmark critical operations
    b = @benchmark state_dimension($ocp)
    
    @test median(b.times) < 100  # nanoseconds
    @test b.allocs == 0
end
```

## When Type Stability Matters

### Critical Paths ⚠️

Type stability is **essential** for:

- Inner loops (called millions of times)
- Hot paths in solvers
- Numerical computations
- Real-time systems

### Less Critical Paths ✓

Type stability is **less important** for:

- One-time setup code
- User-facing API layers
- Error handling paths
- Debugging utilities

## Fixing Type Instabilities

### Strategy 1: Add Type Annotations

```julia
# Before
function process(x)
    result = []  # Vector{Any}
    # ...
end

# After
function process(x::Vector{Float64})
    result = Float64[]  # Vector{Float64}
    # ...
end
```

### Strategy 2: Use Function Barriers

```julia
# Type-unstable outer function
function outer(data::Dict{Symbol, Any})
    value = data[:key]  # Type-unstable
    return inner(value)  # Function barrier
end

# Type-stable inner function
function inner(value::Int)
    return value^2  # Type-stable
end
```

### Strategy 3: Parametric Types

```julia
# Before
struct Container
    data::Vector{Any}
end

# After
struct Container{T}
    data::Vector{T}
end
```

## Quality Checklist

Before finalizing code, verify:

- [ ] Critical functions tested with `@inferred`
- [ ] No `Any` types in hot paths
- [ ] Parametric types used where appropriate
- [ ] `@code_warntype` shows no red flags
- [ ] Allocation tests pass for critical operations
- [ ] Benchmarks meet performance targets

## Tools and Resources

### Julia Tools

- `@inferred` - Test type stability
- `@code_warntype` - Debug type instabilities
- `@code_typed` - See inferred types
- `@code_llvm` - See generated LLVM code
- `BenchmarkTools.jl` - Precise benchmarking

### External Resources

- [Julia Performance Tips](https://docs.julialang.org/en/v1/manual/performance-tips/)
- [Type Stability](https://docs.julialang.org/en/v1/manual/performance-tips/#Write-%22type-stable%22-functions)
- [Profiling](https://docs.julialang.org/en/v1/manual/profile/)

## Examples from CTModels

### Type-Stable Option Extraction

```julia
# Type-stable with parametric types
struct OptionDefinition{T}
    name::Symbol
    type::Type{T}
    default::T
end

function extract_option(opts::Dict{Symbol, Any}, def::OptionDefinition{T}) where T
    return get(opts, def.name, def.default)::T
end
```

### Type-Stable Strategy Metadata

```julia
# Type-stable with NamedTuple
struct StrategyMetadata{NT <: NamedTuple}
    specs::NT
end

function get_spec(meta::StrategyMetadata, key::Symbol)
    return getfield(meta.specs, key)
end
```

## Summary

**Key Takeaways:**

1. Type stability is crucial for Julia performance
2. Test with `@inferred` for all critical functions
3. Use parametric types and NamedTuple for type-stable structures
4. Avoid `Any` and abstract types in hot paths
5. Use `@code_warntype` to debug instabilities
6. Test allocations for performance-critical code

**Remember:** Type-stable code is faster, clearer, and more maintainable.

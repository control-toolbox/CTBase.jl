---
trigger: model_decision
---

# Julia Architecture and Design Principles

## 🤖 **Agent Directive**

**When applying this rule, explicitly state**: "📋 **Applying Architecture Rule**: [specific principle being applied]"

This ensures transparency about which architectural principle is being used and why.

---

This document defines architecture and design principles for Julia code. These principles ensure code is maintainable, extensible, and follows best practices.

## Core Principles

1. **Single Responsibility**: Each module, function, and type has one clear purpose
2. **Open/Closed**: Open for extension, closed for modification
3. **Liskov Substitution**: Subtypes must honor parent contracts
4. **Interface Segregation**: Keep interfaces small and focused
5. **Dependency Inversion**: Depend on abstractions, not concrete implementations

## SOLID Principles in Julia

### Single Responsibility Principle (SRP)

Every module, function, and type should have a single, well-defined responsibility.

**✅ Good - Focused responsibilities:**

```julia
# Parsing responsibility
function parse_ocp_input(text::String)
    return parsed_data
end

# Validation responsibility
function validate_ocp_data(data)
    return is_valid, errors
end

# Processing responsibility
function solve_ocp(data)
    return solution
end
```

**❌ Bad - Too many responsibilities:**

```julia
function handle_ocp(text::String)
    parsed = parse(text)           # Parsing
    validate(parsed)               # Validation
    solution = solve(parsed)       # Processing
    save_to_file(solution, "out")  # I/O
    return format_output(solution) # Formatting
end
```

**Red flags:**
- Function names with "and" or "or"
- Functions longer than 50 lines
- Multiple `if-else` branches handling different concerns
- Modules mixing unrelated functionality

### Open/Closed Principle (OCP)

Software should be open for extension but closed for modification.

**✅ Good - Extensible via abstract types:**

```julia
# Define abstract interface
abstract type AbstractOptimizationProblem end

# Existing implementation
struct LinearProblem <: AbstractOptimizationProblem
    A::Matrix
    b::Vector
end

# Solver works with any AbstractOptimizationProblem
function solve(problem::AbstractOptimizationProblem)
    # Generic solving logic
end

# NEW: Extend without modifying existing code
struct NonlinearProblem <: AbstractOptimizationProblem
    f::Function
    x0::Vector
end
# Solver automatically works via multiple dispatch
```

**❌ Bad - Hard-coded type checks:**

```julia
function solve(problem)
    if problem isa LinearProblem
        # Linear solving
    elseif problem isa NonlinearProblem
        # Nonlinear solving
    # Need to modify for every new type!
    end
end
```

**How to apply:**
- Use abstract types to define interfaces
- Leverage multiple dispatch for extensibility
- Avoid type checking with `isa` or `typeof`
- Design type hierarchies that allow new subtypes

### Liskov Substitution Principle (LSP)

Subtypes must be substitutable for their parent types without breaking functionality.

**✅ Good - Consistent interface:**

```julia
abstract type AbstractModel end

# Contract: all models must implement `evaluate`
function evaluate(model::AbstractModel, x)
    throw(NotImplemented("evaluate not implemented for $(typeof(model))"))
end

# Subtype honors contract
struct LinearModel <: AbstractModel
    coeffs::Vector
end

function evaluate(model::LinearModel, x)
    return dot(model.coeffs, x)  # Returns a number
end

# Generic code works with any AbstractModel
function optimize(model::AbstractModel, x0)
    value = evaluate(model, x0)  # Safe for any model
    # ...
end
```

**❌ Bad - Subtype breaks contract:**

```julia
struct BrokenModel <: AbstractModel
    data::String
end

function evaluate(model::BrokenModel, x)
    return "error: invalid"  # Returns String, not number!
end

# This breaks unexpectedly
function optimize(model::AbstractModel, x0)
    value = evaluate(model, x0)
    gradient = value * 2  # ERROR if value is String!
end
```

**How to apply:**
- Define clear contracts for abstract types (via docstrings)
- Ensure all subtypes implement required methods consistently
- Return types should be compatible across hierarchy
- Test that generic code works with all subtypes

**Testing LSP:**

```julia
@testset "Liskov Substitution" begin
    # Test that all subtypes work with generic code
    for ModelType in [LinearModel, QuadraticModel, CustomModel]
        model = ModelType(test_params...)
        @test evaluate(model, x) isa Number
        @test optimize(model, x0) isa Solution
    end
end
```

### Interface Segregation Principle (ISP)

Keep interfaces small and focused. Don't force clients to depend on methods they don't use.

**✅ Good - Small, focused interfaces:**

```julia
# Separate capabilities
abstract type Evaluable end
abstract type Differentiable end

# Types implement only what they need
struct SimpleFunction <: Evaluable
    f::Function
end

struct SmoothFunction <: Union{Evaluable, Differentiable}
    f::Function
    df::Function
end

# Clients depend only on what they need
function plot_function(f::Evaluable, xs)
    return [evaluate(f, x) for x in xs]
end

function optimize(f::Differentiable, x0)
    return gradient_descent(f, x0)
end
```

**❌ Bad - Bloated interface:**

```julia
# Forces all types to implement everything
abstract type MathFunction end

# Required methods (even if not needed):
evaluate(f::MathFunction, x) = error("not implemented")
gradient(f::MathFunction, x) = error("not implemented")
hessian(f::MathFunction, x) = error("not implemented")
integrate(f::MathFunction, a, b) = error("not implemented")

# Simple function forced to implement everything
struct SimpleFunction <: MathFunction
    f::Function
end

evaluate(sf::SimpleFunction, x) = sf.f(x)
gradient(sf::SimpleFunction, x) = error("not differentiable")  # Forced!
hessian(sf::SimpleFunction, x) = error("not differentiable")   # Forced!
integrate(sf::SimpleFunction, a, b) = error("not integrable")  # Forced!
```

**How to apply:**
- Create small, focused abstract types
- Use `Union` types for multiple interfaces
- Don't force implementations of unused methods
- Export only necessary functions

### Dependency Inversion Principle (DIP)

Depend on abstractions, not concrete implementations.

**✅ Good - Depend on abstractions:**

```julia
# High-level abstraction
abstract type DataStore end

# High-level module depends on abstraction
struct DataProcessor
    store::DataStore  # Abstract type
end

function process(dp::DataProcessor, data)
    save(dp.store, data)  # Works with any DataStore
end

# Low-level implementations
struct FileStore <: DataStore
    path::String
end

struct DatabaseStore <: DataStore
    connection::DBConnection
end

# Easy to swap implementations
processor1 = DataProcessor(FileStore("data.txt"))
processor2 = DataProcessor(DatabaseStore(conn))
```

**❌ Bad - Depend on concrete types:**

```julia
# Tightly coupled to file system
struct DataProcessor
    file_path::String
end

function process(dp::DataProcessor, data)
    write(dp.file_path, data)  # Hard-coded to files
end

# Can't switch to database without modifying DataProcessor
```

**How to apply:**
- Define abstract types for dependencies
- Pass abstract types as arguments
- Use dependency injection
- Avoid hard-coding concrete types

## Other Design Principles

### DRY - Don't Repeat Yourself

Avoid code duplication. Every piece of knowledge should have a single representation.

**✅ Good - Extract common logic:**

```julia
function validate_positive(x, name)
    x > 0 || throw(IncorrectArgument("$name must be positive"))
end

function create_model(n::Int, m::Int)
    validate_positive(n, "n")
    validate_positive(m, "m")
    return Model(n, m)
end
```

**❌ Bad - Duplicated validation:**

```julia
function create_model(n::Int, m::Int)
    n > 0 || throw(ArgumentError("n must be positive"))
    m > 0 || throw(ArgumentError("m must be positive"))
    return Model(n, m)
end

function create_problem(n::Int, m::Int)
    n > 0 || throw(ArgumentError("n must be positive"))  # Duplicated!
    m > 0 || throw(ArgumentError("m must be positive"))  # Duplicated!
    return Problem(n, m)
end
```

### KISS - Keep It Simple, Stupid

Prefer simple solutions over complex ones. Avoid over-engineering.

**✅ Good - Simple and clear:**

```julia
function compute_mean(xs)
    return sum(xs) / length(xs)
end
```

**❌ Bad - Over-engineered:**

```julia
function compute_mean(xs)
    accumulator = zero(eltype(xs))
    counter = 0
    for x in xs
        accumulator = accumulator + x
        counter = counter + 1
    end
    return accumulator / counter
end
```

### YAGNI - You Aren't Gonna Need It

Don't add functionality until it's actually needed.

**✅ Good - Implement what's needed:**

```julia
struct Model
    coeffs::Vector{Float64}
end

function evaluate(m::Model, x)
    return dot(m.coeffs, x)
end
```

**❌ Bad - Premature features:**

```julia
struct Model
    coeffs::Vector{Float64}
    cache::Dict{Vector, Float64}        # Not needed yet
    optimization_history::Vector        # Not needed yet
    metadata::Dict{Symbol, Any}         # Not needed yet
    version::String                     # Not needed yet
end
```

## Julia-Specific Patterns

### Multiple Dispatch

Use multiple dispatch for extensibility and clarity:

```julia
# Define behavior for different type combinations
function combine(a::Number, b::Number)
    return a + b
end

function combine(a::Vector, b::Vector)
    return vcat(a, b)
end

function combine(a::String, b::String)
    return a * b
end

# Extensible: add new methods without modifying existing code
```

### Type Hierarchies

Design type hierarchies that reflect conceptual relationships:

```julia
# Clear hierarchy
abstract type AbstractStrategy end
abstract type AbstractDirectMethod <: AbstractStrategy end
abstract type AbstractIndirectMethod <: AbstractStrategy end

struct DirectShooting <: AbstractDirectMethod end
struct DirectCollocation <: AbstractDirectMethod end
struct IndirectShooting <: AbstractIndirectMethod end
```

### Composition Over Inheritance

Prefer composition (has-a) over inheritance (is-a) when appropriate:

```julia
# Composition: Model has a solver
struct OptimizationModel
    problem::AbstractProblem
    solver::AbstractSolver
    options::NamedTuple
end

# Not: OptimizationModel <: AbstractSolver
```

### Parametric Types

Use parametric types for type stability and flexibility:

```julia
# Type-stable with parameters
struct Container{T}
    items::Vector{T}
end

# Flexible: works with any type
c1 = Container([1, 2, 3])        # Container{Int}
c2 = Container([1.0, 2.0, 3.0])  # Container{Float64}
```

## Module Organization

### Layered Architecture

Organize code in layers with clear dependencies:

```
Low-level (Core types, utilities)
    ↓
Mid-level (Business logic, algorithms)
    ↓
High-level (User-facing API, orchestration)
```

**Example:**

```julia
# Low-level: Core types
module Types
    abstract type AbstractProblem end
    struct Problem <: AbstractProblem
        # ...
    end
end

# Mid-level: Algorithms
module Solvers
    using ..Types
    function solve(p::AbstractProblem)
        # ...
    end
end

# High-level: User API
module API
    using ..Types
    using ..Solvers
    export solve, Problem
end
```

### Separation of Concerns

Keep different concerns in separate modules:

```julia
# Validation logic
module Validation
    function validate_dimensions(n, m)
        # ...
    end
end

# Parsing logic
module Parsing
    function parse_input(text)
        # ...
    end
end

# Business logic
module Core
    using ..Validation
    using ..Parsing
    # ...
end
```

## Quality Checklist

Before finalizing code, verify:

- [ ] Each function has a single, clear responsibility
- [ ] Abstract types define clear interfaces
- [ ] Subtypes honor parent contracts (LSP)
- [ ] No hard-coded type checks (`isa`, `typeof`)
- [ ] Dependencies are on abstractions, not concrete types
- [ ] No code duplication (DRY)
- [ ] Solution is as simple as possible (KISS)
- [ ] No premature features (YAGNI)
- [ ] Multiple dispatch used appropriately
- [ ] Type hierarchies reflect conceptual relationships
- [ ] Module organization follows layered architecture

## Common Anti-Patterns

### God Object

**❌ Avoid:** One object that does everything

```julia
struct System
    data::Dict
    config::Dict
    state::Dict
    # 50+ fields
end

# 100+ methods operating on System
```

**✅ Instead:** Split into focused components

```julia
struct DataManager
    data::Dict
end

struct ConfigManager
    config::Dict
end

struct StateManager
    state::Dict
end
```

### Primitive Obsession

**❌ Avoid:** Using primitives instead of domain types

```julia
function create_problem(n::Int, m::Int, t0::Float64, tf::Float64)
    # What do these numbers mean?
end
```

**✅ Instead:** Use domain types

```julia
struct Dimensions
    state::Int
    control::Int
end

struct TimeInterval
    initial::Float64
    final::Float64
end

function create_problem(dims::Dimensions, time::TimeInterval)
    # Clear meaning
end
```

### Feature Envy

**❌ Avoid:** Methods that use more of another type's data

```julia
function compute_cost(model::Model, data::Data)
    # Uses mostly data fields, not model fields
    return data.a * data.b + data.c
end
```

**✅ Instead:** Move method to appropriate type

```julia
function compute_cost(data::Data)
    return data.a * data.b + data.c
end
```

## References

- [Julia Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/)
- [SOLID Principles](https://en.wikipedia.org/wiki/SOLID)
- [Design Patterns in Julia](https://github.com/JuliaLang/julia/blob/master/CONTRIBUTING.md)

## Related Rules

- `.windsurf/rules/docstrings.md` - Documentation standards
- `.windsurf/rules/testing.md` - Testing standards
- `.windsurf/rules/type-stability.md` - Type stability standards

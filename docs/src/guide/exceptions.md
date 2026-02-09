# Error Handling and CTBase Exceptions

CTBase defines a small hierarchy of domain-specific exceptions to make error
handling explicit and consistent across the control-toolbox ecosystem.

All custom exceptions inherit from `CTBase.CTException`:

```julia
abstract type CTBase.CTException <: Exception end
```

## Exception Hierarchy

```text
CTException (abstract)
├── IncorrectArgument      # Input validation errors
├── PreconditionError      # Order of operations, state validation
├── NotImplemented         # Unimplemented interface methods
├── ParsingError           # Parsing errors
├── AmbiguousDescription   # Ambiguous or incorrect descriptions
└── ExtensionError         # Missing optional dependencies
```

## General Error Handling Pattern

You should generally catch exceptions like this:

```julia
try
    # call into CTBase or a package built on top of it
catch e
    if e isa CTBase.CTException
        # handle CTBase domain errors in a uniform way
        @warn "CTBase error" exception=(e, catch_backtrace())
    else
        # non-CTBase error: rethrow so it is not hidden
        rethrow()
    end
end
```

This pattern avoids accidentally swallowing unrelated internal errors while still
giving you a single place to handle all CTBase-specific problems.

## Input Validation Exceptions

### [IncorrectArgument](@id incorrect-argument-tutorial)

```julia
CTBase.IncorrectArgument <: CTBase.CTException
```

**When to use**: Thrown when an individual argument is invalid or violates a constraint.

**Fields**:

- `msg::String`: Error message
- `got::Union{String,Nothing}`: The invalid value received (optional)
- `expected::Union{String,Nothing}`: What was expected (optional)
- `suggestion::Union{String,Nothing}`: How to fix the problem (optional)
- `context::Union{String,Nothing}`: Where the error occurred (optional)

**Examples**:

Adding a duplicate description:

```@repl
using CTBase
algorithms = CTBase.add((), (:a, :b))
CTBase.add(algorithms, (:a, :b))  # Error: duplicate
```

Using invalid indices for the Unicode helpers:

```@repl
using CTBase
CTBase.ctindice(-1)  # Error: must be between 0 and 9
```

**Use this exception** whenever *one input value* is outside the allowed domain
(wrong range, duplicate, empty when it must not be, etc.).

### [AmbiguousDescription](@id ambiguous-description-tutorial)

```julia
CTBase.AmbiguousDescription <: CTBase.CTException
```

**When to use**: Thrown when a description (a tuple of `Symbol`s) cannot be matched to any known
valid description.

**Fields**:

- `description::Description`: The ambiguous description
- `candidates::Union{Vector{String},Nothing}`: Suggested alternatives (optional)
- `suggestion::Union{String,Nothing}`: How to fix the problem (optional)
- `context::Union{String,Nothing}`: Where the error occurred (optional)

**Example**:

```@repl
using CTBase
D = ((:a, :b), (:a, :b, :c), (:b, :c))
CTBase.complete(:f; descriptions=D)  # Error: no match found
```

**Use this exception** when *the high-level choice of description itself* is wrong
or ambiguous and there is no sensible default.

## Precondition and State Exceptions

### [PreconditionError](@id precondition-error-tutorial)

```julia
CTBase.PreconditionError <: CTBase.CTException
```

**When to use**: Thrown when a function is called in the wrong order or when the system is in an invalid state.

**Fields**:

- `msg::String`: Error message
- `reason::Union{String,Nothing}`: Why the precondition failed (optional)
- `suggestion::Union{String,Nothing}`: How to fix the problem (optional)
- `context::Union{String,Nothing}`: Where the error occurred (optional)

**Examples**:

System initialization order:

```julia
function configure!(state::SystemState, config::Dict)
    if !state.initialized
        throw(CTBase.PreconditionError(
            "System must be initialized before configuration",
            reason="initialize! not called yet",
            suggestion="Call initialize!(state) before configure!",
            context="system configuration"
        ))
    end
    # ... configure system ...
end
```

State validation:

```julia
function dynamics!(ocp::PreModel, f::Function)
    if !__is_state_set(ocp)
        throw(CTBase.PreconditionError(
            "State must be set before defining dynamics",
            reason="state has not been defined yet",
            suggestion="Call state!(ocp, dimension) before dynamics!",
            context="dynamics! function"
        ))
    end
    # ... set dynamics ...
end
```

**Use this exception** for:

- Functions called in the wrong order
- Operations on uninitialized objects
- State machine violations
- Workflow step dependencies

**Distinction from `IncorrectArgument`**:

- `IncorrectArgument`: The *value* of an argument is wrong
- `PreconditionError`: The *timing* or *state* is wrong

## Implementation Exceptions

### [NotImplemented](@id not-implemented-tutorial)

```julia
CTBase.NotImplemented <: CTBase.CTException
```

**When to use**: Used to mark interface points that must be implemented by concrete subtypes.

**Fields**:

- `msg::String`: Error message
- `required_method::Union{String,Nothing}`: Method signature that needs implementation (optional)
- `suggestion::Union{String,Nothing}`: How to implement (optional)
- `context::Union{String,Nothing}`: Where the error occurred (optional)

**Example**:

The typical pattern is to provide a method on an abstract type that throws
`NotImplemented`, and then override it in each concrete implementation:

```julia
abstract type MyAbstractAlgorithm end

function run!(algo::MyAbstractAlgorithm, state)
    throw(CTBase.NotImplemented(
        "run! is not implemented for $(typeof(algo))",
        required_method="run!(::$(typeof(algo)), state)",
        suggestion="Implement run! for your algorithm type",
        context="algorithm execution"
    ))
end

# Concrete implementation
struct MyConcreteAlgorithm <: MyAbstractAlgorithm end

function run!(algo::MyConcreteAlgorithm, state)
    # actual implementation
end
```

**Use this exception** when defining *interfaces* and you want an explicit,
typed error rather than a generic `error("TODO")`.

## Parsing and Extension Exceptions

### [ParsingError](@id parsing-error-tutorial)

```julia
CTBase.ParsingError <: CTBase.CTException
```

**When to use**: Intended for errors detected during parsing of input structures or DSLs
(domain-specific languages).

**Fields**:

- `msg::String`: Error message
- `location::Union{String,Nothing}`: Where in the input the error occurred (optional)
- `suggestion::Union{String,Nothing}`: How to fix the syntax (optional)
- `context::Union{String,Nothing}`: What was being parsed (optional)

**Example**:

```@repl
using CTBase
throw(CTBase.ParsingError(
    "unexpected token 'end'",
    location="line 42, column 10",
    suggestion="Check for unmatched 'begin' or remove extra 'end'",
    context="control flow parsing"
))
```

**Use this exception** when parsing user input, configuration files, or DSL expressions.

### [ExtensionError](@id extension-error-tutorial)

```julia
CTBase.ExtensionError <: CTBase.CTException
```

**When to use**: Thrown when a feature requires optional dependencies (weak dependencies) that are not loaded.

**Fields**:

- `msg::String`: Error message
- `weakdeps::Tuple{Vararg{Symbol}}`: Names of missing packages
- `feature::Union{String,Nothing}`: What feature needs the dependencies (optional)
- `context::Union{String,Nothing}`: Where the error occurred (optional)

**Example**:

```julia
function plot_results(data)
    throw(CTBase.ExtensionError(
        :Plots,
        feature="result visualization",
        context="plot_results function"
    ))
end
```

The enriched display automatically suggests:

```text
❌ Error: ExtensionError, missing dependencies
📦 Missing dependencies: Plots
💡 Suggestion: julia> using Plots
```

**Use this exception** when:

- A feature requires optional packages
- Extensions are not loaded
- Weak dependencies are missing

## Quick Reference: Which Exception to Use?

| Situation | Exception | Example |
|-----------|-----------|---------|
| Invalid argument value | `IncorrectArgument` | `throw(IncorrectArgument("x must be > 0", got="-5", expected="> 0"))` |
| Wrong function call order | `PreconditionError` | `throw(PreconditionError("Must initialize before configure"))` |
| Unimplemented interface | `NotImplemented` | `throw(NotImplemented("run! not implemented for MyType"))` |
| Parsing error | `ParsingError` | `throw(ParsingError("unexpected token", location="line 10"))` |
| Ambiguous description | `AmbiguousDescription` | `throw(AmbiguousDescription((:x,), candidates=["(:a,:b)", "(:c,:d)"]))` |
| Missing optional dependency | `ExtensionError` | `throw(ExtensionError(:Plots, feature="plotting"))` |

## Enriched Error Display

All CTBase exceptions provide an enriched, user-friendly display with:

- **🎯 Clear error type and message**
- **📋 Contextual information** (got/expected, reason, location)
- **💡 Actionable suggestions** for fixing the problem
- **📍 User code location** tracking
- **🎨 Emoji-based visual hierarchy**

Example of enriched display:

```text
Control Toolbox Error

❌ Error: PreconditionError, System must be initialized before configuration
❓ Reason: initialize! not called yet
📂 Context: system configuration
💡 Suggestion: Call initialize!(state) before configure!
📍 In your code:
     configure! at MyModule.jl:42
```

This makes debugging faster by providing all the information needed to understand and fix the problem.

## Best Practices

1. **Choose the right exception type**: Use the decision table above
2. **Provide context**: Always fill in optional fields when available
3. **Be specific**: Include actual values in error messages
4. **Suggest solutions**: Help users fix the problem
5. **Catch specifically**: Use `e isa SpecificException` rather than catching all exceptions
6. **Don't hide errors**: Only catch exceptions you can handle

## See Also

- [Descriptions Tutorial](descriptions.md): Understanding the description system
- [Test Runner Guide](test-runner.md): Testing exception handling

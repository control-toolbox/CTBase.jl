---
trigger: error_handling
---

# Julia Exception Standards

## 🤖 **Agent Directive**

**When applying this rule, explicitly state**: "⚠️ **Applying Exception Rule**: [specific exception principle being applied]"

This ensures transparency about which exception standard is being used and why.

---

This document defines the exception handling standards for the Control Toolbox project. All error conditions must be handled using structured, informative exceptions that provide clear guidance to users.

## Core Principles

1. **Clear Messages**: Error messages must be immediately understandable
2. **Actionable Suggestions**: Provide guidance on how to fix the problem
3. **Rich Context**: Include what was expected, what was received, and where
4. **User-Friendly**: Format errors for end users, not just developers

## Exception Types

CTModels provides four enriched exception types in the `Exceptions` module:

### 1. IncorrectArgument

Use when an individual argument is invalid or violates a precondition.

**Fields:**
- `msg::String`: Main error message (required)
- `got::Union{String, Nothing}`: What value was received (optional)
- `expected::Union{String, Nothing}`: What value was expected (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

**Examples:**

```julia
using CTModels.Exceptions

# Simple message
throw(IncorrectArgument("Invalid criterion"))

# With got/expected
throw(IncorrectArgument(
    "Invalid criterion",
    got=":invalid",
    expected=":min or :max"
))

# Full context
throw(IncorrectArgument(
    "Invalid criterion",
    got=":invalid",
    expected=":min or :max",
    suggestion="Use objective!(ocp, :min, ...) or objective!(ocp, :max, ...)",
    context="objective! function"
))
```

**When to use:**
- Invalid function arguments
- Type mismatches
- Value out of range
- Missing required parameters
- Invalid combinations of parameters

### 2. UnauthorizedCall

Use when a function call is not allowed in the current state or context.

**Fields:**
- `msg::String`: Main error message (required)
- `reason::Union{String, Nothing}`: Why the call is unauthorized (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

**Examples:**

```julia
# Simple message
throw(UnauthorizedCall("State already set"))

# With reason and suggestion
throw(UnauthorizedCall(
    "Cannot call state! twice",
    reason="state has already been defined for this OCP",
    suggestion="Create a new OCP instance or use a different component name"
))

# Full context
throw(UnauthorizedCall(
    "Cannot modify frozen OCP",
    reason="OCP has been finalized and is immutable",
    suggestion="Create a new OCP or modify before calling finalize!()",
    context="constraint! function"
))
```

**When to use:**
- State machine violations (e.g., calling methods in wrong order)
- Attempting to modify immutable objects
- Operations not allowed in current context
- Duplicate definitions

### 3. NotImplemented

Use to mark interface points that must be implemented by concrete subtypes.

**Fields:**
- `msg::String`: Description of what is not implemented (required)
- `type_info::Union{String, Nothing}`: Type information (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)
- `context::Union{String, Nothing}`: Where the error occurred (optional)

**Examples:**

```julia
# Simple message
throw(NotImplemented("solve! not implemented for MyStrategy"))

# With type info and suggestion
throw(NotImplemented(
    "Method solve! not implemented",
    type_info="MyStrategy",
    suggestion="Import the relevant package (e.g. CTDirect) or implement solve!(::MyStrategy, ...)"
))

# For abstract type contracts
abstract type AbstractStrategy end

function solve!(strategy::AbstractStrategy, problem)
    throw(NotImplemented(
        "solve! must be implemented for each strategy type",
        type_info=string(typeof(strategy)),
        suggestion="Define solve!(::$(typeof(strategy)), problem)"
    ))
end
```

**When to use:**
- Abstract type interface methods
- Extension points
- Optional features not yet implemented
- Platform-specific functionality

### 4. ParsingError

Use for parsing errors in DSLs or structured input.

**Fields:**
- `msg::String`: Description of the parsing error (required)
- `location::Union{String, Nothing}`: Where in the input the error occurred (optional)
- `suggestion::Union{String, Nothing}`: How to fix the problem (optional)

**Examples:**

```julia
# Simple message
throw(ParsingError("Unexpected token 'end'"))

# With location
throw(ParsingError(
    "Unexpected token 'end'",
    location="line 42, column 15"
))

# With suggestion
throw(ParsingError(
    "Unexpected token 'end'",
    location="line 42, column 15",
    suggestion="Check syntax balance or remove extra 'end'"
))
```

**When to use:**
- DSL parsing errors
- Configuration file parsing
- Input validation during parsing
- Syntax errors

## Best Practices

### Write Clear Messages

**✅ Good - Specific and clear:**

```julia
throw(IncorrectArgument(
    "State dimension must be positive",
    got="n = -1",
    expected="n > 0",
    suggestion="Provide a positive integer for state dimension"
))
```

**❌ Bad - Vague:**

```julia
throw(IncorrectArgument("Invalid input"))
```

### Provide Context

**✅ Good - Includes context:**

```julia
throw(UnauthorizedCall(
    "Cannot call dynamics! twice",
    reason="dynamics has already been defined",
    suggestion="Create a new OCP instance",
    context="dynamics! function"
))
```

**❌ Bad - No context:**

```julia
throw(UnauthorizedCall("Already defined"))
```

### Suggest Solutions

**✅ Good - Actionable suggestion:**

```julia
throw(IncorrectArgument(
    "Unknown constraint type",
    got=":boundary",
    expected=":initial, :final, or :state",
    suggestion="Use constraint!(ocp, :initial, ...) for initial constraints"
))
```

**❌ Bad - No suggestion:**

```julia
throw(IncorrectArgument("Unknown constraint type"))
```

### Use Appropriate Exception Types

**✅ Good - Correct type:**

```julia
# Argument validation
throw(IncorrectArgument("n must be positive", got="n = -1", expected="n > 0"))

# State violation
throw(UnauthorizedCall("Cannot modify frozen OCP", reason="OCP is immutable"))

# Unimplemented interface
throw(NotImplemented("solve! not implemented", type_info="MyStrategy"))
```

**❌ Bad - Wrong type:**

```julia
# Don't use IncorrectArgument for state violations
throw(IncorrectArgument("OCP already finalized"))  # Should be UnauthorizedCall

# Don't use UnauthorizedCall for validation
throw(UnauthorizedCall("n must be positive"))  # Should be IncorrectArgument
```

## Stacktrace Control

CTModels provides user-friendly error display by default. Control stacktrace visibility:

```julia
using CTModels

# User-friendly display (default)
CTModels.set_show_full_stacktrace!(false)

# Full Julia stacktraces (for debugging)
CTModels.set_show_full_stacktrace!(true)

# Check current setting
is_full = CTModels.get_show_full_stacktrace()
```

**User-friendly display shows:**
- Clear error message with emoji
- What was expected vs what was received
- Actionable suggestions
- Relevant context
- Clean, minimal stacktrace

**Full stacktrace shows:**
- Complete Julia stacktrace
- All function calls
- File locations and line numbers
- Useful for debugging

## Testing Exceptions

### Test Exception Types

```julia
using Test
using CTModels.Exceptions

@testset "Exception Types" begin
    # Test that correct exception is thrown
    @test_throws IncorrectArgument invalid_function(bad_arg)
    
    # Test exception message
    err = try
        invalid_function(bad_arg)
    catch e
        e
    end
    @test err isa IncorrectArgument
    @test occursin("Invalid criterion", err.msg)
end
```

### Test Exception Fields

```julia
@testset "Exception Fields" begin
    err = IncorrectArgument(
        "Invalid value",
        got="x",
        expected="y",
        suggestion="Use y instead"
    )
    
    @test err.msg == "Invalid value"
    @test err.got == "x"
    @test err.expected == "y"
    @test err.suggestion == "Use y instead"
end
```

### Test Error Paths

```julia
@testset "Error Cases" begin
    @testset "Invalid Arguments" begin
        @test_throws IncorrectArgument create_model(-1)
        @test_throws IncorrectArgument create_model(0)
    end
    
    @testset "State Violations" begin
        ocp = Model()
        state!(ocp, 2)
        @test_throws UnauthorizedCall state!(ocp, 3)  # Can't call twice
    end
    
    @testset "Unimplemented Methods" begin
        strategy = MyStrategy()
        @test_throws NotImplemented solve!(strategy, problem)
    end
end
```

## Migration from CTBase

If you have existing code using CTBase exceptions:

**Before (CTBase):**

```julia
throw(CTBase.IncorrectArgument("Invalid criterion: :invalid"))
```

**After (CTModels.Exceptions):**

```julia
throw(Exceptions.IncorrectArgument(
    "Invalid criterion",
    got=":invalid",
    expected=":min or :max",
    suggestion="Use objective!(ocp, :min, ...) or objective!(ocp, :max, ...)"
))
```

**Benefits:**
- Richer error information
- User-friendly display
- Actionable suggestions
- Better debugging experience

## Common Patterns

### Validation Pattern

```julia
function validate_dimension(n::Int, name::String)
    if n <= 0
        throw(IncorrectArgument(
            "Dimension must be positive",
            got="$name = $n",
            expected="$name > 0",
            suggestion="Provide a positive integer for $name"
        ))
    end
end

function create_model(state_dim::Int, control_dim::Int)
    validate_dimension(state_dim, "state_dim")
    validate_dimension(control_dim, "control_dim")
    return Model(state_dim, control_dim)
end
```

### State Machine Pattern

```julia
mutable struct OCP
    state_defined::Bool
    dynamics_defined::Bool
end

function state!(ocp::OCP, n::Int)
    if ocp.state_defined
        throw(UnauthorizedCall(
            "Cannot call state! twice",
            reason="state has already been defined for this OCP",
            suggestion="Create a new OCP instance"
        ))
    end
    ocp.state_defined = true
    # ...
end
```

### Interface Pattern

```julia
abstract type AbstractStrategy end

function solve!(strategy::AbstractStrategy, problem)
    throw(NotImplemented(
        "solve! must be implemented for each strategy type",
        type_info=string(typeof(strategy)),
        suggestion="Define solve!(::$(typeof(strategy)), problem) or import the relevant package"
    ))
end
```

## Quality Checklist

Before finalizing exception handling, verify:

- [ ] Exception type is appropriate (IncorrectArgument, UnauthorizedCall, NotImplemented, ParsingError)
- [ ] Error message is clear and specific
- [ ] `got` and `expected` fields provided when applicable
- [ ] Actionable `suggestion` provided
- [ ] `context` provided for complex errors
- [ ] Exception is tested with `@test_throws`
- [ ] Error message is user-friendly (no jargon)
- [ ] Suggestion is concrete and actionable

## Anti-Patterns

### ❌ Generic Errors

```julia
# Bad: Generic error
error("Something went wrong")

# Good: Specific exception
throw(IncorrectArgument("State dimension must be positive", got="n = -1", expected="n > 0"))
```

### ❌ Missing Context

```julia
# Bad: No context
throw(IncorrectArgument("Invalid value"))

# Good: With context
throw(IncorrectArgument(
    "Invalid criterion",
    got=":invalid",
    expected=":min or :max",
    context="objective! function"
))
```

### ❌ No Suggestions

```julia
# Bad: No suggestion
throw(IncorrectArgument("Unknown constraint type", got=":boundary"))

# Good: With suggestion
throw(IncorrectArgument(
    "Unknown constraint type",
    got=":boundary",
    expected=":initial, :final, or :state",
    suggestion="Use constraint!(ocp, :initial, ...) for initial constraints"
))
```

### ❌ Wrong Exception Type

```julia
# Bad: Using IncorrectArgument for state violation
throw(IncorrectArgument("OCP already finalized"))

# Good: Using UnauthorizedCall
throw(UnauthorizedCall(
    "Cannot modify frozen OCP",
    reason="OCP has been finalized",
    suggestion="Create a new OCP or modify before calling finalize!()"
))
```

## References

- `src/Exceptions/Exceptions.jl` - Exception module implementation
- `src/Exceptions/types.jl` - Exception type definitions
- `src/Exceptions/display.jl` - User-friendly display
- `test/suite/exceptions/` - Exception tests

## Related Rules

- `.windsurf/rules/testing.md` - Testing standards (includes exception testing)
- `.windsurf/rules/docstrings.md` - Document exceptions in `# Throws` section
- `.windsurf/rules/architecture.md` - Error handling architecture

"""
$(TYPEDEF)

Abstract supertype for tags used to select a particular implementation of
`run_tests`.

Concrete subtypes identify a specific backend that provides the actual test
runner logic.

# Example

```julia-repl
julia> using CTBase

julia> CTBase.TestRunnerTag() isa CTBase.AbstractTestRunnerTag
true
```

See also: [`CTBase.DevTools.TestRunnerTag`](@ref)
"""
abstract type AbstractTestRunnerTag end

"""
$(TYPEDEF)

Concrete tag type used to dispatch to the `TestRunner` extension.

Instances of this type are passed to `run_tests` to enable the
extension-based test runner when the extension is available.

# Example

```julia-repl
julia> using CTBase

julia> tag = CTBase.TestRunnerTag()
CTBase.TestRunnerTag()
```

See also: [`CTBase.DevTools.AbstractTestRunnerTag`](@ref)
"""
struct TestRunnerTag <: AbstractTestRunnerTag end

"""
$(TYPEDSIGNATURES)

Run the project test suite using an extension-provided test runner.

This is an **extension point**: the default implementation throws an
`CTBase.Exceptions.ExtensionError` unless a backend extension is loaded.

# Keyword Arguments

Forwarded to the active backend implementation.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the test runner extension is not loaded.

# Example

```julia
using CTBase
# run_tests()
```
"""
function run_tests(::AbstractTestRunnerTag; kwargs...)
    throw(
        Exceptions.ExtensionError(
            :Test; feature="test execution and reporting", context="test running"
        ),
    )
end

"""
$(TYPEDSIGNATURES)

Convenience wrapper for `run_tests` using the default backend tag.

# Keyword Arguments

Forwarded to `run_tests(TestRunnerTag(); kwargs...)`.

# Throws

- `CTBase.Exceptions.ExtensionError`: If the test runner extension is not loaded.

# Example

```julia
using CTBase
# run_tests()
```
"""
function run_tests(; kwargs...)
    return run_tests(TestRunnerTag(); kwargs...)
end

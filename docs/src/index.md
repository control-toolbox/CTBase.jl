# CTBase.jl

```@meta
CurrentModule = CTBase
```

The `CTBase.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

It provides the core types, utilities, and infrastructure used by other packages in the ecosystem, such as [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl).

!!! note

    The root package is [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) which aims to provide tools to model and solve optimal control problems with ordinary differential equations by direct and indirect methods, both on CPU and GPU.

## Features and User Guides

CTBase provides several key features to build robust control-toolbox packages:

- **[Descriptions: encoding algorithms](guide/descriptions.md)**: A declarative way to encode algorithms or configurations using tuples of symbols.
- **[Error handling and Exceptions](guide/exceptions.md)**: A domain-specific exception hierarchy for consistent error reporting.
- **[Test Runner](guide/test-runner.md)**: A modular test runner for granular test execution.
- **[Coverage Post-processing](guide/coverage.md)**: Tools to generate readable coverage reports.
- **[API Documentation Generation](guide/api-documentation.md)**: Automated API reference generation from docstrings.

## Note on Private Methods

In some examples in the documentation, private methods are shown without the module
prefix. This is done for the sake of clarity and readability.

```julia-repl
julia> using CTBase
julia> x = 1
julia> private_fun(x) # throws an error
```

This should instead be written as:

```julia-repl
julia> using CTBase
julia> x = 1
julia> CTBase.private_fun(x)
```

If the method is re-exported by another package,

```julia
module OptimalControl
    import CTBase: private_fun
    export private_fun
end
```

then there is no need to prefix it with the original module name:

```julia-repl
julia> using OptimalControl
julia> x = 1
julia> private_fun(x)
```

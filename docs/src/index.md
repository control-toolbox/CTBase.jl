# CTBase.jl

```@meta
CurrentModule = CTBase
```

The `CTBase.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

The root package is [OptimalControl.jl](https://github.com/control-toolbox/OptimalControl.jl) which aims to provide tools to model and solve optimal control problems with ordinary differential equations by direct and indirect methods, both on CPU and GPU.

!!! warning

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

    If the method is re-exported by another package, there is no need to
    prefix it with the original module name:

    ```julia-repl
    julia> module OptimalControl
        import CTBase: private_fun
        export private_fun
    end
    julia> using OptimalControl
    julia> x = 1
    julia> private_fun(x)
    ```

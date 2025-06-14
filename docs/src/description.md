# Description

## Index

```@index
Pages   = ["description.md"]
Modules = [CTBase]
Order = [:module, :constant, :type, :function, :macro]
```

!!! warning

    In the examples in the documentation below, the methods are not prefixed by the module name even if they are private. 

    ```julia-repl
    julia> using CTBase
    julia> x = 1
    julia> private_fun(x) # throw an error
    ```

    must be replaced by

    ```julia-repl
    julia> using CTBase
    julia> x = 1
    julia> CTBase.private_fun(x)
    ```

    However, if the method is reexported by another package, then, there is no need of prefixing.

    ```julia-repl
    julia> module OptimalControl
               import CTBase: private_fun
               export private_fun
           end
    julia> using OptimalControl
    julia> x = 1
    julia> private_fun(x)
    ```

## Documentation

```@autodocs
Modules = [CTBase]
Order = [:module, :constant, :type, :function, :macro]
Pages = ["description.jl"]
```
# CTBase.jl

```@meta
CurrentModule =  CTBase
```

The `CTBase.jl` package is part of the [control-toolbox ecosystem](https://github.com/control-toolbox).

```@raw html
<img src="./assets/diagram.png" style="display: block; margin: 0 auto 20px auto;" width="320px">
```

!!! note "Install"

    To install a package from the control-toolbox ecosystem, 
    please visit the [installation page](https://github.com/control-toolbox#installation).

You may find in this package, some tools to:

- modelise an optimal control problem (see [`OptimalControlModel`](@ref)) from an abstract point of view (see [`@def`](@ref) from [Parser](@ref)) or from a functional point of view (see [Model](@ref)).
- print an optimal control problem: see [Print](@ref).
- plot a solution (see [`OptimalControlSolution`](@ref)) of an optimal control problem: see [Plot](@ref).
- compute [Lie brackets](https://en.wikipedia.org/w/index.php?title=Lie_bracket_of_vector_fields&oldid=1163591634), [Poisson brackets](https://en.wikipedia.org/w/index.php?title=Poisson_manifold&oldid=1163991099#Formal_definition) and some other tools from [differential geometry](https://en.wikipedia.org/w/index.php?title=Differential_geometry&oldid=1165793820): see [Differential geometry](@ref).
- manipulate tuples of symbols: see [Description](@ref).

You may find the [imported modules and exported names](@ref CTBaseModule) but also the different types of [exceptions](@ref api-exceptions) and [functions](@ref api-types) specific to the control-toolbox ecosystem.

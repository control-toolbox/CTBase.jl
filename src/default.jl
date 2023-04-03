"""
$(TYPEDSIGNATURES)

Used to set the default value of the time dependence of the functions.

The default value is `:autonomous`, which means that the functions are considered time independent.
The other possible time dependence is `:nonautonomous`, which means that the functions are considered time dependent.
"""
__fun_time_dependence() = :autonomous

"""
$(TYPEDSIGNATURES)

Used to set the default value of the dimension usage of the functions.

The default value is `:scalar`, which means that the usage of the functions is considered scalar.
The other possible usage is `:vectorial`.

# Example

If `x` is for instance a vector of dimension 2 and `u` a scalar, then the following usage 
is considered scalar:

```jldoctest
f(x, u) = x[1] + u
```

If `x` and `u` are for instance both scalar, then the following usage is considered scalar:

```jldoctest
f(x, u) = x + u
```

If `x` is for instance a vector of dimension 2 and `u` a vector of dimension 3, then the following usage
is also considered scalar:

```jldoctest
f(x, u) = x[1] + u[1]
```

A vectorial usage is the following. For instance, if `x` is a vector of dimension 2 and `u` a scalar, 
then the following usage is considered vectorial:

```jldoctest
f(x, u) = x[1] + u[1]
```
"""
__fun_dimension_usage() = :scalar

"""
$(TYPEDSIGNATURES)

Used to set the default value of the time dependence of the Optimal Control Problem.
The default value is `:autonomous`, which means that the Optimal Control Problem is considered time independent.
The other possible time dependence is `:nonautonomous`, which means that all the functions used to define the 
Optimal Control Problem are considered time dependent.
"""
__ocp_time_dependence() = :autonomous

"""
$(TYPEDSIGNATURES)

Used to set the default value of the dimension usage of the Optimal Control Problem.
The default value is `:scalar`, which means that the usage for all the functions used to define the
Optimal Control Problem is considered scalar.
"""
__ocp_dimension_usage() = :scalar

"""
$(TYPEDSIGNATURES)

Used to set the default value of the names of the states.
The default value is `["x"]` for a one dimensional state, and `["x₁", "x₂", ...]` for a multi dimensional state.
"""
__state_names(n::Dimension) = n==1 ? ["x"] : [ "x" * ctindices(i) for i ∈ range(1, n)]

"""
$(TYPEDSIGNATURES)

Used to set the default value of the names of the controls.
The default value is `["u"]` for a one dimensional control, and `["u₁", "u₂", ...]` for a multi dimensional control.
"""
__control_names(m::Dimension) = m==1 ? ["u"] : [ "u" * ctindices(i) for i ∈ range(1, m)]

"""
$(TYPEDSIGNATURES)

Used to set the default value of the name of the time.
The default value is `t`.
"""
__time_name() = "t"

"""
$(TYPEDSIGNATURES)

Used to set the default value of the type of criterion. Either :min or :max.
The default value is `:min`.
The other possible criterion type is `:max`.
"""
__criterion_type() = :min

"""
$(TYPEDSIGNATURES)

Used to set the default value of the label of a constraint.
A unique value is given to each constraint using the `gensym` function and prefixing by `:unamed`.
"""
__constraint_label() = gensym(:unamed)

"""
$(TYPEDSIGNATURES)

Used to set the default value of the stockage of elements in a matrix.
The default value is `1`.
"""
__matrix_dimension_stock() = 1 

# --------------------------------------------------------------------------------------------------
# Direct shooting method - default values

"""
$(TYPEDSIGNATURES)

Used to set the default value of the grid size for the direct shooting method.
The default value is `201`.
"""
__grid_size_direct_shooting() = 201

"""
$(TYPEDSIGNATURES)

Used to set the default value of the penalty term in front of the final constraint for the direct shooting method.
The default value is `1e4`.
"""
__penalty_constraint() = 1e4

"""
$(TYPEDSIGNATURES)

Used to set the default value of the maximal number of iterations for the direct shooting method.
The default value is `100`.
"""
__iterations() = 100

"""
$(TYPEDSIGNATURES)

Used to set the default value of the absolute tolerance for the stopping criterion for the direct shooting method.
The default value is `10 * eps()`.
"""
__absoluteTolerance() = 10 * eps()

"""
$(TYPEDSIGNATURES)

Used to set the default value of the optimality relative tolerance for the stopping criterion for the direct shooting method.
The default value is `1e-8`.
"""
__optimalityTolerance() = 1e-8

"""
$(TYPEDSIGNATURES)

Used to set the default value of the step stagnation relative tolerance for the stopping criterion for the direct shooting method.
The default value is `1e-8`.
"""
__stagnationTolerance() = 1e-8

"""
$(TYPEDSIGNATURES)

Used to set the default value of the display argument.
The default value is `true`, which means that the output is printed during resolution.
"""
__display() = true

"""
$(TYPEDSIGNATURES)

Used to set the default value of the callbacks argument.
The default value is `()`, which means that no additional callback is given.
"""
__callbacks() = ()

"""
$(TYPEDSIGNATURES)

Used to set the default interpolation function used for initialisation.
The default value is `Interpolations.linear_interpolation`, which means that the initial guess is linearly interpolated.
"""
function __init_interpolation()
    return (T, U) -> Interpolations.linear_interpolation(T, U, extrapolation_bc = Interpolations.Line())
end

# ------------------------------------------------------------------------------------
# Direct method - default values

"""
$(TYPEDSIGNATURES)

Used to set the default value of the grid size for the direct method.
The default value is `100`.
"""
__grid_size_direct() = 100

"""
$(TYPEDSIGNATURES)

Used to set the default value of the print level of ipopt for the direct method.
The default value is `5`.
"""
__print_level_ipopt() = 5

"""
$(TYPEDSIGNATURES)

Used to set the default value of the μ strategy of ipopt for the direct method.
The default value is `adaptive`.
"""
__mu_strategy_ipopt() = "adaptive"
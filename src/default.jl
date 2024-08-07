#
const __default_AD_backend = Ref(AutoForwardDiff())

function set_AD_backend(AD)
    global __default_AD_backend[] = AD
    nothing
end

"""
$(TYPEDSIGNATURES)

Used to set the default value of Automatic Differentiation backend.

The default value is `AutoForwardDiff()`, that is the `ForwardDiff` package is used by default.
"""
__get_AD_backend() = __default_AD_backend[] # default AD backend

"""
$(TYPEDSIGNATURES)

Used to set the default value of the time dependence of the functions.

The default value is `Autonomous`, which means that the functions are considered time independent.
The other possible time dependence is `NonAutonomous`, which means that the functions are considered time dependent.
"""
__fun_time_dependence() = Autonomous

"""
$(TYPEDSIGNATURES)

Used to set the default value of the variable dependence of the functions.

The default value is `Fixed`, which means that the functions are considered variable independent.
The other possible variable dependence is `NonFixed`, which means that the functions are considered variable dependent.
"""
__fun_variable_dependence() = Fixed

"""
$(TYPEDSIGNATURES)

Used to set the default value of the time dependence of the Optimal Control Problem.
The default value is `Autonomous`, which means that the Optimal Control Problem is considered time independent.
The other possible time dependence is `NonAutonomous`, which means that all the functions used to define the 
Optimal Control Problem are considered time dependent.
"""
__ocp_time_dependence() = Autonomous

"""
$(TYPEDSIGNATURES)

Used to set the default value of the variable dependence of the Optimal Control Problem.
The default value is `Fixed`, which means that the Optimal Control Problem is considered variable independent.
The other possible variable dependence is `NonFixed`, which means that all the functions used to define the
Optimal Control Problem are considered variable dependent.
"""
__ocp_variable_dependence() = Fixed

"""
$(TYPEDSIGNATURES)

Used to set the default value of the names of the variables.
The default value is `"v"`.
"""
__variable_name() = "v"

"""
$(TYPEDSIGNATURES)

Used to set the default value of the names of the variables.
The default value is `["v"]` for a one dimensional variable, and `["v₁", "v₂", ...]` for a multi dimensional variable.
"""
__variable_components_names(q::Dimension,name::String) = q > 1 ? [ name * ctindices(i) for i ∈ range(1, q)] : [name]

"""
$(TYPEDSIGNATURES)

Used to set the default value of the name of the state.
The default value is `"x"`.
"""
__state_name() = "x"

"""
$(TYPEDSIGNATURES)

Used to set the default value of the names of the states.
The default value is `["x"]` for a one dimensional state, and `["x₁", "x₂", ...]` for a multi dimensional state.
"""
__state_components_names(n::Dimension,name::String) = n > 1 ? [ name * ctindices(i) for i ∈ range(1, n)] : [name]

"""
$(TYPEDSIGNATURES)

Used to set the default value of the names of the control.
The default value is `"u"`.
"""
__control_name() = "u"

"""
$(TYPEDSIGNATURES)

Used to set the default value of the names of the controls.
The default value is `["u"]` for a one dimensional control, and `["u₁", "u₂", ...]` for a multi dimensional control.
"""
__control_components_names(m::Dimension,name::String) = m > 1 ? [ name * ctindices(i) for i ∈ range(1, m)] : [name]

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

"""
$(TYPEDSIGNATURES)

Used to set the default initial guess.
The default value is `nothing`.
"""
__ocp_init() = nothing

# ------------------------------------------------------------------------------------
# Direct methods

"""
$(TYPEDSIGNATURES)

Used to set the default grid size.
The default value is `100`.
"""
__grid_size_direct() = 100

"""
$(TYPEDSIGNATURES)

Used to set the default time grid.
The default value is `nothing`.
"""
__time_grid_direct() = nothing

"""
$(TYPEDSIGNATURES)

Used to set the default tolerance.
The default value is `1e-8`.
"""
__tolerance_direct() = 1e-8

"""
$(TYPEDSIGNATURES)

Used to set the default maximum of iterations.
The default value is `1000`.
"""
__max_iterations_direct() = 1000

"""
$(TYPEDSIGNATURES)

Used to set the default linear solver.
The default value is `:ma57`.
"""
__linear_solver_direct() = :ma57

# ------------------------------------------------------------------------------------
# IPOPT

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
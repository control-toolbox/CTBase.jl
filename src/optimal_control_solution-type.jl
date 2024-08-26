# --------------------------------------------------------------------------------------------------
# Definition of an Optimal Control Solution
#
"""
$(TYPEDEF)

Abstract type for optimal control solutions.
"""
abstract type AbstractOptimalControlSolution end

"""
$(TYPEDEF)

Type of an optimal control solution.

# Fields

$(TYPEDFIELDS)
"""
@with_kw mutable struct OptimalControlSolution <: AbstractOptimalControlSolution

    # time_grid = [t0, t1, ...]
    time_grid::Union{Nothing, TimesDisc} = nothing

    # name of t, t0 and tf
    time_name::Union{Nothing, String} = nothing
    initial_time_name::Union{Nothing, String} = nothing
    final_time_name::Union{Nothing, String} = nothing

    # control: dimension, name of u = (u₁, u₂, ...) and u(t)
    control_dimension::Union{Nothing, Dimension} = nothing
    control_components_names::Union{Nothing, Vector{String}} = nothing
    control_name::Union{Nothing, String} = nothing
    control::Union{Nothing, Function} = nothing

    # state: dimension, name of x = (x₁, x₂, ...) and x(t)
    state_dimension::Union{Nothing, Dimension} = nothing
    state_components_names::Union{Nothing, Vector{String}} = nothing
    state_name::Union{Nothing, String} = nothing
    state::Union{Nothing, Function} = nothing

    # variable: dimension, name of v = (v₁, v₂, ...) and value of v
    variable_dimension::Union{Nothing, Dimension} = nothing
    variable_components_names::Union{Nothing, Vector{String}} = nothing
    variable_name::Union{Nothing, String} = nothing
    variable::Union{Nothing, Variable} = nothing

    # costate: p(t)
    costate::Union{Nothing, Function} = nothing

    # objective value
    objective::Union{Nothing, ctNumber} = nothing

    # solver infos
    iterations::Union{Nothing, Int} = nothing # number of iterations
    stopping::Union{Nothing, Symbol} = nothing # the stopping criterion
    message::Union{Nothing, String} = nothing # the message corresponding to the stopping criterion
    success::Union{Nothing, Bool} = nothing # whether or not the method has finished successfully: CN1, stagnation vs iterations max

    # dictionary to save additional infos
    infos::Dict{Symbol, Any} = Dict{Symbol, Any}()

    # constraints and multipliers
    boundary_constraints::Union{Nothing, ctVector} = nothing
    mult_boundary_constraints::Union{Nothing, ctVector} = nothing
    variable_constraints::Union{Nothing, ctVector} = nothing
    mult_variable_constraints::Union{Nothing, ctVector} = nothing
    mult_variable_box_lower::Union{Nothing, ctVector} = nothing
    mult_variable_box_upper::Union{Nothing, ctVector} = nothing

    control_constraints::Union{Nothing, Function} = nothing
    mult_control_constraints::Union{Nothing, Function} = nothing
    state_constraints::Union{Nothing, Function} = nothing
    mult_state_constraints::Union{Nothing, Function} = nothing
    mixed_constraints::Union{Nothing, Function} = nothing
    mult_mixed_constraints::Union{Nothing, Function} = nothing
    mult_state_box_lower::Union{Nothing, Function} = nothing
    mult_state_box_upper::Union{Nothing, Function} = nothing
    mult_control_box_lower::Union{Nothing, Function} = nothing
    mult_control_box_upper::Union{Nothing, Function} = nothing
end

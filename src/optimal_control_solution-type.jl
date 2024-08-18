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
    time_grid::Union{Nothing, TimesDisc}=nothing
    initial_time_name::Union{String, Nothing}=nothing
    final_time_name::Union{String, Nothing}=nothing
    time_name::Union{String, Nothing}=nothing
    control_dimension::Union{Nothing, Dimension}=nothing
    control_components_names::Union{Vector{String}, Nothing}=nothing
    control_name::Union{String, Nothing}=nothing
    control::Union{Nothing, Function}=nothing
    state_dimension::Union{Nothing, Dimension}=nothing
    state_components_names::Union{Vector{String}, Nothing}=nothing
    state_name::Union{String, Nothing}=nothing
    state::Union{Nothing, Function}=nothing
    variable_dimension::Union{Dimension,Nothing}=nothing
    variable_components_names::Union{Vector{String}, Nothing}=nothing
    variable_name::Union{String, Nothing}=nothing
    variable::Union{Nothing, Variable}=nothing
    costate::Union{Nothing, Function}=nothing
    objective::Union{Nothing, ctNumber}=nothing
    iterations::Union{Nothing, Integer}=nothing
    stopping::Union{Nothing, Symbol}=nothing # the stopping criterion
    message::Union{Nothing, String}=nothing # the message corresponding to the stopping criterion
    success::Union{Nothing, Bool}=nothing # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}()
end

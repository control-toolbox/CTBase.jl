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
    state_dimension::Union{Nothing, Dimension}=nothing
    control_dimension::Union{Nothing, Dimension}=nothing
    times::Union{Nothing, TimesDisc}=nothing
    time_name::Union{String, Nothing}=nothing
    state::Union{Nothing, Function}=nothing
    state_names::Union{Vector{String}, Nothing}=nothing
    adjoint::Union{Nothing, Function}=nothing
    control::Union{Nothing, Function}=nothing
    control_names::Union{Vector{String}, Nothing}=nothing
    objective::Union{Nothing, ctNumber}=nothing
    iterations::Union{Nothing, Integer}=nothing
    stopping::Union{Nothing, Symbol}=nothing # the stopping criterion
    message::Union{Nothing, String}=nothing # the message corresponding to the stopping criterion
    success::Union{Nothing, Bool}=nothing # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}()
end

# we get an error when a solution is printed so I add this function
# which has to be put in the package CTBase and has to be completed
"""
$(TYPEDSIGNATURES)

Prints the solution.
"""
function Base.show(io::IO, ::MIME"text/plain", sol::OptimalControlSolution)
    nothing
end
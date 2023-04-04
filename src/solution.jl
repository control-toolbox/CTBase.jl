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
    time_name::String=""
    state::Union{Nothing, Function}=nothing
    state_names::Vector{String}=Vector{String}()
    adjoint::Union{Nothing, Function}=nothing
    control::Union{Nothing, Function}=nothing
    control_names::Vector{String}=Vector{String}()
    objective::Union{Nothing, MyNumber}=nothing
    iterations::Union{Nothing, Integer}=nothing
    stopping::Union{Nothing, Symbol}=nothing # the stopping criterion
    message::Union{Nothing, String}=nothing # the message corresponding to the stopping criterion
    success::Union{Nothing, Bool}=nothing # whether or not the method has finished successfully: CN1, stagnation vs iterations max
    infos::Dict{Symbol, Any}=Dict{Symbol, Any}()
end

#= # getters
state_dimension(sol::OptimalControlSolution) = sol.state_dimension
control_dimension(sol::OptimalControlSolution) = sol.control_dimension
time_steps(sol::OptimalControlSolution) = sol.times
time_steps_length(sol::OptimalControlSolution) = length(time(sol))
state(sol::OptimalControlSolution) = sol.state
state_names(sol::OptimalControlSolution) = sol.state_names
control(sol::OptimalControlSolution) = sol.control
control_names(sol::OptimalControlSolution) = sol.control_names
adjoint(sol::OptimalControlSolution) = sol.adjoint
objective(sol::OptimalControlSolution) = sol.objective
iterations(sol::OptimalControlSolution) = sol.iterations   
success(sol::OptimalControlSolution) = sol.success
message(sol::OptimalControlSolution) = sol.message
stopping(sol::OptimalControlSolution) = sol.stopping =#

# we get an error when a solution is printed so I add this function
# which has to be put in the package CTBase and has to be completed
"""
$(TYPEDSIGNATURES)

Prints the solution.
"""
function Base.show(io::IO, ::MIME"text/plain", sol::OptimalControlSolution)
    nothing
end